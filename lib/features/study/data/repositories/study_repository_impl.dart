import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../domain/models/study_turn_model.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/failures/study_refusal_failure.dart';
import '../../domain/models/new_card_order_model.dart';
import '../../domain/models/study_action_model.dart';
import '../../domain/models/study_answer_kind_model.dart';
import '../../domain/models/study_deck_context_model.dart';
import '../../domain/models/study_entry_summary_model.dart';
import '../../domain/models/study_schedule_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_options_model.dart';
import '../../domain/models/study_outcome_reason_model.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../../domain/models/study_session_status_model.dart';
import '../../domain/repositories/study_repository.dart';
import '../datasources/study_dao.dart';
import '../mappers/study_mapper.dart';

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
    with _StudyQueueOperations, _StudyLifecycleOperations
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
  }) => _dao
      .watchEntryCounts(deckId, now)
      .map(
        (row) => StudyEntrySummaryModel(
          newCount: row.newCount ?? 0,
          dueCount: row.dueCount ?? 0,
          fillableCount: row.fillableCount ?? 0,
          distinctMeanings: row.distinctMeanings,
        ),
      );

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
      rootDeckId: deck.rootDeckId,
      schedulerType: SchedulerType.fromDbValue(root.schedulerType ?? ''),
      schedulerGeneration: root.schedulerGeneration ?? 1,
    );
  }

  @override
  Future<StudyScheduleModel?> scheduleOf(String cardId) async {
    final state = await _dao.studyStateOf(cardId);
    if (state == null) return null;

    return StudyScheduleModel(
      box: state.currentBox,
      easeFactor: state.easeFactor,
      intervalDays: state.intervalDays,
      repetitions: state.repetitions,
    );
  }

  @override
  Future<List<String>> cardsFinishedInSession(String sessionId) =>
      _dao.cardsWithNothingPending(sessionId);

  @override
  Future<StudyOptionsModel> effectiveOptions(String rootDeckId) async {
    final settings = await _dao.appSettings();

    // The deck-level override of BR-147 is read but not yet parsed: no screen
    // writes `study_config` until M5.4a, and a parser with no writer is a
    // parser nobody has tested against real input.
    return StudyOptionsModel(
      cardLimit: settings.cardLimit,
      newCardOrder: NewCardOrder.fromDbValue(settings.newCardOrder),
    );
  }

  @override
  Future<StudySessionEntity> openSession({
    required String deckId,
    required StudySessionKind kind,
    required List<StudyMode> stageSequence,
    required int cardLimit,
    required NewCardOrder newCardOrder,
    required DateTime now,
  }) async {
    if (stageSequence.isEmpty) {
      throw const ConflictFailure(
        message: 'A session needs at least one stage',
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
        ),
      );

      // Every stage over the same card set, each with its own shuffle (BR-113).
      // Sharing one order across stages would make the second stage a re-run of
      // the first, which is the opposite of what five stages are for.
      for (final mode in stageSequence) {
        await _dao.insertQueueItems(
          _roundOne(sessionId: sessionId, mode: mode, cards: cards),
        );
      }

      final session = await _dao.sessionById(sessionId);
      return studySessionEntityFromRow(session!);
    });
  }

  @override
  Future<void> completeLearning({
    required String cardId,
    required DateTime learnedAt,
    required DateTime dueAt,
    int? box,
    int? intervalDays,
  }) => _dao.runInTransaction(() async {
    final state = await _dao.studyStateOf(cardId);
    if (state == null) {
      throw const NotFoundFailure(message: 'Card has no study state');
    }

    // Both columns in one statement. A card holding `learned_at` without a
    // schedule, or a schedule without `learned_at`, is exactly what invariants
    // 24 and 28 exist to catch — and writing them separately is the only way to
    // produce one.
    final isEightBox =
        SchedulerType.fromDbValue(state.schedulerType) ==
        SchedulerType.eightBox;

    await _dao.updateStudyState(
      cardId,
      CardStudyStatesCompanion(
        learnedAt: Value<DateTime?>(learnedAt),
        dueAt: Value<DateTime?>(dueAt),
        currentBox: Value<int?>(isEightBox ? (box ?? kInitialBox) : null),
        intervalDays: Value<int?>(
          isEightBox ? null : (intervalDays ?? kInitialIntervalDays),
        ),
      ),
    );
  });

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
  }) => _dao.runInTransaction(() async {
    final open = await _dao.openSessionsForRoot(rootDeckId);

    for (final session in open) {
      await _dao.updateSession(
        session.id,
        StudySessionsCompanion(
          status: Value<String>(StudySessionStatus.invalidated.dbValue),
          // `scheduler_reset`, not `stale_generation`: the difference is who
          // noticed. This is the reset closing its own sessions; the other is a
          // session discovering afterwards that it had been outrun (BR-83,
          // BR-84).
          endReason: Value<String?>(
            StudySessionEndReason.schedulerReset.dbValue,
          ),
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
