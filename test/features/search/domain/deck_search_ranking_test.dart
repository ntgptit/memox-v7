import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/search_fold.dart';
import 'package:memox/features/search/domain/models/deck_search_ranking_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_match_rank_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';

/// The deck half of the search: matching, ranking, ties, paths and cursors.
///
/// Pure, so every rule below is asserted without a database. The SQL half is
/// held to the same answers on real SQLite in
/// `test/features/search/data/search_pagination_test.dart`.
void main() {
  final DateTime base = DateTime.utc(2026);

  SearchableDeck deck(
    String id,
    String name, {
    String? parent,
    int minutes = 0,
    bool isCardDeck = false,
  }) => SearchableDeck(
    id: id,
    name: name,
    foldedName: foldForSearch(name),
    parentDeckId: parent,
    createdAt: base.add(Duration(minutes: minutes)),
    isCardDeck: isCardDeck,
  );

  DeckPage rank(
    List<SearchableDeck> decks,
    String query, {
    SearchCursor? after,
    int limit = 20,
  }) => rankDeckMatches(
    decks: decks,
    query: SearchQuery.parse(query),
    after: after,
    limit: limit,
  );

  test('exact beats prefix beats contains', () {
    final page = rank(<SearchableDeck>[
      deck('c', 'common nouns'),
      deck('p', 'nouns'),
      deck('e', 'noun'),
    ], 'noun');

    expect(page.ranked.map((r) => r.hit.deckId), <String>['e', 'p', 'c']);
    expect(page.ranked.map((r) => r.hit.rank), <SearchMatchRank>[
      SearchMatchRank.exact,
      SearchMatchRank.prefix,
      SearchMatchRank.contains,
    ]);
  });

  test('a tie inside one tier breaks by folded name, then created_at, then id', () {
    // Three decks that all merely contain the term, so the tier cannot separate
    // them. Without the chain the order would be whatever `allDecks` returned,
    // which is a different order on a different device — and a cursor built on
    // it would skip or repeat rows.
    final page = rank(<SearchableDeck>[
      deck('z', 'Beta noun', minutes: 5),
      deck('a', 'Beta noun', minutes: 5),
      deck('m', 'alpha noun', minutes: 9),
      deck('n', 'Beta noun', minutes: 1),
    ], 'noun');

    expect(page.ranked.map((r) => r.hit.deckId), <String>['m', 'n', 'a', 'z']);
  });

  test('case does not decide the order — the folded name does', () {
    // Sorting by the displayed name puts every capitalised deck above every
    // lowercase one, because `B` < `a` in code-unit order. The stored columns
    // are folded, so the deck half sorts on the folded name too or the two
    // groups disagree about what "alphabetical" means.
    final page = rank(<SearchableDeck>[
      deck('b', 'beta noun'),
      deck('a', 'Alpha noun'),
    ], 'noun');

    expect(page.ranked.map((r) => r.hit.deckId), <String>['a', 'b']);
  });

  test('the path names every ancestor, root first, and excludes the deck', () {
    final decks = <SearchableDeck>[
      deck('root', 'Korean'),
      deck('mid', 'Nouns', parent: 'root'),
      deck('leaf', 'Food nouns', parent: 'mid', isCardDeck: true),
    ];

    final page = rank(decks, 'food');

    expect(page.ranked.single.hit.deckPath, <String>['Korean', 'Nouns']);
    expect(page.ranked.single.hit.isCardDeck, isTrue);
  });

  test('a root deck has no path', () {
    expect(
      rank(<SearchableDeck>[
        deck('root', 'Korean'),
      ], 'korean').ranked.single.hit.deckPath,
      isEmpty,
    );
  });

  test('a broken chain yields the part of the path that is intact', () {
    // A parent pointer to a row that is not in the set. Throwing would take the
    // whole search down for one corrupt row; a partial path is still the most
    // useful thing that can be said about where the deck is.
    final page = rank(<SearchableDeck>[
      deck('leaf', 'Nouns', parent: 'gone'),
    ], 'noun');

    expect(page.ranked.single.hit.deckPath, isEmpty);
  });

  test('a cycle terminates instead of hanging', () {
    // BR-55 caps a real tree at ten levels; this is the corrupt case the bound
    // exists for.
    final page = rank(<SearchableDeck>[
      deck('a', 'Noun a', parent: 'b'),
      deck('b', 'Noun b', parent: 'a'),
    ], 'noun');

    expect(page.ranked, hasLength(2));
    expect(page.ranked.first.hit.deckPath.length, lessThanOrEqualTo(10));
  });

  group('paging', () {
    final decks = <SearchableDeck>[
      for (var i = 0; i < 5; i++) deck('d$i', 'noun $i', minutes: i),
    ];

    test('a full page reports that more exists; a short one does not', () {
      expect(rank(decks, 'noun', limit: 2).isExhausted, isFalse);
      expect(rank(decks, 'noun', limit: 5).isExhausted, isTrue);
      expect(rank(decks, 'noun', limit: 9).isExhausted, isTrue);
    });

    test('two pages cover every row exactly once', () {
      final first = rank(decks, 'noun', limit: 2);
      final second = rank(
        decks,
        'noun',
        after: first.ranked.last.cursor,
        limit: 2,
      );
      final third = rank(
        decks,
        'noun',
        after: second.ranked.last.cursor,
        limit: 2,
      );

      final ids = <String>[
        for (final page in <DeckPage>[first, second, third])
          for (final RankedDeck each in page.ranked) each.hit.deckId,
      ];
      expect(ids, <String>['d0', 'd1', 'd2', 'd3', 'd4']);
      expect(ids.toSet(), hasLength(ids.length), reason: 'no row is repeated');
      expect(third.isExhausted, isTrue);
    });

    test('a row inserted above the cursor neither duplicates nor hides one', () {
      // The offset failure, made concrete: with `LIMIT … OFFSET` a row created
      // above the window shifts everything after it by one, so the last row of
      // page 1 reappears at the top of page 2 and one row is never seen at all.
      final first = rank(decks, 'noun', limit: 2);
      final grown = <SearchableDeck>[
        ...decks,
        deck('new', 'noun aaa', minutes: -1),
      ];

      final second = rank(
        grown,
        'noun',
        after: first.ranked.last.cursor,
        limit: 2,
      );

      expect(
        second.ranked.map((r) => r.hit.deckId),
        <String>['d2', 'd3'],
        reason:
            'the boundary is the last row seen, not a count of rows before it',
      );
    });

    test('a zero or negative limit asks for nothing and says so', () {
      expect(rank(decks, 'noun', limit: 0).ranked, isEmpty);
      expect(rank(decks, 'noun', limit: 0).isExhausted, isTrue);
    });
  });

  test('an empty query matches nothing and reports the group finished', () {
    final page = rank(<SearchableDeck>[deck('a', 'Korean')], '   ');

    expect(page.ranked, isEmpty);
    expect(page.isExhausted, isTrue);
  });

  test('the cursor order is total and consistent with itself', () {
    final a = SearchCursor(rankTier: 0, sortKey: 'a', createdAt: base, id: '1');
    final b = SearchCursor(rankTier: 0, sortKey: 'a', createdAt: base, id: '2');

    expect(a.isBefore(b), isTrue);
    expect(b.isBefore(a), isFalse);
    expect(
      a.compareTo(a),
      0,
      reason: 'a comparator that never answers 0 is not an order',
    );
    expect(SearchCursor.beforeFirst.isBefore(a), isTrue);
  });
}
