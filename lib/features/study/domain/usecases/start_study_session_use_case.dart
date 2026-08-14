import '../../../../core/error/failure.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../models/study_session_start_model.dart';
import '../failures/study_refusal_failure.dart';
import '../models/study_direction_model.dart';
import '../models/study_mode.dart';
import '../models/study_scheduler.dart';
import '../models/study_day_model.dart';
import '../models/study_session_kind_model.dart';
import '../models/study_session_status_model.dart';
import '../repositories/study_repository.dart';

/// Opens a session of a chosen kind (UC-05).
///
/// **One use case for both kinds, because opening a session is one interaction.**
/// What differs is which set of cards it takes and which stages it runs, and both
/// of those are answers the algorithm and BR-142 already give — not two different
/// things a user does. Two use cases here would duplicate the option lookup, the
/// generation read and the refusal handling, and the copies would drift.
///
/// The stage list comes from the deck's algorithm (BR-97). A review session is
/// given exactly one mode by the user (BR-109), and that mode must be one the
/// algorithm offers (BR-146) — a review in `browse` would record nothing and
/// could never end.
class StartStudySessionUseCase {
  const StartStudySessionUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudySessionStartModel> call({
    required String deckId,
    required StudySessionKind kind,
    required DateTime now,
    required Duration utcOffset,

    /// Required for a review session, ignored for a learning one.
    StudyMode? reviewMode,

    /// The recall direction the user chose (BR-182).
    ///
    /// Required when — and legal **only** when — the session is eligible. See
    /// [_directionFor].
    StudySessionDirection? direction,
  }) async {
    final context = await _repository.deckContext(deckId);
    final scheduler = schedulerFor(context.schedulerType);

    // A deck written by a newer build is readable but not studiable: nothing
    // here knows its rules, and guessing them would write a schedule under an
    // algorithm that does not exist in this version.
    if (scheduler == null) {
      throw const ConflictFailure(
        message: 'This deck uses an algorithm this version does not know',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    final stageSequence = _stagesFor(
      scheduler: scheduler,
      kind: kind,
      reviewMode: reviewMode,
    );

    // Before any write, and before the stale sweep below: a refused session must
    // leave nothing behind (BR-101), and the sweep already closes rows.
    final sessionDirection = _directionFor(
      schedulerType: context.schedulerType,
      kind: kind,
      stageSequence: stageSequence,
      direction: direction,
    );

    // Read once, here, and frozen onto the session (BR-139). Changing the
    // setting afterwards must not move a session that is already running.
    final options = await _repository.effectiveOptions(context.rootDeckId);

    // BR-103: choosing to start something new ends whatever was still open,
    // and ends it as `user_exit` — the user chose.
    //
    // **The stale sweep runs first, and that ordering is the rule.** A session
    // from an earlier day is `interrupted`, never `user_exit` — the user did not
    // leave, the app did. Without this line the two labels come down to which
    // screen happened to run first, and history written with the wrong label
    // cannot be recomputed later (BR-76).
    await _repository.abandonStaleSessions(
      dayStart: StudyDayModel(now: now, utcOffset: utcOffset).startOfToday,
    );

    final open = await _repository.openSessionFor(deckId);
    if (open != null) {
      await _repository.endSession(
        sessionId: open.id,
        status: StudySessionStatus.abandoned,
        reason: StudySessionEndReason.userExit,
        endedAt: now,
      );
    }

    final session = await _repository.openSession(
      deckId: deckId,
      kind: kind,
      stageSequence: stageSequence,
      cardLimit: options.cardLimit,
      newCardOrder: options.newCardOrder,
      now: now,
      direction: sessionDirection,
    );

    // The card set comes back with the session rather than in a second call:
    // three reads are three snapshots, and a Reset landing between them leaves
    // the screen holding halves of two different worlds (AD-13).
    return StudySessionStartModel(
      session: session,
      deckName: context.deckName,
      schedulerType: context.schedulerType,
      actions: scheduler.supportedActions,
      cards: await _repository.sessionCards(session.id),
    );
  }

  List<StudyMode> _stagesFor({
    required StudyScheduler scheduler,
    required StudySessionKind kind,
    required StudyMode? reviewMode,
  }) {
    if (kind == StudySessionKind.learning) return scheduler.stageSequence;

    if (reviewMode == null) {
      throw const ValidationFailure(
        message: 'A review session needs a mode',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    // BR-146. Refused rather than silently substituted: a user who picked
    // `fill` and got `match` would have no way to tell it happened.
    if (!scheduler.reviewModes.contains(reviewMode)) {
      throw const ConflictFailure(
        message: 'This algorithm does not offer that mode',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    return <StudyMode>[reviewMode];
  }

  /// The direction this session may carry, refusing everything else (BR-187).
  ///
  /// **Two refusals, and the second one is the load-bearing half.** Missing a
  /// direction on an eligible session is an incomplete request. Supplying one on
  /// an *ineligible* session is the case that would quietly give `eight_box` — or
  /// a learning chain, or `fill` — a feature no rule grants it, and it would
  /// never surface: the column takes the value, the queue stamps it, and only a
  /// reader months later would find a `match` turn claiming to have been asked
  /// from the meaning.
  ///
  /// It is asked here rather than in the repository because eligibility needs the
  /// root deck's algorithm and the chosen stage together, and both are already in
  /// hand — while the repository is handed a stage sequence and deliberately
  /// knows nothing about which algorithm produced it.
  StudySessionDirection? _directionFor({
    required SchedulerType schedulerType,
    required StudySessionKind kind,
    required List<StudyMode> stageSequence,
    required StudySessionDirection? direction,
  }) {
    final isEligible =
        stageSequence.length == 1 &&
        isReverseDirectionEligible(
          kind: kind,
          schedulerType: schedulerType,
          mode: stageSequence.single,
        );

    if (!isEligible) {
      if (direction == null) return null;

      throw const ConflictFailure(
        message: 'This session cannot choose a recall direction',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    if (direction == null) {
      throw const ValidationFailure(
        message: 'A self-assess review needs a recall direction',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    return direction;
  }
}
