import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/card/di/card_detail_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/card/presentation/support/fake_card_detail_repository.dart';
import '../../features/card/presentation/support/fake_card_repository.dart';
import '../../features/deck/presentation/support/fake_deck_repository.dart';

/// The detail route (UC-12, M4.14 W1): its name, its URL, the order it is
/// registered in, and what a tap on a row now means.
///
/// **Through the real route table.** Where a bare `:cardId` sits among its
/// siblings is not a property of any screen — it is a property of the table,
/// and the failure it prevents (Add opening a detail screen for a card called
/// "new") is only visible from here.
void main() {
  const deckContext = DeckContextModel(
    deckName: 'TOPIK I',
    ancestors: <DeckBreadcrumbSegment>[],
  );

  FakeCardRepository cardRepo({int cards = 2}) {
    final repository = FakeCardRepository.loaded(
      <dynamic>[
        for (var index = 0; index < cards; index++)
          FakeCardRepository().listItem('c$index', front: 'front $index'),
      ].cast(),
      total: cards,
    );
    repository
      ..holdsCards = true
      ..deckContextToShow = deckContext;

    return repository;
  }

  FakeCardDetailRepository detailRepo() => FakeCardDetailRepository()
    ..seededDetail = fakeCardDetail(front: 'front 0')
    ..pages.add(CardHistoryPageModel.empty);

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required FakeCardRepository cards,
    FakeCardDetailRepository? detail,
    String initialLocation = '/decks/deck-1/cards',
  }) async {
    final router = createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);
    addTearDown(cards.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          cardRepositoryProvider.overrideWithValue(cards),
          cardDetailRepositoryProvider.overrideWithValue(
            detail ?? detailRepo(),
          ),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('goNamed builds /decks/<id>/cards/<cardId> and mounts the '
      'detail screen', (tester) async {
    final router = await pumpApp(tester, cards: cardRepo());

    router.goNamed(
      RouteNames.cardDetail,
      pathParameters: <String, String>{
        RoutePathParams.deckId: 'deck-1',
        RoutePathParams.cardId: 'c0',
      },
    );
    await tester.pumpAndSettle();

    expect(find.byType(CardDetailScreen), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/decks/deck-1/cards/c0',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a deep link opens the detail screen directly', (tester) async {
    await pumpApp(
      tester,
      cards: cardRepo(),
      initialLocation: '/decks/deck-1/cards/c0',
    );

    expect(find.byType(CardDetailScreen), findsOneWidget);
  });

  group('the bare :cardId segment is registered last (M4.14 W1)', () {
    testWidgets('/cards/new still reaches the editor, not a detail screen for '
        'a card called "new"', (tester) async {
      await pumpApp(
        tester,
        cards: cardRepo(),
        initialLocation: '/decks/deck-1/cards/new',
      );

      expect(find.byType(CardEditorScreen), findsOneWidget);
      expect(find.byType(CardDetailScreen), findsNothing);
    });

    testWidgets('/cards/import still reaches the wizard', (tester) async {
      await pumpApp(
        tester,
        cards: cardRepo(),
        initialLocation: '/decks/deck-1/cards/import',
      );

      expect(find.byType(CardImportScreen), findsOneWidget);
      expect(find.byType(CardDetailScreen), findsNothing);
    });

    testWidgets('/cards/<id>/edit still reaches the editor', (tester) async {
      await pumpApp(
        tester,
        cards: cardRepo(),
        initialLocation: '/decks/deck-1/cards/c0/edit',
      );

      expect(find.byType(CardEditorScreen), findsOneWidget);
      expect(find.byType(CardDetailScreen), findsNothing);
    });
  });

  group('what a tap means (BR-189)', () {
    testWidgets('a tap on a row outside selection mode opens the detail '
        'screen, not the editor', (tester) async {
      await pumpApp(tester, cards: cardRepo());

      await tester.tap(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();

      expect(find.byType(CardDetailScreen), findsOneWidget);
      expect(find.byType(CardEditorScreen), findsNothing);
    });

    testWidgets('a tap inside selection mode toggles and does not '
        'navigate', (tester) async {
      await pumpApp(tester, cards: cardRepo());

      await tester.longPress(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();
      // The same row again: inside the mode a tap toggles it, and toggling is
      // all it may do. Tapping the *second* row would be the same assertion
      // through a target that sits below the fold on this surface.
      await tester.tap(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();

      expect(find.byType(CardDetailScreen), findsNothing);
      expect(find.byType(CardListScreen), findsOneWidget);
      // The row went back to unselected rather than opening anything: the tap
      // changed which rows are picked, and nothing else.
      final tile = tester.widget<CardTileWidget>(
        find.byType(CardTileWidget).first,
      );
      expect(tile.isSelected, isFalse);
    });
  });

  group('coming back (BR-189)', () {
    testWidgets('Back from the detail screen returns to the card list', (
      tester,
    ) async {
      final router = await pumpApp(tester, cards: cardRepo());

      await tester.tap(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();
      expect(find.byType(CardDetailScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(CardListScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/decks/deck-1/cards',
      );
    });

    testWidgets('Edit pushes the editor on top, so leaving it returns to the '
        'card being read (UC-12 A1)', (tester) async {
      final router = await pumpApp(
        tester,
        cards: cardRepo(),
        initialLocation: '/decks/deck-1/cards/c0',
      );
      expect(find.byType(CardDetailScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(CardEditorScreen), findsOneWidget);

      // The editor leaves the way it leaves in production — `Navigator.pop`,
      // which is what both its Save path and its close action call. A
      // `pageBack()` would be a different gesture and would prove less.
      Navigator.of(tester.element(find.byType(CardEditorScreen))).pop();
      await tester.pumpAndSettle();

      // The editor route is a *sibling* of the detail route, not a child, so a
      // `goNamed` would have rebuilt the stack without the detail screen in it
      // and dropped the user on the list — reading, then editing, then landing
      // somewhere else.
      expect(find.byType(CardDetailScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/decks/deck-1/cards/c0',
      );
    });

    testWidgets('the search term typed before opening a card is still there '
        'afterwards', (tester) async {
      await pumpApp(tester, cards: cardRepo());

      await tester.enterText(find.byType(TextField).first, 'front');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // The detail route is pushed onto the same branch, so the list is not
      // rebuilt from scratch — which is what keeps the filter, the window and
      // the selection alive across the visit.
      expect(find.text('front'), findsWidgets);
      expect(find.byType(CardListScreen), findsOneWidget);
    });

    testWidgets('the bottom bar stays visible on the detail screen', (
      tester,
    ) async {
      await pumpApp(
        tester,
        cards: cardRepo(),
        initialLocation: '/decks/deck-1/cards/c0',
      );

      expect(find.byType(MxNavigationBar), findsOneWidget);
    });
  });
}
