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
}
