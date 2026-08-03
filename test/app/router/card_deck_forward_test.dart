import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';

import '../../features/card/presentation/support/fake_card_repository.dart';
import '../../features/deck/presentation/support/fake_deck_repository.dart';

/// The auto-forward: a `card`-type deck's detail route redirects into its card
/// list (BR-63, W1), and a `deck`-type one does not.
void main() {
  /// A deck repository that serves one deck at the deck level, so that when the
  /// forward does *not* fire the deck screen has something to render.
  FakeDeckRepository servingDeck() => FakeDeckRepository(
    deckList: (String? id) => Stream<DeckListSnapshot>.value(
      id == null
          ? const DeckListSnapshot(
              ancestors: <DeckPathSegment>[],
              parent: null,
              decks: <DeckSummary>[],
              nextDueAt: null,
            )
          : DeckListSnapshot(
              ancestors: const <DeckPathSegment>[],
              parent: fakeRootDeck(id: id, name: 'Japanese N5'),
              decks: const <DeckSummary>[],
              nextDueAt: null,
            ),
    ),
  );

  /// A card repository already loaded, so the card list settles instead of
  /// spinning forever once the forward lands on it. [holdsCards] drives the
  /// redirect's one answer.
  FakeCardRepository cardRepo({required bool holdsCards}) {
    final repository = FakeCardRepository.loaded(
      <dynamic>[FakeCardRepository().listItem('c1', front: 'ichi')].cast(),
      total: 1,
    );
    repository.holdsCards = holdsCards;

    return repository;
  }

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required bool holdsCards,
  }) async {
    final router = createAppRouter(initialLocation: '/decks/deck-1');
    addTearDown(router.dispose);
    final cards = cardRepo(holdsCards: holdsCards);
    addTearDown(cards.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(servingDeck()),
          cardRepositoryProvider.overrideWithValue(cards),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('entering a card-type deck forwards into its card list', (
    tester,
  ) async {
    final router = await pumpApp(tester, holdsCards: true);

    // The card list is on screen for this deck, and the deck level is not.
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is CardListScreen && w.deckId == 'deck-1',
      ),
      findsOneWidget,
    );
    expect(find.byType(DeckListScreen), findsNothing);
    // The URL carries the forward, so a reload lands on the cards too.
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/decks/deck-1/cards',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('entering a deck-type deck stays on the deck screen', (
    tester,
  ) async {
    final router = await pumpApp(tester, holdsCards: false);

    expect(find.byType(DeckListScreen), findsOneWidget);
    expect(find.byType(CardListScreen), findsNothing);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/decks/deck-1',
    );
    expect(tester.takeException(), isNull);
  });
}
