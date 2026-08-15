import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../domain/models/study_answer_commit_model.dart';
import '../../domain/models/study_queue_item_status_model.dart';
import '../../domain/models/study_lapse_policy_model.dart';
import '../../domain/models/study_turn_model.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/failures/study_refusal_failure.dart';
import '../../domain/models/new_card_order_model.dart';
import '../../domain/models/study_action_model.dart';
import '../../domain/models/study_card_limit_model.dart';
import '../../domain/models/study_answer_kind_model.dart';
import '../../domain/models/study_deck_context_model.dart';
import '../../domain/models/study_direction_model.dart';
import '../../domain/models/study_entry_summary_model.dart';
import '../../domain/models/study_schedule_model.dart';
import '../../domain/models/study_scheduler.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_options_model.dart';
import '../../domain/models/study_outcome_reason_model.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../../domain/models/study_session_summary_model.dart';
import '../../domain/models/study_session_status_model.dart';
import '../../domain/repositories/study_repository.dart';
import '../datasources/study_dao.dart';
import '../mappers/study_config_mapper.dart';
import '../mappers/study_mapper.dart';

part 'study_options_repository_impl.dart';
part 'study_queue_layout_repository_impl.dart';
part 'study_queue_repository_impl.dart';
part 'study_lifecycle_repository_impl.dart';

/// How many other cards a forgotten one waits behind (BR-26).
const int kSelfAssessComebackGap = 3;

/// How many `relearning` turns a card may take in `self_assess` before it is
/// pushed out of the queue and flagged (BR-104).
const int kSelfAssessRelearningCeiling = 3;

/// The lowest rung a card starts on once it finishes the learning chain
/// (BR-144). `eight_box` box 1; `sm2` one day.
const int kInitialBox = 1;
const int kInitialIntervalDays = 1;

