/// Icon sizes.
///
/// Three steps covered everything UC-05 draws. The fourth is not a guess: the
/// study session's top bar packs a close button, a mode chip, a progress track
/// and a counter into one row, and at [md] the glyph pushed the track down to
/// half the width it needs to read as a measure. The v3 Icons ladder adds a
/// fifth step, [lg] at 32 — the old [lg] (40) is renamed [xl] to make room
/// (R8).
abstract final class AppIconSize {
  /// Inline with body text.
  static const double sm = 16;

  /// Default for actions and list affordances.
  static const double md = 24;

  /// An action sharing a row with something that needs the width.
  static const double mdCompact = 20;

  /// An icon carrying more weight than [md] without becoming illustrative —
  /// the step between a default glyph and a hero one (v3 Icons ladder, 32).
  static const double lg = 32;

  /// Illustrative icon in an empty or error state (v3 Icons ladder, 40).
  static const double xl = 40;
}
