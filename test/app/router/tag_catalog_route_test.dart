import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/tag_catalog_repository_provider.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/card/presentation/support/fake_card_repository.dart';
import '../../features/card/presentation/support/fake_tag_catalog_repository.dart';
import '../../features/deck/presentation/support/fake_deck_repository.dart';

/// The tag catalog route (UC-18, M4.14 T1, T2): its name, its URL, both entry
/// points, and — the part that motivated this file — the way back.
///
/// **`goNamed` from the card list was wrong and nothing caught it.** `/tags` is
/// a child of `/`, so going to it rebuilds the branch stack from the URL and
/// leaves `[deck list root, catalog]`: Back lands on the root rather than the
/// card list, and the card list's autoDispose state — the applied tag filter,
/// the selection, the grown window — dies with the screen. Every other gate was
/// green; only a route test can see a stack.
void main() {
  final english = AppLocalizationsEn();

  const deckContext = DeckContextModel(
    deckName: 'TOPIK I',
    ancestors: <DeckBreadcrumbSegment>[],
  );

  const tags = <TagCatalogEntry>[
    TagCatalogEntry(id: 't1', name: 'noun', cardCount: 3),
  ];

  FakeCardRepository cardRepo() {
    final repository = FakeCardRepository.loaded(
      <dynamic>[FakeCardRepository().listItem('c1', front: '사과')].cast(),
      total: 1,
    );
    repository
      ..holdsCards = true
      ..deckContextToShow = deckContext;

    return repository;
  }

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required FakeCardRepository cards,
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
          tagCatalogRepositoryProvider.overrideWithValue(
            FakeTagCatalogRepository.seeded(tags),
          ),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('goNamed builds /tags and mounts the catalog', (tester) async {
    final router = await pumpApp(tester, cards: cardRepo());

    router.goNamed(RouteNames.tagCatalog);
    await tester.pumpAndSettle();

    expect(find.byType(TagCatalogScreen), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/tags');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a deep link opens the catalog directly', (tester) async {
    await pumpApp(tester, cards: cardRepo(), initialLocation: '/tags');

    expect(find.byType(TagCatalogScreen), findsOneWidget);
  });

  testWidgets('it stays inside the Library branch, so the bottom bar stays', (
    tester,
  ) async {
    await pumpApp(tester, cards: cardRepo(), initialLocation: '/tags');

    // Unlike the import wizard, the catalog is a destination rather than a
    // full-screen task: it is composed *inside* the shell (M4.14 T1).
    expect(find.byType(MxNavigationBar), findsOneWidget);
  });

  testWidgets('the card list overflow opens it, and Back returns to the '
      'card list — not to the deck root (M4.14 T1)', (tester) async {
    await pumpApp(tester, cards: cardRepo());
    expect(find.byType(CardListScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.tagCatalogEntryAction).last);
    await tester.pumpAndSettle();
    expect(find.byType(TagCatalogScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // The whole point: the user came from a card list, so that is where Back
    // puts them. A `go` would have left them at the deck-list root.
    expect(find.byType(CardListScreen), findsOneWidget);
    expect(find.byType(TagCatalogScreen), findsNothing);
  });

  testWidgets('the Library overflow menu opens it from the root level', (
    tester,
  ) async {
    // The entry moved off the bar into its one overflow menu (owner mockup,
    // 2026-08-20).
    await pumpApp(tester, cards: cardRepo(), initialLocation: '/');
    expect(find.byType(DeckListScreen), findsOneWidget);

    await tester.tap(find.byTooltip(english.libraryActionsTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.tagCatalogEntryAction).last);
    await tester.pumpAndSettle();

    expect(find.byType(TagCatalogScreen), findsOneWidget);
  });

  testWidgets('selection mode hides the card list entry', (tester) async {
    await pumpApp(tester, cards: cardRepo());

    await tester.longPress(find.text('사과'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    expect(find.text(english.tagCatalogEntryAction), findsNothing);
  });
}
