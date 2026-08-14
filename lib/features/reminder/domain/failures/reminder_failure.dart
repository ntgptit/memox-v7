/// Why turning the reminder on, off, or to another time did not complete.
///
/// **A value on the failure, not a message.** `Failure.message` is a sanitized
/// diagnostic the UI is forbidden to render; the screen switches on one of
/// these and picks ARB copy, so a new reason fails to compile until it has a
/// sentence of its own (see `Failure.reason`).
///
/// Each value is a different screen. [platformUnavailable] has no recovery and
/// must not offer one; [permissionDenied] recovers through system settings; the
/// remaining three recover through a retry, and the retry re-runs **the command
/// that failed** rather than a fixed one — a single hardwired retry turned
/// "turning it off failed" into "turn it back on".
enum ReminderSetupRejection {
  /// This build cannot deliver reminders here at all (BR-193).
  platformUnavailable,

  /// The OS refused the notification permission (BR-192).
  ///
  /// The setting stays off. Android grants one prompt per app, so the recovery
  /// is system settings, not another ask.
  permissionDenied,

  /// The OS accepted the request but the work could not be enqueued (BR-190).
  scheduleFailed,

  /// The reminder was turned off, but the pending run could not be cancelled
  /// (BR-190).
  ///
  /// **Separate from [scheduleFailed] because the user is in a different
  /// place.** The setting is already off and the toggle already shows it, so
  /// copy saying "nothing was turned on" would describe the opposite of what
  /// just happened. The stale run is harmless — delivery re-reads the settings
  /// row and skips (BR-184) — but the user is owed the truth about it.
  cancelFailed,

  /// The choice could not be written to the database.
  ///
  /// Distinct from [scheduleFailed] because the recoveries differ: a retry here
  /// re-runs a local write, while a retry there re-enters the platform.
  settingsWriteFailed,
}
