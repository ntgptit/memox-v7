/// Spacing scale. Every gap, pad and inset in the app comes from here.
///
/// Six steps, deliberately. A scale wide enough to express "a bit more" invites
/// per-screen drift, and the drift is what makes an interface feel unfinished
/// long before anyone can point at a specific screen.
abstract final class AppSpacing {
  /// Between an icon and its label.
  static const double xs = 4;

  /// Between tightly related items in a row.
  static const double sm = 8;

  /// Inside a compact control.
  static const double md = 12;

  /// Standard screen padding and the gap between list items.
  static const double lg = 16;

  /// Between sections of a screen.
  static const double xl = 24;

  /// Around a lone focal element — an empty state, a single card in a session.
  static const double xxl = 32;

  /// The permitted values, in order. `AppSpacing` is the only source of
  /// spacing, so a test can assert the scale did not quietly grow a step.
  static const List<double> scale = <double>[xs, sm, md, lg, xl, xxl];
}
