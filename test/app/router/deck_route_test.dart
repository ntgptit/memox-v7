import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_names.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/features/deck/presentation/deck_detail_screen.dart';
import 'package:memox/features/deck/presentation/root_deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';

/// The nested deck route, exercised through the real app root.
///
/// Split from `app_router_test.dart` so neither file outgrows the project's
/// file-size limit. The shared pump helper lives in both because it is short and
/// duplicating four lines beats a third file that exists only to hold them.
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

  group('the deck detail route', () {
    /// A repository that can serve one deck, so the nested route has something
    /// to render.
    FakeDeckRepository servingDeck() => FakeDeckRepository(
      deckById: (id) async => fakeRootDeck(id: id, name: 'Japanese N5'),
      childDecks: (_) => Stream<List<DeckEntity>>.value(const <DeckEntity>[]),
    );

    testWidgets('a deep link to /decks/<id> opens that deck', (tester) async {
      await pumpApp(
        tester,
        initialLocation: '/decks/deck-1',
        repository: servingDeck(),
      );

      expect(find.byType(DeckDetailScreen), findsOneWidget);
      expect(find.text('Japanese N5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('it stays inside the Decks branch, bar and all', (
      tester,
    ) async {
      // A child route rather than a top-level one. As a top-level route the deck
      // screen would open with no bottom bar and no branch to go back into.
      await pumpApp(
        tester,
        initialLocation: '/decks/deck-1',
        repository: servingDeck(),
      );

      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(selectedTab(tester), 0);
    });

    testWidgets('goNamed with a path parameter reaches it', (tester) async {
      // By name and by parameter constant, so neither half is a literal that the
      // compiler cannot check against the other.
      final router = await pumpApp(tester, repository: servingDeck());

      router.goNamed(
        RouteNames.deckDetail,
        pathParameters: <String, String>{RoutePathParams.deckId: 'deck-9'},
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeckDetailScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/decks/deck-9',
      );
    });

    testWidgets('back returns to the root deck list', (tester) async {
      final router = await pumpApp(tester, repository: servingDeck());

      router.goNamed(
        RouteNames.deckDetail,
        pathParameters: <String, String>{RoutePathParams.deckId: 'deck-1'},
      );
      await tester.pumpAndSettle();
      expect(find.byType(DeckDetailScreen), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      expect(find.byType(RootDeckListScreen), findsOneWidget);
      expect(find.byType(DeckDetailScreen), findsNothing);
    });

    testWidgets('switching to Review and back keeps the deck open', (
      tester,
    ) async {
      // The branch stack, which is what `indexedStack` buys. A plain route set
      // would drop the pushed deck screen on the way out.
      final router = await pumpApp(tester, repository: servingDeck());
      router.goNamed(
        RouteNames.deckDetail,
        pathParameters: <String, String>{RoutePathParams.deckId: 'deck-1'},
      );
      await tester.pumpAndSettle();

      await tester.tap(tab(english.navigationReviewLabel));
      await tester.pumpAndSettle();
      await tester.tap(tab(english.navigationDecksLabel));
      await tester.pumpAndSettle();

      expect(find.byType(DeckDetailScreen), findsOneWidget);
    });

    testWidgets('a deck that no longer exists shows the not-found state', (
      tester,
    ) async {
      // UC-03 E1 through the route: a stale deep link must not crash or land on
      // a blank screen.
      await pumpApp(
        tester,
        initialLocation: '/decks/gone',
        repository: FakeDeckRepository.failing(
          const NotFoundFailure(message: 'That deck no longer exists.'),
        ),
      );

      expect(find.text(english.deckDetailNotFoundTitle), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
