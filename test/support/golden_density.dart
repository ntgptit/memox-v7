import 'dart:ui';

/// The device pixel ratio every golden is rasterised at.
///
/// **Three, and it is derived rather than picked.** It is the density of the two
/// phones the design system frames its own kit against — an iPhone 13 mini is
/// 3×, an S23 Ultra 3.5× — so a golden is what one of those panels would
/// actually show rather than a third of it.
///
/// Goldens were rasterised at 1 until M4.10w, which meant a 420×1040 logical
/// screen produced a 420×1040 PNG: legible, but soft enough that reading a
/// review of one was guesswork about whether an edge was wrong or just
/// undersampled. Nothing about the *layout* changed — logical size is
/// `physicalSize / devicePixelRatio`, so a widget still lays out at exactly the
/// same numbers and every rect assertion in the suite is unaffected. Only the
/// raster got finer.
///
/// The cost is on disk: 64 goldens went from 646 KB to a few megabytes. Flat UI
/// compresses well, so the growth is far short of the 9× the pixel count
/// suggests, and a golden nobody can read is not worth its bytes either.
///
/// Layout tests that set their own `devicePixelRatio` deliberately keep 1 — they
/// measure logical rects, which this does not touch, and a larger raster there
/// would cost time for nothing.
const double kGoldenDevicePixelRatio = 3;

/// The physical surface needed to render [logical] at [kGoldenDevicePixelRatio].
Size goldenSurfaceFor(Size logical) => logical * kGoldenDevicePixelRatio;
