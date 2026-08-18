import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/delay_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/search/di/library_search_repository_provider.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/search/presentation/widgets/items/deck_result_tile_widget.dart';
import 'package:memox/features/card/di/card_detail_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/search/presentation/widgets/items/card_result_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../card/presentation/support/fake_card_detail_repository.dart';
import '../../card/presentation/support/fake_card_repository.dart';
import '../../deck/presentation/support/fake_deck_repository.dart';
import 'support/fake_library_search_repository.dart';
import 'support/search_screen_harness.dart';

/// The route, through the real router and the real shell.
///
/// **The Library header and the search screen are two features**, and the route
/// name in `core/` is the whole of the coupling between them (AD-13). Nothing
/// but a real route table can show that the two halves actually meet.
void main() {
  final english = AppLocalizationsEn();

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required FakeLibrarySearchRepository search,
    String? initialLocation,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final GoRouter router = initialLocation == null
        ? createAppRouter()
        : createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);
    final FakeCardRepository cardRepository = FakeCardRepository();
    addTearDown(cardRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(
            FakeDeckRepository.withSummaries(<DeckSummary>[
              fakeSummary(id: 'deck-1', name: 'Japanese N5'),
            ]),
          ),
          librarySearchRepositoryProvider.overrideWithValue(search),
          cardRepositoryProvider.overrideWithValue(cardRepository),
          cardDetailRepositoryProvider.overrideWithValue(
            FakeCardDetailRepository()
              ..seededDetail = fakeCardDetail(front: 'noun')
              ..pages.add(CardHistoryPageModel.empty),
          ),
          delaySchedulerProvider.overrideWithValue(immediateScheduler),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('the Library header opens the search surface', (tester) async {
    final GoRouter router = await pumpApp(
      tester,
      search: FakeLibrarySearchRepository.serving(fakeSearchPage()),
    );

    expect(
      find.byType(MxSearchField),
      findsNothing,
      reason: 'the level itself no longer carries an input',
    );

    await tester.tap(find.bySemanticsLabel(english.librarySearchOpenLabel));
    await tester.pumpAndSettle();

    expect(find.byType(LibrarySearchScreen), findsOneWidget);
    expect(find.byType(MxSearchField), findsOneWidget);
    expect(
      router.state.uri.path,
      '/search',
      reason: 'a search is a location, so it can be deep-linked and restored',
    );
  });

  testWidgets('the search surface keeps the bottom bar', (tester) async {
    await pumpApp(
      tester,
      search: FakeLibrarySearchRepository.serving(fakeSearchPage()),
    );
    await tester.tap(find.bySemanticsLabel(english.librarySearchOpenLabel));
    await tester.pumpAndSettle();

    expect(
      find.byType(MxNavigationBar),
      findsOneWidget,
      reason: 'search is a child of the Library branch, not a screen over it',
    );
  });

  testWidgets('Back returns to the level the search was opened from', (
    tester,
  ) async {
    await pumpApp(
      tester,
      search: FakeLibrarySearchRepository.serving(fakeSearchPage()),
    );
    await tester.tap(find.bySemanticsLabel(english.librarySearchOpenLabel));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LibrarySearchScreen), findsNothing);
    expect(find.byType(DeckListScreen), findsOneWidget);
  });

  testWidgets('Back returns to the deck the search was opened from, not the '
      'root', (tester) async {
    // The bug this closes: search is a *sibling* of the deck-detail route under
    // `/`, so `go('/search')` rebuilt the branch's match list as `[/, /search]`
    // and threw away every level below the root. Back then landed on the root
    // list from a search opened three decks deep — and the test above could not
    // see it, because it opens the search from the root, where the wrong
    // behaviour and the right one look identical.
    final GoRouter router = await pumpApp(
      tester,
      search: FakeLibrarySearchRepository.serving(fakeSearchPage()),
      initialLocation: '/decks/deck-1',
    );
    expect(router.state.uri.path, '/decks/deck-1');

    await tester.tap(find.bySemanticsLabel(english.librarySearchOpenLabel));
    await tester.pumpAndSettle();
    expect(find.byType(LibrarySearchScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      router.state.uri.path,
      '/decks/deck-1',
      reason: 'the stack the user built survives a visit to search',
    );
  });

  testWidgets('the field takes focus the moment the screen opens', (
    tester,
  ) async {
    await pumpApp(
      tester,
      search: FakeLibrarySearchRepository.serving(fakeSearchPage()),
    );
    await tester.tap(find.bySemanticsLabel(english.librarySearchOpenLabel));
    await tester.pumpAndSettle();

    final TextField field = tester.widget<TextField>(find.byType(TextField));

    expect(
      field.focusNode?.hasFocus,
      isTrue,
      reason: 'the tap that opened the screen was the request to type',
    );
  });

  testWidgets('opening a deck result leaves search for that deck', (
    tester,
  ) async {
    final GoRouter router = await pumpApp(
      tester,
      search: FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          decks: <DeckSearchHit>[
            fakeDeckHit(id: 'deck-9', name: 'Japanese N5'),
          ],
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel(english.librarySearchOpenLabel));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'japanese');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DeckResultTileWidget));
    await tester.pumpAndSettle();

    expect(
      router.state.uri.path,
      '/decks/deck-9',
      reason: 'a deck result opens the deck, never an editor',
    );
  });

  testWidgets('opening a card result opens the read-only card detail', (
    tester,
  ) async {
    final GoRouter router = await pumpApp(
      tester,
      search: FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          cards: <CardSearchHit>[fakeCardHit(id: 'card-7', deckId: 'deck-9')],
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel(english.librarySearchOpenLabel));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'noun');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CardResultTileWidget));
    await tester.pumpAndSettle();

    expect(
      router.state.uri.path,
      '/decks/deck-9/cards/card-7',
      reason:
          'a card result opens the reading surface, never the editor '
          '(BR-254)',
    );
  });
}
