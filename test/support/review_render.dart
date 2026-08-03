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

/// The default review surface: a phone in logical pixels, `devicePixelRatio` 1
/// so the PNG reads 1:1. Matches the frame the app imposes on web (AD-04).
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
    super.key,
  });

  final Widget home;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.dark ? buildDarkTheme() : buildLightTheme(),
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
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
Future<void> pumpReview(
  WidgetTester tester,
  Widget root, {
  Size surface = kReviewSurface,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  debugDisableShadows = false;

  await tester.pumpWidget(root);
  await tester.pumpAndSettle();
}

/// Captures the review golden at [path] for [finder], then restores
/// `debugDisableShadows` to the value the framework's paint-vars assertion
/// expects. Call this instead of a bare `expectLater(..., matchesGoldenFile)`
/// after [pumpReview].
Future<void> matchesReviewGolden(Finder finder, String path) async {
  await expectLater(finder, matchesGoldenFile(path));
  debugDisableShadows = true;
}
