import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/fallback/route_not_found_screen.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_names.dart';
import 'package:memox/features/review/presentation/review_placeholder_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

/// The route table, exercised through the real app root.
///
/// Every test builds its own router. A `GoRouter` carries navigation history, so
/// one shared instance would let a location entered here decide where the next
/// test starts — the kind of coupling that shows up as a suite which passes in
/// order and fails when run alone.
void main() {
  final english = AppLocalizationsEn();

  /// Pumps the real root with a router nobody else holds.
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String? initialLocation,
  }) async {
    final router = initialLocation == null
        ? createAppRouter()
        : createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(MemoxApp(router: router));
    await tester.pumpAndSettle();

    return router;
  }

  group('root', () {
    testWidgets('the app renders through the router, not through home', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(ReviewPlaceholderScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MemoxApp uses MaterialApp.router', (tester) async {
      // `MaterialApp.router` leaves `home` null and carries a `routerDelegate`.
      // Asserting both is what stops a future edit from quietly reinstating
      // `home:` and leaving the router registered but unused.
      await pumpApp(tester);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.home, isNull);
      expect(app.routerConfig, isNotNull);
    });
  });

  group('navigation by name', () {
    testWidgets('goNamed reaches the review route', (tester) async {
      // Proves the name is actually registered. A path-based test would pass
      // even if `name:` had been left off the route entirely.
      final router = await pumpApp(tester);

      router.goNamed(RouteNames.review);
      await tester.pumpAndSettle();

      expect(find.byType(ReviewPlaceholderScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the redirect hook lets ordinary navigation through', (
      tester,
    ) async {
      // The MVP has no auth, so the guard point must be inert. Reading the
      // location back rather than trusting the rendered screen: a redirect to
      // some other route that also happened to render the placeholder would
      // look identical on screen.
      final router = await pumpApp(tester);

      router.goNamed(RouteNames.review);
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
      expect(appRedirect, isNotNull);
    });
  });

  group('unknown route', () {
    const missing = '/this-route-does-not-exist';

    testWidgets('falls back to the 404 screen instead of a red screen', (
      tester,
    ) async {
      await pumpApp(tester, initialLocation: missing);

      expect(find.byType(RouteNotFoundScreen), findsOneWidget);
      expect(find.byType(ReviewPlaceholderScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows localized copy and no technical detail', (tester) async {
      await pumpApp(tester, initialLocation: missing);

      expect(find.text(english.pageNotFoundTitle), findsOneWidget);
      expect(find.text(english.pageNotFoundMessage), findsOneWidget);
      // The failed location must not reach the screen: a user cannot act on it,
      // and once deep links exist a location can carry card content.
      expect(find.textContaining(missing), findsNothing);
    });

    testWidgets('the action returns to the main route', (tester) async {
      await pumpApp(tester, initialLocation: missing);

      await tester.tap(find.text(english.goHomeAction));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewPlaceholderScreen), findsOneWidget);
      expect(find.byType(RouteNotFoundScreen), findsNothing);
    });

    testWidgets('is built from the shared components', (tester) async {
      // Not a re-test of those components' layout — this asserts the fallback
      // did not grow its own Scaffold and its own error column, which is how a
      // 404 ends up looking like a different app than the one it interrupts.
      await pumpApp(tester, initialLocation: missing);

      expect(
        find.descendant(
          of: find.byType(RouteNotFoundScreen),
          matching: find.byType(MxContentShell),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(RouteNotFoundScreen),
          matching: find.byType(MxErrorState),
        ),
        findsOneWidget,
      );
    });
  });
}
