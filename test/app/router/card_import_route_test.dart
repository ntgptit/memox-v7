import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/card/di/card_import_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../../features/card/presentation/support/fake_card_repository.dart';
import '../../features/card/presentation/support/fake_card_transfer_repositories.dart';
import '../../features/deck/presentation/support/fake_deck_repository.dart';

/// The import route (UC-10, M4.12 W6): its name, its URL, the entry points
/// that reach it, and the way back.
void main() {
  final english = AppLocalizationsEn();

  const deckContext = DeckContextModel(
    deckName: 'TOPIK I',
    ancestors: <DeckBreadcrumbSegment>[],
  );

  FakeCardRepository cardRepo({int cards = 1}) {
    final repository = cards == 0
        ? (FakeCardRepository.loaded(const [], total: 0))
        : FakeCardRepository.loaded(
            <dynamic>[FakeCardRepository().listItem('c1', front: '사과')].cast(),
            total: cards,
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
          cardTransferRepositoryProvider.overrideWithValue(
            FakeCardTransferRepository(),
          ),
          cardImportSourceRepositoryProvider.overrideWithValue(
            FakeCardImportSourceRepository(),
          ),
          cardImportRepositoryProvider.overrideWithValue(
            FakeCardImportCommitRepository(),
          ),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('goNamed builds the URL and mounts the wizard', (tester) async {
    final router = await pumpApp(tester, cards: cardRepo());

    router.goNamed(
      RouteNames.cardImport,
      pathParameters: <String, String>{RoutePathParams.deckId: 'deck-1'},
    );
    await tester.pumpAndSettle();

    expect(find.byType(CardImportScreen), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/decks/deck-1/cards/import',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a deep link opens the wizard directly', (tester) async {
    await pumpApp(
      tester,
      cards: cardRepo(),
      initialLocation: '/decks/deck-1/cards/import',
    );

    expect(find.byType(CardImportScreen), findsOneWidget);
  });

  testWidgets('the card list overflow menu is the entry point, and the '
      'wizard leads back to the list', (tester) async {
    await pumpApp(tester, cards: cardRepo());
    expect(find.byType(CardListScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportEntryAction).last);
    await tester.pumpAndSettle();

    expect(find.byType(CardImportScreen), findsOneWidget);

    // Close with no draft leaves immediately (W5), onto the same list —
    // whose stream is the thing that shows imported cards, no reload.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(CardListScreen), findsOneWidget);
    expect(find.byType(CardImportScreen), findsNothing);
  });

  testWidgets('the empty card list offers Import cards too', (tester) async {
    await pumpApp(tester, cards: cardRepo(cards: 0));

    await tester.tap(find.text(english.cardImportEntryAction).last);
    await tester.pumpAndSettle();

    expect(find.byType(CardImportScreen), findsOneWidget);
  });

  testWidgets('selection mode hides the import entry', (tester) async {
    await pumpApp(tester, cards: cardRepo());

    await tester.longPress(find.text('사과'));
    await tester.pumpAndSettle();

    // The overflow that remains belongs to the selection bar; the app-bar
    // overflow with the import entry is gone until selection ends.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();

    expect(find.text(english.cardImportEntryAction), findsNothing);
  });

  testWidgets('a missing deck id segment renders the 404 screen, not a '
      'crash', (tester) async {
    await pumpApp(
      tester,
      cards: cardRepo(),
      initialLocation: '/decks//cards/import',
    );

    expect(find.byType(CardImportScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
