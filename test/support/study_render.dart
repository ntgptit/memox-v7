/// Device-faithful **review renders** — PNGs a human looks at to judge a real
/// screen, not pixel-regression baselines.
///
/// **Why this exists: the shadow trap.** `flutter_test` defaults
/// `debugDisableShadows = true`, which draws every elevation shadow as a hard
/// black silhouette — the "border" that appears around a `FloatingActionButton`
/// or a `Card`. A regression golden wants that (a real shadow is
/// platform-dependent and makes a baseline flaky), but a review render wants the
/// soft shadow a device actually draws. [pumpReview] turns the flag off for the
/// captured frame and [matchesReviewGolden] restores it, so no review test
/// re-discovers the trap or re-writes the fix.
///
/// **Not for the strict goldens.** `mx_components_golden_test` and the
/// `visual_audit` suite keep shadows disabled on purpose; use `matchesGoldenFile`
/// directly there. This is only for the demo/preview renders whose whole point is
/// faithfulness to what a phone shows.
///
/// Every review render is a `golden` (windows-bound pixels, run on the CI golden
/// job, excluded on Linux); tag the test file `@Tags(<String>['golden', ...])`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'golden_density.dart';

import 'layout_probe.dart';

/// The default review surface, in **logical** pixels: the frame the app imposes
/// on web (AD-04).
///
/// Rasterised at [kGoldenDevicePixelRatio], so the PNG is three times this on
/// each side. It read 1:1 until then, which was the wrong half of the trade for
/// the one suite whose entire purpose is a human looking at it: M4.10w moved the
/// strict goldens and the design previews to 3 precisely because reviewing an
/// undersampled render is guesswork about whether an edge is wrong or just
/// short of pixels — and these renders were left behind, so the images most
/// meant to be read were the softest in the repo.
///
/// Nothing about layout changes: logical size is `physicalSize / dpr`, so every
/// widget lays out at exactly the same numbers and no rect assertion moves.
const Size kReviewSurface = Size(393, 852);

/// The production-themed, localized `MaterialApp` a review render pumps.
///
/// The caller wraps it in the `ProviderScope` its screen needs — Riverpod's
/// `Override` is not a public type, so a shared helper cannot take an overrides
/// list itself (the same reason `repository_bindings.dart` uses factory
/// functions). This keeps the theme + localization boilerplate in one place while
/// the overrides stay at the call site where they differ.
class ReviewApp extends StatelessWidget {
  const ReviewApp({
    required this.home,
    this.brightness = Brightness.light,
    this.isHighContrast = false,
    this.locale,
    this.textScale = 1,
    super.key,
  });

  final Widget home;
  final Brightness brightness;

  /// The high-contrast pair the app wires beside light and dark — rendered
  /// here so it has a picture (A20.1 P1-08).
  final bool isHighContrast;

  /// Null follows the platform, which in a test is English. Pass `Locale('vi')`
  /// to render the translation — a review render is where a long translation
  /// stops being a hypothetical.
  final Locale? locale;

  /// The text scale the whole app renders at, including anything pushed onto
  /// the navigator.
  ///
  /// **Applied through `builder`, not around `home`.** A `MediaQuery` inside
  /// `home` sits *below* the navigator, so a route pushed over it — a bottom
  /// sheet, a dialog — would render at 1.0 while the screen behind it scaled,
  /// which is exactly the combination a 2.0 render exists to inspect.
  final double textScale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: switch ((brightness, isHighContrast)) {
      (Brightness.dark, true) => buildHighContrastDarkTheme(),
      (Brightness.dark, false) => buildDarkTheme(),
      (Brightness.light, true) => buildHighContrastLightTheme(),
      (Brightness.light, false) => buildLightTheme(),
    },
    locale: locale,
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: textScale == 1
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
    home: home,
  );
}

/// Pumps [root] — a `ProviderScope` wrapping a [ReviewApp] — as a device-faithful
/// render with real elevation shadows, then settles.
///
/// Pair every call with [matchesReviewGolden]: it captures the frame and puts
/// `debugDisableShadows` back before the framework's end-of-test paint-vars
/// assertion runs. (The flag has to be off during the *paint*, so it cannot be
/// restored in a `tearDown` — that fires too late and trips the assertion.)
///
/// [surface] is **logical**, and `goldenSurfaceFor` turns it into the physical
/// one the density needs. Passing a physical size here would shrink the screen
/// to a third of itself rather than sharpen it.
Future<void> pumpReview(
  WidgetTester tester,
  Widget root, {
  Size surface = kReviewSurface,
  bool settle = true,
}) async {
  tester.view.physicalSize = goldenSurfaceFor(surface);
  tester.view.devicePixelRatio = kGoldenDevicePixelRatio;
  addTearDown(tester.view.reset);

  debugDisableShadows = false;

  await tester.pumpWidget(root);
  if (!settle) {
    // **One frame, for a face that never settles.** A loading face holds a
    // repeating animation open, so `pumpAndSettle` times out rather than
    // returning — which is why no render in this repo had ever photographed
    // one, and why a spinner inside a card could be laid out wrong for a whole
    // milestone with nothing to look at.
    //
    // This returns at t=0, and a caller photographing a spinner should **not**
    // capture there: at t=0 the indicator's sweep is zero length and the PNG is
    // a dot. Pump a fixed offset first — a constant duration is every bit as
    // deterministic as no duration, and it shows an arc.
    await tester.pump();

    return;
  }
  await tester.pumpAndSettle();
}

/// Captures the whole frame to [path], then restores `debugDisableShadows` to
/// the value the framework's paint-vars assertion expects. Call this instead of
/// a bare `expectLater(..., matchesGoldenFile)` after [pumpReview].
///
/// **The finder is fixed at the root, and that is what makes the density real.**
/// `captureImage` walks up to the nearest repaint boundary and rasterises that
/// layer in its own coordinate space, so a finder pointing at a screen inside the
/// app yields *logical* pixels — 393x852 no matter what `devicePixelRatio` says —
/// while the root reaches the `RenderView`, whose bounds are physical. Only
/// capturing at the root gets 1179x2556.
///
/// It crops, too, and silently. `find.byType(DeckListScreen)` returned a frame
/// 80 short of the surface because the navigation bar sits beside the screen
/// rather than inside it — so the one piece of chrome a reviewer most needs to
/// judge was missing from the picture meant for judging it.
///
/// Both failures come from letting the caller choose, and neither announces
/// itself: the PNG looks right until someone measures it. So there is no choice
/// to make.
Future<void> matchesReviewGolden(String path) async {
  await expectLater(find.byType(ReviewApp), matchesGoldenFile(path));
  // The same frame, measured. See `layout_probe.dart` for why the numbers are
  // taken here rather than by a suite of their own. Off unless asked for.
  if (isLayoutProbeEnabled) probeLayout(path);
  debugDisableShadows = true;
}
