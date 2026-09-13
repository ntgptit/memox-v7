/// Corner radii — the handoff's radius roles, on the handoff's names.
abstract final class AppRadius {
  /// Badge, micro surface.
  static const double xs = 4;

  /// Small tile, icon tile.
  static const double sm = 8;

  /// Button, input.
  static const double md = 12;

  /// FAB.
  static const double lg = 16;

  /// Card, dialog, the bottom sheet's top corners — the roomiest common
  /// surface (D12: the Dialog and BottomSheet specs name 20 over 16 and 24).
  static const double card = 20;

  /// The handoff's `radius-xl`.
  static const double xl = 24;

  /// A large focal surface.
  static const double xxl = 28;

  /// Pill — chip, avatar, toggle track.
  static const double full = 999;
}
