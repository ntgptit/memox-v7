import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/golden_density.dart';

/// The one way a component golden gets on screen.
///
/// Split from `mx_components_golden_test.dart` at the 400-line guard, like
/// `golden_surfaces.dart` before it. The helper is the part both golden suites
/// (full-width and compact) must share verbatim: if the two pumped their
/// specimens differently, a diff between their baselines would measure the
/// harness, not the component.

/// The logical surface every full-width component golden is shot at.
const Size kGoldenSurface = Size(360, 640);

/// Pins everything that can move a pixel: surface size, device pixel ratio,
/// text scale and locale. Fonts are pinned too, but not here —
/// `test/flutter_test_config.dart` loads Roboto and MaterialIcons before any
/// test runs.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required bool isDark,
  Size at = kGoldenSurface,
}) async {
  tester.view.physicalSize = goldenSurfaceFor(at);
  tester.view.devicePixelRatio = kGoldenDevicePixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? buildDarkTheme() : buildLightTheme(),
      locale: const Locale('en'),
      home: Builder(
        // `copyWith`, never a fresh `MediaQueryData`: constructing one
        // zeroes `size`, `padding` and `viewInsets`, so the widget under
        // test is told the screen is 0x0 while `tester.view` says
        // otherwise. Anything that reads the width then branches on a
        // number no device reports.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
