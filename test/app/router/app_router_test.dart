import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/app/fallback/route_not_found_screen.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/review/presentation/review_placeholder_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';

/// The route table, exercised through the real app root.
///
/// Every test builds its own router. A `GoRouter` carries navigation history, so
/// one shared instance would let a location entered here decide where the next
/// test starts — the kind of coupling that shows up as a suite which passes in
/// order and fails when run alone.
///
/// The home route now reads from the deck repository, so the root is pumped
/// inside a `ProviderScope` with that contract faked. Without the override the
/// screen would open the real on-device database, and a routing test would fail
/// for a storage reason.
void main() {
  final english = AppLocalizationsEn();

  /// The tab label, not the screen title.
  ///
  /// In English `decksTitle` and `navigationDecksLabel` are both "Decks", so a
  /// bare `find.text('Decks')` matches the app bar and the tab at once and
  /// every tap becomes ambiguous. Scoping to the bar is what keeps these tests
  /// about navigation.
  Finder tab(String label) => find.descendant(
    of: find.byType(MxNavigationBar),
    matching: find.text(label),
  );

  /// Which destination the bar is currently showing as selected.
  int selectedTab(WidgetTester tester) => tester
      .widget<MxNavigationBar>(find.byType(MxNavigationBar))
      .selectedIndex;

  /// Pumps the real root with a router nobody else holds.
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String? initialLocation,
    FakeDeckRepository? repository,
  }) async {
    final router = initialLocation == null
        ? createAppRouter()
        : createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(
            repository ?? FakeDeckRepository(),
          ),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  group('root', () {
    testWidgets('cold start opens the root deck list, through the router', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(DeckListScreen), findsOneWidget);
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

  group('the navigation shell', () {
    testWidgets('cold start selects Decks, not Review', (tester) async {
      await pumpApp(tester);

      expect(find.byType(DeckListScreen), findsOneWidget);
      expect(selectedTab(tester), 0);
    });

    testWidgets('tapping Review opens the review placeholder', (tester) async {
      await pumpApp(tester);

      await tester.tap(tab(english.navigationReviewLabel));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewPlaceholderScreen), findsOneWidget);
      expect(selectedTab(tester), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Decks comes back to the root deck list', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(tab(english.navigationReviewLabel));
      await tester.pumpAndSettle();
      await tester.tap(tab(english.navigationDecksLabel));
      await tester.pumpAndSettle();

      expect(find.byType(DeckListScreen), findsOneWidget);
      expect(selectedTab(tester), 0);
    });

    testWidgets('a deep link to /review opens on the Review tab', (
      tester,
    ) async {
      // The reason Review has a real path rather than living under `/`. Opening
      // Decks first and then jumping would be visible to the user, and would
      // make the back button land somewhere they never chose to be.
      await pumpApp(tester, initialLocation: RoutePaths.review);

      expect(find.byType(ReviewPlaceholderScreen), findsOneWidget);
      expect(find.byType(DeckListScreen), findsNothing);
      expect(selectedTab(tester), 1);
    });

    testWidgets('switching away and back does not rebuild the branch', (
      tester,
    ) async {
      // What `indexedStack` buys, measured rather than assumed. The deck screen
      // stays mounted while Review is on top, so its stream subscription
      // survives — one summary subscription for the whole round trip. Replace the
      // shell with plain top-level routes and this becomes 2, which is the
      // "why did my place in the list disappear" bug in its smallest form.
      final repository = FakeDeckRepository();
      await pumpApp(tester, repository: repository);

      expect(repository.deckListCallCount, 1);

      await tester.tap(tab(english.navigationReviewLabel));
      await tester.pumpAndSettle();
      await tester.tap(tab(english.navigationDecksLabel));
      await tester.pumpAndSettle();

      expect(repository.deckListCallCount, 1);
      expect(find.byType(DeckListScreen), findsOneWidget);
    });

    testWidgets('re-selecting the current tab stays on its initial location', (
      tester,
    ) async {
      // With one route per branch there is no stack to pop, so what is
      // observable today is that the re-selection is handled rather than
      // throwing or navigating somewhere else. The pop-to-root half of
      // `goBranch(initialLocation: true)` becomes testable when deck detail
      // adds a second route to branch 0.
      final router = await pumpApp(tester);

      await tester.tap(tab(english.navigationDecksLabel));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
      expect(find.byType(DeckListScreen), findsOneWidget);
      expect(selectedTab(tester), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the bar is present on both branches', (tester) async {
      await pumpApp(tester);
      expect(find.byType(MxNavigationBar), findsOneWidget);

      await tester.tap(tab(english.navigationReviewLabel));
      await tester.pumpAndSettle();

      expect(find.byType(MxNavigationBar), findsOneWidget);
    });
  });

  group('navigation by name', () {
    testWidgets('goNamed reaches the deck route', (tester) async {
      // Proves the name is actually registered. A path-based test would pass
      // even if `name:` had been left off the route entirely.
      final router = await pumpApp(tester);

      router.goNamed(RouteNames.decks);
      await tester.pumpAndSettle();

      expect(find.byType(DeckListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('goNamed reaches the review route and moves the tab', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      router.goNamed(RouteNames.review);
      await tester.pumpAndSettle();

      expect(find.byType(ReviewPlaceholderScreen), findsOneWidget);
      // Navigating by name from outside the bar must still leave the bar
      // telling the truth — the selected index comes from the router, not from
      // whichever widget happened to trigger the navigation.
      expect(selectedTab(tester), 1);
    });

    testWidgets('the redirect hook lets ordinary navigation through', (
      tester,
    ) async {
      // The MVP has no auth, so the guard point must be inert. Reading the
      // location back rather than trusting the rendered screen: a redirect to
      // some other route that also happened to render the deck list would look
      // identical on screen.
      final router = await pumpApp(tester);

      router.goNamed(RouteNames.decks);
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
      expect(find.byType(DeckListScreen), findsNothing);
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

    testWidgets('the action returns to the root deck list', (tester) async {
      await pumpApp(tester, initialLocation: missing);

      await tester.tap(find.text(english.goHomeAction));
      await tester.pumpAndSettle();

      expect(find.byType(DeckListScreen), findsOneWidget);
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