/// Drift-backed [StudyRepository].
///
/// **This class is where the queue rules live**, and that is deliberate. BR-23's
/// ordering, BR-26's comeback, BR-115's rounds and BR-116's failed set all need
/// the data *as it stands at the moment of writing*; checking any of them above
/// the repository would put the check outside the transaction, which is a race
/// between the check and the write.
///
/// It is also the boundary where a Drift exception becomes a domain `Failure`.
/// Nothing above it sees a `DriftWrappedException`.
final class StudyRepositoryImpl
    with
        _StudyOptionsOperations,
        _StudyQueueLayoutOperations,
        _StudyQueueOperations,
        _StudyLifecycleOperations
    implements StudyRepository {
  StudyRepositoryImpl(
    this._dao, {
    String Function()? idGenerator,

    /// Injected so a test can pin the shuffle. `RANDOM()` in SQL cannot be
    /// seeded, which is why the ordering of a round is decided here and not in
    /// the query.
    Random? random,
  }) : _idGenerator = idGenerator ?? const Uuid().v4,
       _random = random ?? Random();

  @override
  final StudyDao _dao;
  @override
  final String Function() _idGenerator;
  @override
  final Random _random;

  @override
  Stream<StudyEntrySummaryModel> watchStudyEntry(
    String deckId, {
    required DateTime now,
  }) => _dao.watchEntryCounts(deckId, now).map(studyEntrySummaryFromRow);

  @override
  Future<StudyDeckContextModel> deckContext(String deckId) async {
    final deck = await _dao.deckById(deckId);
    if (deck == null) {
      throw const NotFoundFailure(message: 'Deck not found');
    }

    // The algorithm lives on the root, and a branch resolves through
    // `root_deck_id` rather than by walking parents (BR-06, BR-57).
    final root = deck.rootDeckId == deck.id
        ? deck
        : await _dao.deckById(deck.rootDeckId) ?? deck;

    return StudyDeckContextModel(
      deckId: deck.id,
      deckName: deck.name,
      rootDeckId: deck.rootDeckId,
      schedulerType: SchedulerType.fromDbValue(root.schedulerType ?? ''),
      schedulerGeneration: root.schedulerGeneration ?? 1,
    );
  }

  @override
  Future<StudyScheduleModel?> scheduleOf(String cardId) async {
    final state = await _dao.studyStateOf(cardId);

    return state == null ? null : studyScheduleFromRow(state);
  }

  @override
  Future<StudySessionSummaryModel> sessionSummary({
    required String sessionId,
    required List<StudyAction> wrongActions,
  }) async => studySessionSummaryFromRow(
    await _dao.sessionSummaryRow(
      sessionId: sessionId,
      wrongActions: wrongActions
          .map((action) => action.dbValue)
          .toList(growable: false),
    ),
  );

  @override
  Future<List<StudyCardModel>> sessionCards(String sessionId) async {
    final ids = await _dao.sessionCardIds(sessionId);
    final cards = <StudyCardModel>[];

    for (final id in ids) {
      final row = await _dao.cardById(id);
      if (row == null) continue;

      cards.add(studyCardModelFromRow(row));
    }

    return cards;
  }

  @override
  Future<List<String>> cardsFinishedInSession(String sessionId) =>
      _dao.cardsWithNothingPending(sessionId);

  @override
  Future<StudySessionEntity> openSession({
    required String deckId,
    required StudySessionKind kind,
    required List<StudyMode> stageSequence,
    required int cardLimit,
    required NewCardOrder newCardOrder,
    required DateTime now,
    StudySessionDirection? direction,
  }) async {
    if (stageSequence.isEmpty) {
      throw const ConflictFailure(
        message: 'A session needs at least one stage',
      );
    }

    // **The shape a direction is allowed to arrive in, checked here and not only
    // in the use case.** The use case owns eligibility because it has the root
    // deck's algorithm (BR-208); what this layer can still see is the other two
    // thirds of BR-203 — the kind and the single stage — and without this check
    // the *session* row took a direction even when only the queue rows were
    // gated. Invariant 31 calls that row invalid, so the guard belongs where the
    // row is written.
    //
    // `unknown` is refused for a different reason: a value this build cannot
    // name would read back as a decision somebody made. Refused here rather than
    // left to `dbValue`'s `StateError`, so the caller gets a domain failure.
    final isDirectionAllowed =
        kind == StudySessionKind.reviewing &&
        stageSequence.length == 1 &&
        stageSequence.single == StudyMode.selfAssess;
    if (direction != null &&
        (direction == StudySessionDirection.unknown || !isDirectionAllowed)) {
      throw const ConflictFailure(
        message: 'This session cannot carry a recall direction',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    return _dao.runInTransaction(() async {
      final deck = await _dao.deckById(deckId);
      if (deck == null) {
        throw const NotFoundFailure(message: 'Deck not found');
      }

      final cards = await _cardsFor(
        rootDeckId: deck.rootDeckId,
        kind: kind,
        cardLimit: cardLimit,
        newCardOrder: newCardOrder,
        now: now,
      );

      // BR-145 and BR-101 together: nothing due means no session at all, not an
      // empty one. A session row written and then abandoned would still count as
      // a session in the history, and studying ahead is a rule rather than a
      // missing feature.
      if (cards.isEmpty) {
        throw ConflictFailure(
          message: 'Nothing to study',
          reason: kind == StudySessionKind.reviewing
              ? StudyRefusalReason.nothingDueToReview
              : StudyRefusalReason.nothingLeftToLearn,
        );
      }

      final sessionId = _idGenerator();
      await _dao.insertSession(
        StudySessionsCompanion.insert(
          id: sessionId,
          deckId: deckId,
          rootDeckId: deck.rootDeckId,
          schedulerGeneration: deck.schedulerGeneration ?? 1,
          sessionKind: kind.dbValue,
          currentMode: stageSequence.first.dbValue,
          status: StudySessionStatus.inProgress.dbValue,
          cardLimit: cardLimit,
          startedAt: now,
          direction: Value<String?>(direction?.dbValue),
        ),
      );

      // Every stage over the same card set, each with its own shuffle (BR-113).
      // Sharing one order across stages would make the second stage a re-run of
      // the first, which is the opposite of what five stages are for.
      for (final mode in stageSequence) {
        await _dao.insertQueueItems(
          _roundOne(
            sessionId: sessionId,
            mode: mode,
            cards: cards,
            direction: direction,
          ),
        );
      }

      final session = await _dao.sessionById(sessionId);
      return studySessionEntityFromRow(session!);
    });
  }

  @override
  Future<void> advanceStage({
    required String sessionId,
    required StudyMode mode,
    required DateTime now,
  }) => _dao.updateSession(
    sessionId,
    StudySessionsCompanion(currentMode: Value<String>(mode.dbValue)),
  );

  @override
  Future<bool> buildNextRound(String sessionId) async {
    final session = await _dao.sessionById(sessionId);
    if (session == null) return false;

    // Nothing to build: failures enrolled themselves as they happened, so a
    // pending row at a higher round already exists if there is a next round at
    // all. An empty result is BR-119's end condition, and there is deliberately
    // no ceiling on the number of rounds — BR-104's three belongs to
    // `self_assess`.
    final round = await _dao.currentRound(
      sessionId: sessionId,
      mode: session.currentMode,
    );

    return round != null;
  }

  @override
  Future<void> saveTurnProgress({
    required String sessionId,
    required StudyMode mode,
    required String cardId,
    int? remainingMs,
    bool isRevealed = false,
  }) async {
    final round = await _dao.currentRound(
      sessionId: sessionId,
      mode: mode.dbValue,
    );

    if (round == null) return;

    // **The stage having a pending round is not the same as *this card* still
    // being in it.** The lowest pending round is decided by whichever cards are
    // left, so a card answered a moment ago still resolves to a round — and
    // writing progress against its completed row would make Resume serve a card
    // the user has already answered. Only a row that is still pending may take
    // progress.
    final item = await _dao.queueItem(
      sessionId: sessionId,
      mode: mode.dbValue,
      round: round,
      cardId: cardId,
    );
    if (item == null || item.status != 'pending') return;

    await _dao.updateQueueItem(
      sessionId: sessionId,
      mode: mode.dbValue,
      round: round,
      cardId: cardId,
      values: StudyQueueItemsCompanion(
        remainingMs: Value<int?>(remainingMs),
        isRevealed: Value<int>(isRevealed ? 1 : 0),
      ),
    );
  }

  @override
  Future<int> invalidateSessionsForRoot({
    required String rootDeckId,
    required DateTime endedAt,
    required StudySessionEndReason reason,
  }) => _dao.runInTransaction(() async {
    final open = await _dao.openSessionsForRoot(rootDeckId);

    for (final session in open) {
      await _dao.updateSession(
        session.id,
        StudySessionsCompanion(
          status: Value<String>(StudySessionStatus.invalidated.dbValue),
          // Never `stale_generation`: the difference is who noticed. This is
          // the deck operation closing its own sessions; the other is a session
          // discovering afterwards that it had been outrun (BR-83, BR-84). Which
          // deck operation it was comes from the caller — see the contract.
          endReason: Value<String?>(reason.dbValue),
          endedAt: Value<DateTime?>(endedAt),
        ),
      );
    }

    return open.length;
  });

  /// Refuses a write the session cannot accept (BR-79, BR-84).
  ///
  /// **This commits, and is called before the write transaction opens.** A
  /// session whose generation no longer matches the root has to end
  /// `invalidated` *and* not write its turn; doing both inside one transaction
  /// means the invalidation rolls back with the refusal, leaving the session
  /// open and still offering to record turns that can never be accepted.
  ///
  /// The transaction re-reads the session afterwards, so a Reset landing between
  /// the two only costs a rollback — the next attempt invalidates.
  @override
  Future<StudySession> _invalidateIfStale(String sessionId) async {
    final session = await _dao.sessionById(sessionId);
    if (session == null) {
      throw const NotFoundFailure(message: 'Session not found');
    }
    if (session.status != StudySessionStatus.inProgress.dbValue) {
      throw const ConflictFailure(
        message: 'Session is not open',
        reason: StudyRefusalReason.sessionNotOpen,
      );
    }

    final root = await _dao.deckById(session.rootDeckId);
    final current = root?.schedulerGeneration ?? session.schedulerGeneration;
    if (current == session.schedulerGeneration) return session;

    await _dao.updateSession(
      sessionId,
      StudySessionsCompanion(
        status: Value<String>(StudySessionStatus.invalidated.dbValue),
        endReason: Value<String?>(
          StudySessionEndReason.staleGeneration.dbValue,
        ),
      ),
    );

    throw const ConflictFailure(
      message: 'Session belongs to an older generation',
      reason: StudyRefusalReason.staleGeneration,
    );
  }
}
