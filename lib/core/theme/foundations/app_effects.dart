/// Visual effects that are neither an interaction state nor a colour — the v3
/// registry's `EFFECT_TOKEN` entries (docs/superpowers/specs/
/// 2026-09-18-memox-v3-theme-prerequisite.md §5.6).
///
/// **Kept out of `states/` on purpose.** Glass is translucency, not
/// interaction; a pressed or disabled policy that could reach these would be
/// the two layers sharing one channel.
abstract final class AppEffects {
  /// `op-glass` — the alpha chrome glass keeps over its runtime backdrop.
  /// `AppDerivedColors.chromeGlass` reads it, so 0.84 is authored once.
  static const double glassOpacity = 0.84;

  /// `glass-blur` — the blur behind glass chrome, as a Gaussian sigma.
  ///
  /// The registry's web value is `saturate(180%) blur(18px)`, a non-binding
  /// source trace. CSS `blur()` takes a standard deviation and so does
  /// `ImageFilter.blur`, so the number carries over as is. The saturation
  /// boost does not: it is a second filter pass over scrolling content for a
  /// web-only vibrancy cue, and blur alone carries the glass intent. Where a
  /// platform or the frame budget refuses live blur, the consumer keeps its
  /// solid or translucent fallback.
  static const double glassBlurSigma = 18;
}
