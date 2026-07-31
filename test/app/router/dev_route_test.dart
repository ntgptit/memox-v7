import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/dev/design_system_showcase_screen.dart';
import 'package:memox/app/fallback/route_not_found_screen.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Both sides of the dev-route gate.
///
/// Pumped without `MemoxApp` on purpose: the showcase route needs no
/// providers, and going through the real root would drag the deck repository
/// into a test about whether a route exists. The delegates are still real
/// because the 404 fallback reads ARB copy.
void main() {
  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    required bool includeDevRoutes,
  }) async {
    final router = createAppRouter(
      initialLocation: RoutePaths.devDesignSystem,
      includeDevRoutes: includeDevRoutes,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('with dev routes on, the path opens the showcase', (
    tester,
  ) async {
    // `includeDevRoutes: true` here is what a debug build gets by default —
    // the default is `kDebugMode`, which is also true under `flutter test`,
    // but stating it keeps the test meaning one thing in every build mode.
    await pumpRouter(tester, includeDevRoutes: true);

    expect(find.byType(DesignSystemShowcaseScreen), findsOneWidget);
    expect(find.byType(RouteNotFoundScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with dev routes off, the path is a 404 — release behaviour', (
    tester,
  ) async {
    await pumpRouter(tester, includeDevRoutes: false);

    expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    expect(find.byType(DesignSystemShowcaseScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
