/// Why turning the reminder on, off, or to another time did not complete.
///
/// **A value on the failure, not a message.** `Failure.message` is a sanitized
/// diagnostic the UI is forbidden to render; the screen switches on one of
/// these and picks ARB copy, so a new reason fails to compile until it has a
/// sentence of its own (see `Failure.reason`).
///
/// Each value is a different screen: [platformUnavailable] has no recovery and
/// must not offer one, [permissionDenied] recovers through system settings,
/// and the two failures recover through a retry that changes nothing else.
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

  /// The choice could not be written to the database.
  ///
  /// Distinct from [scheduleFailed] because the recoveries differ: a retry here
  /// re-runs a local write, while a retry there re-enters the platform.
  settingsWriteFailed,
}
