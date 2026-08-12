/// Where a deck stands against today's local calendar (BR-161).
///
/// **A presentation classification of BR-142's one Reviewing set, never a
/// third kind of session.** Every due card — today's or last week's — is the
/// same set a review session serves in the same order; what differs is how
/// urgently the list should read, and that is all this enum carries.
///
/// Derived at read time from the subtree's oldest due card, never stored: the
/// status changes at local midnight with no write anywhere, so a column would
/// be stale by construction.
enum DeckScheduleStatus {
  /// Nothing due right now. New cards may still be waiting — "not due" is not
  /// "nothing to do" (BR-150) — and a fully learned deck rests here too:
  /// completion belongs to the progress bar, not the schedule.
  notDue,

  /// Due cards exist and the oldest of them came due **today**, by the local
  /// calendar (BR-105). Actionable and entirely normal — the product working,
  /// not a warning (BR-29).
  dueToday,

  /// The oldest due card's day has passed: at least one completed local-day
  /// boundary lies between its `due_at` and now. Late study, not a system
  /// error — but it wears the error-container pair on purpose (owner decision,
  /// 2026-08-11, recorded on BR-161): missed reads red, and only missed does.
  /// The badge counts the days.
  overdue,
}

/// BR-161's classification, stated once (UC-06 step 3).
///
/// A single deck asks this through [DeckSummary.scheduleStatus]; a level asks
/// it through `DeckListSnapshot.levelScheduleStatus` after folding its
/// children. Both delegate here so the boundary conditions — is zero due
/// "today"? is zero days "overdue"? — cannot drift between callers.
///
/// Total over already-normalised counts: the mapper has turned the oldest due
/// instant into completed local days before anything up here runs, so this
/// function never touches a clock (AD-16).
DeckScheduleStatus deckScheduleStatusOf({
  required int dueCardCount,
  required int overdueDayCount,
}) {
  if (dueCardCount == 0) return DeckScheduleStatus.notDue;
  if (overdueDayCount == 0) return DeckScheduleStatus.dueToday;

  return DeckScheduleStatus.overdue;
}
