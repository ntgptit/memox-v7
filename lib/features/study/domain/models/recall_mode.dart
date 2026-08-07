import 'study_entry_summary_model.dart';
import 'study_mode.dart';

/// How long one `recall` turn lasts (BR-128).
const Duration kRecallTurnLimit = Duration(seconds: 20);

/// How a `recall` turn ended.
///
/// **Exactly one of these is recorded per turn** (BR-129). The interesting case
/// is the instant the clock reaches zero with a tap already in flight: an
/// implementation that lets both through writes two turns for one question, and
/// one that lets neither through hangs the session.
enum RecallOutcome {
  /// The user revealed the answer before the clock ran out.
  revealed,

  /// The clock reached zero. Counts as wrong, and cannot be argued with
  /// afterwards (BR-130).
  timedOut,
}

/// Remember it before the clock runs out.
final class RecallModeHandler implements StudyModeHandler {
  const RecallModeHandler();

  @override
  int capacityFrom(StudyEntrySummaryModel summary) => summary.dueCount;

  /// Decides the single outcome of a turn (BR-129).
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
  RecallOutcome outcomeFor({required Duration elapsed}) =>
      elapsed < kRecallTurnLimit
      ? RecallOutcome.revealed
      : RecallOutcome.timedOut;

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
