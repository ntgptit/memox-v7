/// Icon sizes — the handoff's five roles. Visual size only; the touch area is
/// `AppSizing.touchTarget`, never a larger glyph.
abstract final class AppIconSize {
  /// Inline in body text, compact utility.
  static const double xs = 16;

  /// Compact control: dense rows, metadata, the FAB glyph, in-content icon
  /// buttons.
  static const double sm = 20;

  /// Standard action: app-bar and navigation actions.
  static const double md = 24;

  /// Large emphasis: feature tiles.
  static const double lg = 32;

  /// Illustrative: empty and error states, hero marks.
  static const double xl = 40;
}
