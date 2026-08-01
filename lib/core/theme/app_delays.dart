/// Interaction delays — how long the app waits before it reacts.
///
/// **Not `AppDurations`, and the split is deliberate.** A duration says how long
/// a movement takes; a delay says how long nothing happens. They are measured in
/// the same unit and they answer different questions, and putting a 500ms wait
/// into `AppDurations.slow` would break that file's own contract — `slow` is
/// documented as the ceiling on motion, so a 500 there says the app is allowed
/// to animate for half a second.
///
/// A delay is also exempt from the reduced-motion policy for the same reason:
/// `AppMotionPolicy` collapses movement, and a tooltip that appeared the instant
/// the pointer crossed it would fire on every pass across a toolbar.
abstract final class AppDelays {
  /// How long a pointer rests on a control before its tooltip appears.
  ///
  /// Material's own default, named rather than left implicit: every
  /// `MxIconButton` and the floating action carry a tooltip, so this is the
  /// delay the whole app is judged by.
  static const Duration tooltipWait = Duration(milliseconds: 500);
}
