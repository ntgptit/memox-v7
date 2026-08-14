/// What one fire-time evaluation actually did (BR-184).
///
/// **A returned value, not a log line.** The three skips are business outcomes
/// with different causes, and the only place they can be observed is a
/// background isolate — so a host test asserts on this enum instead of on
/// whether a notification appeared on a device nobody in CI is holding.
///
/// Nothing here carries a count or a deck name: the outcome says what happened,
/// and BR-186 keeps the content in `ReminderSummaryModel`, which never reaches a
/// log.
enum ReminderDelivery {
  /// A summary notification was posted.
  posted,

  /// The user has turned the reminder off since this run was scheduled.
  ///
  /// Reached when a cancel did not take — a schedule that outlived its setting
  /// is the one thing a background worker cannot prevent, so it re-checks
  /// rather than trusting that it was cancelled.
  skippedDisabled,

  /// Nothing is due any more (BR-184). The ordinary skip.
  skippedNothingDue,
}
