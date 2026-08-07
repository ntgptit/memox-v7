import '../../../../core/error/failure.dart';
import '../entities/study_session_entity.dart';
import '../models/study_action_model.dart';
import '../models/study_day_model.dart';
import '../models/study_mode.dart';
import '../models/study_outcome_reason_model.dart';
import '../models/study_scheduler.dart';
import '../models/study_session_kind_model.dart';
import '../repositories/study_repository.dart';

/// Records one answer (UC-05).
///
/// **This is the template method AD-18 talks about.** It runs the fixed sequence
/// — work out what the turn means, ask the algorithm what the new schedule is,
/// then hand the whole thing to the repository to write in one transaction —
/// and a mode's own logic plugs in rather than wrapping it. The seven writes
/// that follow all have to be atomic (BR-86), which is why they stay behind the
/// repository and this stops at deciding *what* to write.
///
/// **A learning session consults no scheduler at all.** Every turn in the chain
/// is `learning` or `relearning` and moves nothing (BR-141, BR-144), so asking
/// for an interval would produce a number that must then be thrown away — and a
/// number computed and discarded is a number somebody eventually stores.
class SubmitStudyAnswerUseCase {
  const SubmitStudyAnswerUseCase(this._repository);

  final StudyRepository _repository;

  Future<void> call({
    required StudySessionEntity session,
    required String cardId,
    required StudyMode mode,
    required StudyAction action,
    required DateTime now,
    required Duration utcOffset,
    StudyOutcomeReason? outcomeReason,
    int? comparisonVersion,
    bool? usedHint,
  }) async {
    if (session.kind == StudySessionKind.learning) {
      return _repository.submitAnswer(
        sessionId: session.id,
        cardId: cardId,
        mode: mode,
        action: action,
        now: now,
        outcomeReason: outcomeReason,
        comparisonVersion: comparisonVersion,
        usedHint: usedHint,
      );
    }

    final context = await _repository.deckContext(session.deckId);
    final scheduler = schedulerFor(context.schedulerType);
    if (scheduler == null) {
      throw const ConflictFailure(
        message: 'This deck uses an algorithm this version does not know',
      );
    }

    final schedule = await _repository.scheduleOf(cardId);
    if (schedule == null) {
      throw const NotFoundFailure(message: 'Card has no study state');
    }

    final update = scheduler.next(schedule: schedule, action: action);

    // AD-16: the algorithm returns days, and the day boundary turns them into a
    // moment. Doing that here rather than inside the repository is what keeps
    // `next_due_at` in the history identical to what the scheduler just said —
    // rounding at the point of writing would make the two disagree, and history
    // would stop being reproducible.
    final dueAt = StudyDayModel(
      now: now,
      utcOffset: utcOffset,
    ).startOfDayAfter(update.intervalDays);

    // Passed on every turn, including the `relearning` ones. The repository is
    // what decides they change nothing (BR-78) — it knows whether this is the
    // card's first turn in the session, and this does not.
    await _repository.submitAnswer(
      sessionId: session.id,
      cardId: cardId,
      mode: mode,
      action: action,
      now: now,
      outcomeReason: outcomeReason,
      comparisonVersion: comparisonVersion,
      usedHint: usedHint,
      nextDueAt: dueAt,
      nextBox: update.schedule.box,
      nextEaseFactor: update.schedule.easeFactor,
      nextIntervalDays: update.schedule.intervalDays,
    );
  }
}
