/// Corner radii.
///
/// Restrained on purpose: this is a study tool for adults at work, and heavily
/// rounded surfaces read as playful rather than focused.
abstract final class AppRadius {
  /// Chips, badges, small indicators.
  static const double sm = 8;

  /// Buttons and inputs.
  static const double md = 12;

  /// Cards and sheets.
  static const double lg = 16;

  /// The study card, which is the one surface a whole screen is built around.
  ///
  /// **Four pixels above [lg], and it is the only thing at this radius.** A card
  /// filling the screen reads tighter than the same corner does on a list row,
  /// so the focal surface gets its own step rather than every card getting a
  /// softer one.
  static const double xl = 20;

  /// Fully rounded, for pill-shaped controls.
  static const double pill = 999;
}
