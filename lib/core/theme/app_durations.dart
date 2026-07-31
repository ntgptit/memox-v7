import 'package:flutter/animation.dart';

/// Motion durations.
///
/// Short and few. During a review session the user is answering, not watching;
/// animation that draws attention to itself costs recall.
abstract final class AppDurations {
  /// State changes that must not feel like a jump — button press, ripple.
  static const Duration fast = Duration(milliseconds: 120);

  /// Card and surface transitions.
  static const Duration normal = Duration(milliseconds: 200);

  /// The longest anything in the app is allowed to take.
  static const Duration slow = Duration(milliseconds: 320);

  /// The app's two easing curves.
  ///
  /// Named for the same reason the durations are: a `Curves.decelerate` written
  /// at a call site is a motion decision nobody can find later, and the two the
  /// design declares are not Flutter's presets — `--ease-standard` is
  /// `cubic-bezier(0.2,0,0,1)` and `--ease-decelerate` is `cubic-bezier(0,0,0,1)`,
  /// where `Curves.decelerate` is `(0, 0, 0.2, 1)`. Close enough to look right
  /// and not the same thing.
  ///
  /// [standard] for anything that starts and stops on screen; [decelerate] for
  /// something arriving at a value it then holds, which is what a progress bar
  /// does.
  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve decelerate = Cubic(0, 0, 0, 1);
}
