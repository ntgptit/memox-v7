import 'app_sizing.dart';

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
  ///
  /// **A gap, never a size.** The same 32 as a box's width, height or an
  /// icon's size is `AppSizing.controlDense`; `spacing_is_a_gap_test.dart`
  /// refuses a spacing token on both axes of one box (A20.1 P2-12).
  static const double xxl = 32;

  /// The permitted values, in order. `AppSpacing` is the only source of
  /// spacing, so a test can assert the scale did not quietly grow a step.
  static const List<double> scale = <double>[xs, sm, md, lg, xl, xxl];

  /// The bottom inset a scrollable needs on a screen with a floating action
  /// button, so the last row can scroll clear of it: the button itself plus a
  /// [lg] gap on each side. Derived, not chosen — it is a clearance, not a step
  /// on [scale], and any screen that grows a FAB reads it from here instead of
  /// re-adding the same three numbers.
  ///
  /// **The one member here that is not a gap, and it stays because it is one
  /// anyway.** What it measures is empty space at the foot of a list; the
  /// button's own extent is [AppSizing.floatingAction], read rather than
  /// repeated. The touch-target floor that used to sit beside it left for
  /// `AppSizing` at M100.29 — a control's height was never a gap.
  static const double fabScrollClearance = AppSizing.floatingAction + lg + lg;
}
