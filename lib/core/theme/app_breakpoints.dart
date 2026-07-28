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
  static const double medium = 600;
}
