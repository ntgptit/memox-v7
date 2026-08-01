/// Layout breakpoints.
///
/// Mobile-first, matching AD-04: Android is the release target and the web
/// build is framed to a phone. There is no desktop breakpoint because nothing
/// in the MVP has a desktop layout to switch to — adding one now would be a
/// branch no code takes.
abstract final class AppBreakpoints {
  /// Below this, treat the screen as cramped.
  ///
  /// **360 is also the smallest screen a whole *screen* is promised to fit.**
  /// `design_system/readme.md` declares it as the design's one real breakpoint,
  /// and for a long time the screen tests ran at 320x568 — forty pixels below
  /// the floor the design ever claimed. Nothing was gained by it: what it
  /// produced was a run of spacing trades, each shaving a section break to buy
  /// back a few pixels on a size no supported device reports. Screen tests run
  /// at 360x640 now, at `textScaler` 2.0, which is the guarantee worth keeping.
  ///
  /// **The compact tier below 360 stays, and is still tested per component.**
  /// `applyCompactScale` and this predicate are a safety net for a screen that
  /// turns up anyway; a component that degrades below the floor is cheap, while
  /// a whole screen laid out for a size nobody ships is what was expensive.
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
