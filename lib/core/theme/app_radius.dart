/// Corner radii.
///
/// Restrained on purpose: this is a study tool for adults at work, and heavily
/// rounded surfaces read as playful rather than focused.
abstract final class AppRadius {
  /// Chips, badges, small indicators.
  static const double sm = 8;

  /// Buttons and inputs.
  static const double md = 12;

  /// Cards and sheets — the study card itself.
  static const double lg = 16;

  /// Fully rounded, for pill-shaped controls.
  static const double pill = 999;
}
