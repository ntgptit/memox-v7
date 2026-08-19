/// What one fire-time evaluation actually did (BR-220).
///
/// **A returned value, not a log line.** The three skips are business outcomes
/// with different causes, and the only place they can be observed is a
/// background isolate — so a host test asserts on this enum instead of on
/// whether a notification appeared on a device nobody in CI is holding.
///
/// Nothing here carries a count or a deck name: the outcome says what happened,
/// and BR-222 keeps the content in `ReminderSummaryModel`, which never reaches a
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

  /// Nothing is due any more (BR-220). The ordinary skip.
  skippedNothingDue,

  /// This local day has already had its summary (BR-221).
  ///
  /// **The schedule is not the only thing that can post twice.** A run that
  /// delivered and then failed on its way out reports failure to the OS, and
  /// WorkManager retries it — with the same settings and the same unstudied
  /// cards, so the second attempt would post again.
  ///
  /// It cannot cover a process killed between the notification and the write
  /// that records it: what this reads does not exist yet at that instant. That
  /// window is narrowed instead of closed — the delivery no longer reports
  /// failure when only the *recording* failed, so the ordinary case stops
  /// asking for the retry that would post again.
  skippedAlreadyServed,
}
