/// Corner radii.
///
/// Restrained on purpose: this is a study tool for adults at work, and heavily
/// rounded surfaces read as playful rather than focused.
abstract final class AppRadius {
  /// The v3 Radius table's 4 — the 20px checkbox. No caller here yet; added
  /// for the ladder, not re-pointed to a component (R1).
  static const double xs = 4;

  /// Chips, badges, small indicators today; the v3 Radius table's 8 is "icon
  /// tile (28dp), compact button" (R1 — existing bindings are not re-pointed).
  static const double sm = 8;

  /// Buttons and inputs today; the v3 Radius table's 12 also covers notes,
  /// snackbars and other small controls.
  static const double md = 12;

  /// Sheets today; the v3 Radius table's 16 is the FAB and the bottom-nav
  /// bar. **No longer a card radius** — `MxCard`'s page-level recipes moved
  /// to [xl] at the Card component pass, closing the gap this doc used to
  /// admit ("cards and sheets today").
  static const double lg = 16;

  /// `MxCard`'s own corner — every recipe except `.tile` (control corner,
  /// [md]) and `.option` (row/control shape, [lg]). The v3 Radius table's 20
  /// also names the dialog, the bottom-sheet top corners and the 64dp
  /// empty-state tile.
  static const double xl = 20;

  /// The v3 Radius table's 24. No v3 call site claims it yet (R8) — kept on
  /// the ladder for the component spec that does.
  static const double xxl = 24;

  /// Fully rounded, for pill-shaped controls.
  static const double pill = 999;
}
