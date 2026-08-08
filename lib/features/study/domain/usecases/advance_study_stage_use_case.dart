import '../../../../core/error/failure.dart';
import '../entities/study_session_entity.dart';
import '../models/study_day_model.dart';
import '../models/study_mode.dart';
import '../models/study_scheduler.dart';
import '../models/study_session_kind_model.dart';
import '../models/study_session_status_model.dart';
import '../repositories/study_repository.dart';

/// What happens when a stage runs out of cards (UC-05).
///
/// Three outcomes, and keeping them apart is the whole job:
///
/// * the stage has more to serve — nothing to do;
/// * another stage follows — move to it;
/// * nothing follows — finish the cards and close the session.
class AdvanceStudyStageUseCase {
  const AdvanceStudyStageUseCase(this._repository);

  final StudyRepository _repository;

  /// Returns the stage now running, or null when the session has ended.
  Future<StudyMode?> call({
    required StudySessionEntity session,
    required DateTime now,
    required Duration utcOffset,
  }) async {
    // Not the same question as "is there a card to serve right now". A
    // `self_assess` queue with everything waiting out BR-26's three-card gap
    // serves nothing and is not finished; conflating the two ends the session
    // three cards early.
    if (!await _repository.isStageExhausted(session.id)) {
      return session.currentMode;
    }

    // **Keeps going while each stage it lands on is also exhausted** (BR-99).
    // A stage that cannot run on this session-s card set is written with no rows
    // at all, so it is exhausted from the moment the session opens — `guess`
    // under five distinct meanings, `match` under two pairs. Advancing once and
    // returning that stage hands the caller a stage with no turn in it, and a
    // null turn is indistinguishable from the end of the session: the session
    // stops with cards still unanswered.
    //
    // Bounded by the algorithm-s stage sequence, which is a fixed list of five.
    var current = session;
    while (true) {
      final next = await _nextStage(current);
      if (next == null) break;

      await _repository.advanceStage(
        sessionId: current.id,
        mode: next,
        now: now,
      );
      current = current.copyWith(currentMode: next);

      if (!await _repository.isStageExhausted(current.id)) return next;
    }

    await _finish(session: current, now: now, utcOffset: utcOffset);

    return null;
  }

  /// The stage after the current one, or null at the end of the sequence.
  ///
  /// A review session has exactly one stage (BR-109), so it always ends here.
  Future<StudyMode?> _nextStage(StudySessionEntity session) async {
    if (session.kind == StudySessionKind.reviewing) return null;

    final context = await _repository.deckContext(session.deckId);
    final scheduler = schedulerFor(context.schedulerType);
    if (scheduler == null) {
      throw const ConflictFailure(
        message: 'This deck uses an algorithm this version does not know',
      );
    }

    final sequence = scheduler.stageSequence;
    final index = sequence.indexOf(session.currentMode);

    // An unrecognised current stage would otherwise resolve to index 0 and
    // restart the whole chain, quietly making the session twice as long.
    if (index < 0) {
      throw ConflictFailure(
        message: 'Session is on a stage its algorithm does not run',
        cause: session.currentMode,
      );
    }

    return index + 1 < sequence.length ? sequence[index + 1] : null;
  }

  /// Ends the session, and — for a learning one — marks its cards learned.
  ///
  /// **Completion is an event, not an answer** (BR-144). It sets `learned_at`
  /// and seeds the schedule at the algorithm's lowest rung, due at the start of
  /// the next study day, and writes no `scheduled` turn at all.
  ///
  /// The cards that qualify are those with nothing pending left **anywhere in
  /// the session** — which is "every stage it took part in", not "every stage in
  /// the sequence" (BR-114). A card the `fill` stage skipped for want of an
  /// `example` has no row there to be pending, so it finishes with the rest.
  /// Reading the rule the other way is what would have frozen most of a deck
  /// permanently, because `example` is optional.
  Future<void> _finish({
    required StudySessionEntity session,
    required DateTime now,
    required Duration utcOffset,
  }) async {
    if (session.kind == StudySessionKind.learning) {
      final context = await _repository.deckContext(session.deckId);
      final scheduler = schedulerFor(context.schedulerType);
      if (scheduler == null) {
        throw const ConflictFailure(
          message: 'This deck uses an algorithm this version does not know',
        );
      }

      final initial = scheduler.initial();
      final dueAt = StudyDayModel(
        now: now,
        utcOffset: utcOffset,
      ).startOfDayAfter(initial.intervalDays);

      for (final cardId in await _repository.cardsFinishedInSession(
        session.id,
      )) {
        await _repository.completeLearning(
          cardId: cardId,
          learnedAt: now,
          dueAt: dueAt,
          box: initial.schedule.box,
          intervalDays: initial.schedule.intervalDays,
        );
      }
    }

    await _repository.endSession(
      sessionId: session.id,
      status: StudySessionStatus.completed,
      // Null, always: a session that ran out of queue did not fail at anything
      // (BR-81), and the matrix admits no reason here.
      reason: null,
      endedAt: now,
    );
  }
}
