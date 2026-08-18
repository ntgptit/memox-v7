import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/search/presentation/widgets/items/card_result_tile_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/deck_result_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_library_search_repository.dart';
import 'support/search_screen_harness.dart';

/// Every state the search surface renders (wireframe M99.32 W3).
void main() {
  final english = AppLocalizationsEn();

  group('the states', () {
    testWidgets('nothing typed says what can be searched, and reads nothing', (
      tester,
    ) async {
      final repository = FakeLibrarySearchRepository.serving(fakeSearchPage());
      await pumpSearchScreen(tester, repository: repository);

      expect(find.text(english.librarySearchInitialTitle), findsOneWidget);
      expect(find.text(english.librarySearchInitialMessage), findsOneWidget);
      expect(
        repository.calls,
        isEmpty,
        reason: 'opening the screen is not a search (BR-249)',
      );
    });

    testWidgets('a settled query with both kinds shows both sections', (
      tester,
    ) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.serving(
          fakeSearchPage(
            decks: <DeckSearchHit>[fakeDeckHit()],
            cards: <CardSearchHit>[fakeCardHit()],
          ),
        ),
      );
      await typeSearch(tester, 'noun');

      expect(find.text(english.librarySearchDecksGroupLabel), findsOneWidget);
      expect(find.text(english.librarySearchCardsGroupLabel), findsOneWidget);
      expect(find.byType(DeckResultTileWidget), findsOneWidget);
      expect(find.byType(CardResultTileWidget), findsOneWidget);
    });

    testWidgets('decks are drawn above cards', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.serving(
          fakeSearchPage(
            decks: <DeckSearchHit>[fakeDeckHit()],
            cards: <CardSearchHit>[fakeCardHit()],
          ),
        ),
      );
      await typeSearch(tester, 'noun');

      expect(
        tester.getRect(find.byType(DeckResultTileWidget)).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byType(CardResultTileWidget)).top,
        ),
        reason: 'BR-251 is an order on screen, not only an order in the data',
      );
    });

    testWidgets('a decks-only result draws no card header', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.serving(
          fakeSearchPage(decks: <DeckSearchHit>[fakeDeckHit()]),
        ),
      );
      await typeSearch(tester, 'noun');

      expect(find.text(english.librarySearchDecksGroupLabel), findsOneWidget);
      expect(find.text(english.librarySearchCardsGroupLabel), findsNothing);
    });

    testWidgets('a cards-only result draws no deck header', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.serving(
          fakeSearchPage(cards: <CardSearchHit>[fakeCardHit()]),
        ),
      );
      await typeSearch(tester, 'noun');

      expect(find.text(english.librarySearchDecksGroupLabel), findsNothing);
      expect(find.text(english.librarySearchCardsGroupLabel), findsOneWidget);
    });

    testWidgets('a settled query that found nothing echoes what was typed', (
      tester,
    ) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.serving(fakeSearchPage()),
      );
      await typeSearch(tester, 'zebra');

      expect(
        find.text(english.librarySearchNoResultsTitle('zebra')),
        findsOneWidget,
      );
    });

    testWidgets(
      'waiting for the first page shows a spinner, not an empty state',
      (tester) async {
        // A query whose answer never arrives: the screen must not claim there are
        // no results for a search that has not finished.
        await pumpSearchScreen(
          tester,
          repository: FakeLibrarySearchRepository(
            (_, _, _) => const Stream<LibrarySearchPage>.empty(),
          ),
        );
        await tester.enterText(searchInput, 'noun');
        await tester.pump();

        expect(find.byType(MxLoadingState), findsOneWidget);
        expect(find.byType(MxEmptyState), findsNothing);
      },
    );

    testWidgets('a failed first page offers a retry and lists nothing', (
      tester,
    ) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.failing(),
      );
      await typeSearch(tester, 'noun');

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.librarySearchErrorMessage), findsOneWidget);
      expect(find.byType(DeckResultTileWidget), findsNothing);
    });

    testWidgets('a failed later page keeps the results and moves the error to '
        'the footer', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.failingAfter(
          fakeSearchPage(cards: <CardSearchHit>[fakeCardHit()], hasMore: true),
        ),
      );
      await typeSearch(tester, 'noun');

      expect(find.byType(CardResultTileWidget), findsOneWidget);
      await tester.tap(find.text(english.librarySearchLoadMoreAction));
      await tester.pumpAndSettle();

      expect(
        find.byType(CardResultTileWidget),
        findsOneWidget,
        reason: 'what was already found is still what was found',
      );
      expect(
        find.text(english.librarySearchLoadMoreErrorMessage),
        findsOneWidget,
      );
      expect(find.byType(MxErrorState), findsNothing);
    });

    testWidgets('load more appends the next page', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.paged(
          first: fakeSearchPage(
            cards: <CardSearchHit>[fakeCardHit(front: 'one')],
            hasMore: true,
          ),
          next: fakeSearchPage(
            cards: <CardSearchHit>[fakeCardHit(id: 'card-2', front: 'two')],
          ),
        ),
      );
      await typeSearch(tester, 'noun');

      await tester.tap(find.text(english.librarySearchLoadMoreAction));
      await tester.pumpAndSettle();

      expect(find.byType(CardResultTileWidget), findsNWidgets(2));
      expect(
        find.text(english.librarySearchLoadMoreAction),
        findsNothing,
        reason: 'the last page says there is nothing after it',
      );
    });

    testWidgets('clearing the field returns to the initial state', (
      tester,
    ) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.serving(
          fakeSearchPage(cards: <CardSearchHit>[fakeCardHit()]),
        ),
      );
      await typeSearch(tester, 'noun');
      expect(find.byType(CardResultTileWidget), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(english.librarySearchClearLabel));
      await tester.pumpAndSettle();

      expect(find.text(english.librarySearchInitialTitle), findsOneWidget);
      expect(find.byType(CardResultTileWidget), findsNothing);
    });
  });

  testWidgets('the screen is the one the route builds', (tester) async {
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(fakeSearchPage()),
    );

    expect(find.byType(LibrarySearchScreen), findsOneWidget);
  });
}
