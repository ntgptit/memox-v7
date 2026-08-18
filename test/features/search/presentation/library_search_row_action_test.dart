import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/search/domain/models/search_destination_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/states/library_search_state.dart';
import 'package:memox/features/search/presentation/widgets/items/card_result_tile_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/deck_result_tile_widget.dart';
import 'package:memox/features/search/presentation/widgets/sections/library_search_body_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'support/fake_library_search_repository.dart';

/// What a result row **reports** when it is tapped (BR-254).
///
/// **Asserted against the body widget, not the screen.** The row's whole
/// contract is the typed [SearchDestination] it hands upward; what the screen
/// then does with it is navigation, and navigation is asserted through the real
/// router in `library_search_route_test.dart`. Splitting them is what lets the
/// card path be proven wired on a build where its route does not exist yet.
void main() {
  Future<void> pumpBody(
    WidgetTester tester, {
    required LibrarySearchState state,
    required ValueChanged<SearchDestination> onOpen,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildLightTheme(),
        home: Scaffold(
          body: LibrarySearchBodyWidget(
            state: state,
            isDebouncing: false,
            onOpen: onOpen,
            onLoadMore: () {},
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  LibrarySearchState stateWith({
    List<DeckSearchHit> decks = const <DeckSearchHit>[],
    List<CardSearchHit> cards = const <CardSearchHit>[],
  }) => LibrarySearchState(
    query: SearchQuery.parse('noun'),
    decks: decks,
    cards: cards,
    phase: LibrarySearchPhase.ready,
    hasMore: false,
    isLoadingMore: false,
  );

  testWidgets('a deck row reports a deck destination', (tester) async {
    final opened = <SearchDestination>[];
    await pumpBody(
      tester,
      state: stateWith(decks: <DeckSearchHit>[fakeDeckHit(id: 'deck-9')]),
      onOpen: opened.add,
    );

    await tester.tap(find.byType(DeckResultTileWidget));
    await tester.pumpAndSettle();

    expect(opened, <SearchDestination>[
      const DeckDestination(deckId: 'deck-9'),
    ]);
  });

  testWidgets('a card row reports a card destination, never an edit route', (
    tester,
  ) async {
    // The route does not exist on this base. What must be true is that the row
    // asks for the **card**, so the day the route lands nothing in this feature
    // changes — and that it carries the deck as well, because every card route
    // in this app is nested under one.
    final opened = <SearchDestination>[];
    await pumpBody(
      tester,
      state: stateWith(
        cards: <CardSearchHit>[fakeCardHit(id: 'card-9', deckId: 'deck-9')],
      ),
      onOpen: opened.add,
    );

    await tester.tap(find.byType(CardResultTileWidget));
    await tester.pumpAndSettle();

    expect(opened, <SearchDestination>[
      const CardDestination(cardId: 'card-9', deckId: 'deck-9'),
    ]);
  });

  test('a hit maps to exactly one destination, and the map is total', () {
    // Sealed on both sides, so a third kind of hit cannot reach a row that
    // forgot it.
    expect(
      SearchDestination.of(fakeDeckHit(id: 'd')),
      const DeckDestination(deckId: 'd'),
    );
    expect(
      SearchDestination.of(fakeCardHit(id: 'c', deckId: 'd')),
      const CardDestination(cardId: 'c', deckId: 'd'),
    );
  });
}
