import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/delay_provider.dart';
import 'package:memox/features/search/di/library_search_repository_provider.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_match_rank_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/domain/repositories/library_search_repository.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// `LibrarySearchScreen` mounted whole, with the repository contract faked.
///
/// The composition check the component playgrounds cannot do: the pinned field
/// above two grouped sections, a card row's three lines beside a deck row's two,
/// and how the whole thing behaves when one long Korean front meets a
/// three-level Vietnamese path.
///
/// The debounce is replaced with an immediate scheduler — a catalog demonstrates
/// states, and making the reader wait 250ms per keystroke to see one shows the
/// timer rather than the design.
WidgetbookComponent librarySearchScreenComponent() {
  return WidgetbookComponent(
    name: 'LibrarySearchScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<SearchScenario>(
            label: 'scenario',
            options: SearchScenario.values,
            labelBuilder: (SearchScenario value) => value.label,
          );

          // Keyed by scenario so changing it rebuilds from scratch: the typed
          // query and the loaded pages belong to one scenario.
          return ProviderScope(
            key: ValueKey<Object>(scenario),
            overrides: [
              librarySearchRepositoryProvider.overrideWithValue(
                _CatalogSearchRepository(scenario),
              ),
              delaySchedulerProvider.overrideWithValue((
                Duration delay,
                void Function() action,
              ) {
                action();

                return () {};
              }),
            ],
            child: const LibrarySearchScreen(),
          );
        },
      ),
    ],
  );
}

/// The states worth looking at. Nothing typed is the screen's resting state and
/// is reached by simply not typing, so it is not a scenario of its own.
enum SearchScenario {
  mixed('decks and cards'),
  decksOnly('decks only'),
  cardsOnly('cards only'),
  longContent('long Korean and Vietnamese content'),
  paged('more results than one page'),
  empty('nothing matched'),
  error('read fails'),
  // The two held-open waiting faces (the M99.31 lesson: a face that flashes
  // for one frame is not reviewable). Both need something typed first — with
  // an empty query nothing is read at all (BR-249), so the screen shows its
  // resting face whatever the scenario. Type anything to reach `loading`;
  // for `pageStalls`, type, then tap Load more under the results.
  loading('loading (read never lands)'),
  pageStalls('loading-more holds (Load more, then it hangs)');

  const SearchScenario(this.label);

  final String label;
}

/// Enough of [LibrarySearchRepository] to drive the screen.
///
/// The page is the same whatever was typed: the catalog demonstrates states, it
/// does not simulate a database. What *is* honoured is the cursor — asking for a
/// second page returns the second page — because the load-more footer is one of
/// the states worth looking at.
class _CatalogSearchRepository implements LibrarySearchRepository {
  _CatalogSearchRepository(this.scenario);

  final SearchScenario scenario;

  @override
  Stream<LibrarySearchPage> watchSearchPage({
    required SearchQuery query,
    required LibrarySearchCursor after,
    required int pageSize,
  }) {
    if (scenario == SearchScenario.error) {
      return Stream<LibrarySearchPage>.error(
        const DatabaseFailure(message: 'catalog demo failure'),
      );
    }

    // A stream that never emits, deliberately not `Stream.empty()` — an empty
    // stream *closes*, which is a different provider state from "still
    // waiting". Same idiom as the reminder, study and card-detail catalogs:
    // the only way a reviewer can look at a waiting face is for the wait to
    // never end.
    if (scenario == SearchScenario.loading) {
      return StreamController<LibrarySearchPage>().stream;
    }

    final bool isFirstPage = after == LibrarySearchCursor.start;

    // First page lands normally (with more available); the second stays in
    // flight forever, so the inline loading-more spinner under the results
    // holds still long enough to be looked at.
    if (scenario == SearchScenario.pageStalls && !isFirstPage) {
      return StreamController<LibrarySearchPage>().stream;
    }

    return Stream<LibrarySearchPage>.value(switch (scenario) {
      SearchScenario.empty => _page(),
      SearchScenario.decksOnly => _page(decks: _decks()),
      SearchScenario.cardsOnly => _page(cards: _cards()),
      SearchScenario.longContent => _page(
        decks: <DeckSearchHit>[
          _deck(
            'long-1',
            '명사와 형용사를 모두 담은 아주 긴 이름의 덱',
            path: const <String>[
              'Tiếng Hàn cơ bản',
              '문법 정리 노트',
              'Danh từ và tính từ',
            ],
          ),
        ],
        cards: <CardSearchHit>[
          _card(
            'long-c1',
            '아주 긴 앞면 텍스트가 여기에 들어갑니다',
            'Một mặt sau rất dài để kiểm tra việc cắt chữ xuống đúng một dòng',
            tag: 'ngữ pháp',
          ),
        ],
      ),
      SearchScenario.paged =>
        isFirstPage
            ? _page(decks: _decks(), cards: _cards(), hasMore: true)
            : _page(
                cards: <CardSearchHit>[
                  _card('p2-1', 'second page', 'trang thứ hai'),
                  _card('p2-2', 'and its neighbour', 'và cái kế bên'),
                ],
              ),
      SearchScenario.pageStalls => _page(
        decks: _decks(),
        cards: _cards(),
        hasMore: true,
      ),
      SearchScenario.mixed ||
      SearchScenario.error ||
      // Unreachable: the guard above returned a held-open stream already.
      SearchScenario.loading => _page(decks: _decks(), cards: _cards()),
    });
  }

  LibrarySearchPage _page({
    List<DeckSearchHit> decks = const <DeckSearchHit>[],
    List<CardSearchHit> cards = const <CardSearchHit>[],
    bool hasMore = false,
  }) => LibrarySearchPage(
    decks: decks,
    cards: cards,
    cursor: LibrarySearchCursor(
      areDecksExhausted: true,
      areCardsExhausted: !hasMore,
      afterCard: hasMore ? SearchCursor.beforeFirst : null,
    ),
  );

  List<DeckSearchHit> _decks() => <DeckSearchHit>[
    _deck('d1', 'Nouns', rank: SearchMatchRank.exact),
    _deck(
      'd2',
      'Noun forms',
      path: const <String>['Korean'],
      isCardDeck: true,
      rank: SearchMatchRank.prefix,
    ),
  ];

  List<CardSearchHit> _cards() => <CardSearchHit>[
    _card('c1', 'noun', 'danh từ'),
    _card('c2', 'a common noun', 'một danh từ thông dụng'),
    _card('c3', 'tagged only', 'chỉ khớp qua tag', tag: 'noun'),
  ];

  DeckSearchHit _deck(
    String id,
    String name, {
    List<String> path = const <String>['Korean', 'Grammar'],
    bool isCardDeck = false,
    SearchMatchRank rank = SearchMatchRank.contains,
  }) => DeckSearchHit(
    deckId: id,
    name: name,
    deckPath: path,
    rank: rank,
    isCardDeck: isCardDeck,
  );

  CardSearchHit _card(String id, String front, String back, {String? tag}) =>
      CardSearchHit(
        cardId: id,
        deckId: 'd1',
        front: front,
        back: back,
        deckPath: const <String>['Korean', 'Grammar', 'Nouns'],
        rank: SearchMatchRank.contains,
        matchedTagName: tag,
      );
}
