/// Layout breakpoints.
///
/// Mobile-first, matching AD-04: Android is the release target and the web
/// build is framed to a phone. There is no desktop breakpoint because nothing
/// in the MVP has a desktop layout to switch to — adding one now would be a
/// branch no code takes.
abstract final class AppBreakpoints {
  /// Below this, treat the screen as cramped: the 320x568 case every component
  /// is tested against.
  static const double compact = 360;

  /// Tablet and the framed web surface at its widest.
  ///
  /// Unused by production code, and deliberately kept that way: the project
  /// ships no large-screen layout, so nothing may branch on this. It exists as
  /// the documented upper edge of the phone range.
  static const double medium = 600;

  /// Whether [width] is narrow enough to need the compact scale.
  ///
  /// Width, not height. A 320-wide screen is short of horizontal room for text
  /// and gutters; a short screen is handled by scrolling instead, because
  /// shrinking type to win vertical space would apply on every device the
  /// moment a keyboard opened.
  static bool isCompact(double width) => width < compact;
}
