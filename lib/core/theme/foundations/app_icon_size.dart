/// Icon sizes.
///
/// Three steps covered everything UC-05 draws. The fourth is not a guess: the
/// study session's top bar packs a close button, a mode chip, a progress track
/// and a counter into one row, and at [md] the glyph pushed the track down to
/// half the width it needs to read as a measure.
abstract final class AppIconSize {
  /// Inline with body text.
  static const double sm = 16;

  /// Default for actions and list affordances.
  static const double md = 24;

  /// An action sharing a row with something that needs the width.
  static const double mdCompact = 20;

  /// Illustrative icon in an empty or error state.
  static const double lg = 40;
}
