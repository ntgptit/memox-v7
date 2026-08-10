import 'study_lapse_policy_model.dart';
import 'study_outcome_reason_model.dart';
import 'study_entry_summary_model.dart';
import 'study_mode.dart';

/// How long one `recall` turn lasts (BR-128).
const Duration kRecallTurnLimit = Duration(seconds: 20);

/// How a `recall` turn ended — the **graded** result, and nothing else.
///
/// **Revealing the back used to be one of these, and that was the bug.** A
/// learner who presses *Show answer* has told the app one thing: they want to
/// see the back. They have not said they remembered it, and the old
/// `RecallOutcome.revealed` mapped straight onto the scheduler's *correct*
/// action — so every card a learner gave up on early was promoted a box. The
/// evidence 8-box needs is binary and it only exists once the learner says
/// which it was, which is why reveal is now a **phase** (`RecallPhase`) and
/// these three are the only things that can be written down.
///
/// **Exactly one of these is recorded per turn** (BR-129). The interesting case
/// is the instant the clock reaches zero with a tap already in flight: an
/// implementation that lets both through writes two turns for one question, and
/// one that lets neither through hangs the session.
enum RecallOutcome {
  /// The learner saw the back and said they knew it.
  remembered,

  /// The learner saw the back and said they did not.
  forgotten,

  /// The clock reached zero. Counts as wrong, and cannot be argued with
  /// afterwards (BR-130).
  timedOut;

  /// What 8-box is told (BR-107, BR-120). Binary, because `eight_box` has
  /// exactly two graded actions and `recall` produces no third thing.
  bool get isCorrect => this == RecallOutcome.remembered;

  /// Why the turn ended this way, when the action alone cannot say (BR-131).
  ///
  /// `forgotten` and `timedOut` both write the same action; owning up to a
  /// blank and running out of time are not the same event, and the difference
  /// only survives if it is stored here rather than inferred later.
  StudyOutcomeReason? get reason =>
      this == RecallOutcome.timedOut ? StudyOutcomeReason.timeout : null;
}

/// Remember it before the clock runs out.
final class RecallModeHandler extends StudyModeHandler {
  const RecallModeHandler();

  @override
  StudyLapsePolicy get lapsePolicy =>
      StudyLapsePolicy.completeAndEnrollNextRound;

  @override
  int capacityFrom(StudyEntrySummaryModel summary) => summary.dueCount;

  /// Whether the clock has run out (BR-129).
  ///
  /// [elapsed] is measured in *interactive* time — the widget stops the clock
  /// when the app goes to the background, so a phone call does not fail a card
  /// (BR-128).
  ///
  /// **The boundary is inclusive on the timeout side.** BR-129 says an action
  /// *before* the mark is a manual reveal and one *at or after* it is a timeout,
  /// so `elapsed == limit` is a timeout. Reading it the other way makes the
  /// exact-zero tap a reveal, which is the one case a user cannot tell apart
  /// from a miss and would experience as the app being generous at random.
  ///
  /// **A predicate rather than an outcome.** It used to return a `RecallOutcome`
  /// and therefore had to name the *other* side of the mark — which is how
  /// "revealed" became a gradeable result. What the clock knows is one bit: is
  /// the turn still the learner's to answer.
  bool didTimeOut({required Duration elapsed}) => elapsed >= kRecallTurnLimit;

  /// What remains of the limit, never below zero.
  ///
  /// Stored so Resume continues the turn instead of restarting it (BR-133). A
  /// turn of the same card in a later round is a **different** turn and starts
  /// at the full limit again.
  Duration remainingAfter(Duration elapsed) {
    final remaining = kRecallTurnLimit - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }
}
