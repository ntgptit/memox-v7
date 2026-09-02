import 'package:flutter/material.dart';

/// Whether a finite animation is allowed to run at all.
///
/// **`AppDurations` cannot answer this, and that is why this exists.** Those are
/// `const` — they say how long a movement takes, and a constant cannot read the
/// platform. So every custom animation in the app ran unconditionally: the
/// progress bar swept for 320ms and the search pill crossfaded for 120ms even
/// when the operating system had been told to reduce motion, which for a user
/// with vestibular sensitivity is the setting they turned on to stop exactly
/// that.
///
/// **Zero, not a shorter duration.** A 60ms sweep is still a sweep; the request
/// is for the interface to change state without moving, so the transition is
/// removed rather than hurried. `Duration.zero` through the same
/// `TweenAnimationBuilder` or `AnimatedContainer` lands on the final value in
/// the frame the change arrives, which is what "no animation" means without any
/// branch at the call site.
///
/// **Finite, non-essential transitions only.** An indeterminate spinner is not
/// covered and must not be: its motion *is* the information — it says work is
/// still running — and a spinner frozen at Duration.zero says the app has hung.
/// The accessibility contract asks for animation that decorates a state change
/// to be removed, not for feedback to be taken away.
abstract final class AppMotionPolicy {
  /// [duration] when animation is allowed, `Duration.zero` when the user has
  /// asked for it to be reduced.
  ///
  /// Reads `MediaQuery.disableAnimationsOf`, which is the platform's own
  /// accessibility flag — `AccessibilityFeatures.disableAnimations` on Android
  /// and iOS, `prefers-reduced-motion` on the web build. Not an app setting:
  /// there is none, and a second switch would let the two disagree.
  static Duration durationOf(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
