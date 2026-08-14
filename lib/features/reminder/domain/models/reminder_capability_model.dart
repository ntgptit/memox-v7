/// Whether this device can deliver a daily reminder at all (BR-193).
///
/// **A value, not a platform check.** `domain/` and `presentation/` never ask
/// which operating system they are on; they ask the platform contract what it
/// can do, and get one of these back. That is what keeps a `Platform.isAndroid`
/// out of a widget and out of a use case, and what lets a test drive the
/// unsupported branch without a fake platform.
enum ReminderCapability {
  /// Reminders can be scheduled and shown here.
  supported,

  /// This platform has no reminder delivery in this build (Web, iOS).
  ///
  /// The settings screen renders a disabled control and says so, rather than a
  /// toggle that flips and does nothing.
  unsupported,
}

/// Whether the operating system will let the app post a notification (BR-192).
///
/// Three values, not a `bool`, because "not asked yet" and "asked and refused"
/// lead to different screens: the first is the ordinary path into an opt-in,
/// the second is a recoverable dead end that has to explain itself. Collapsing
/// them is how an app ends up re-prompting a user who already said no — which
/// Android only honours once, so the second ask is silently a no.
enum ReminderPermission {
  /// The app may post notifications.
  granted,

  /// The user refused, or the OS refused on their behalf.
  denied,

  /// No decision has been recorded yet, and none has been asked for.
  notRequested,
}
