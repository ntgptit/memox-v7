import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/search_fold.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/search/domain/models/deck_search_ranking_model.dart';
import 'package:memox/features/search/domain/models/search_match_rank_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';

import 'support/search_harness.dart';

/// The two halves of one ranking rule, held to the same answers.
///
/// **Decks rank in Dart and cards rank in SQL**, because `decks` has no folded
/// column while `cards` and `tags` do (BR-248). Two implementations of BR-250 is
/// the cost of that, and this file is what stops them drifting: the same words,
/// the same tiers, the same order, proved on one real database.
void main() {
  final h = installSearchHarness();

  /// The tiers the SQL writes, read back from a query built to produce one of
  /// each. `search.drift` restates the numbers as literals because SQL cannot
  /// import an enum; this is what fails when only one side is changed.
  test('the SQL tiers are the enum tiers', () async {
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    await h.card(holder.id, 'noun', back: 'x');
    await h.card(holder.id, 'nouns', back: 'x');
    await h.card(holder.id, 'a noun', back: 'x');

    final LibrarySearchPage page = await h.page('noun');

    expect(page.cards.map((c) => c.rank.tier), <int>[
      SearchMatchRank.exact.tier,
      SearchMatchRank.prefix.tier,
      SearchMatchRank.contains.tier,
    ]);
  });

  test('a non-matching row is filtered by the sentinel, not ranked', () async {
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    await h.card(holder.id, 'unrelated', back: 'x');

    expect((await h.page('noun')).cards, isEmpty);
    expect(
      SearchMatchRank.values.map((r) => r.tier),
      everyElement(lessThan(SearchMatchRank.noMatchTier)),
      reason: 'the WHERE clause depends on every real tier being below it',
    );
  });

  test('both halves agree on the same words', () async {
    // The same three words, once as deck names and once as card fronts. If the
    // Dart comparator and the SQL CASE ever disagree, the two lists differ.
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    const words = <String>['noun', 'nouns', 'a noun'];
    for (final String word in words) {
      await h.child(word, root.id);
      await h.card(holder.id, word, back: 'x');
    }

    final LibrarySearchPage page = await h.page('noun');

    expect(
      page.decks.map((d) => d.rank).toList(),
      page.cards.map((c) => c.rank).toList(),
    );
  });

  test('the Dart comparator answers what the SQL does for one candidate', () {
    // The pure half, stated directly, so a failure names the rule rather than a
    // list of ids.
    for (final (String candidate, SearchMatchRank? expected)
        in <(String, SearchMatchRank?)>[
          ('noun', SearchMatchRank.exact),
          ('nouns', SearchMatchRank.prefix),
          ('a noun', SearchMatchRank.contains),
          ('verb', null),
        ]) {
      final DeckPage page = rankDeckMatches(
        decks: <SearchableDeck>[
          SearchableDeck(
            id: 'd',
            name: candidate,
            foldedName: foldForSearch(candidate),
            parentDeckId: null,
            createdAt: DateTime.utc(2026),
            isCardDeck: false,
          ),
        ],
        query: SearchQuery.parse('noun'),
        after: null,
        limit: 5,
      );

      expect(
        page.ranked.isEmpty ? null : page.ranked.single.hit.rank,
        expected,
        reason: 'candidate "$candidate"',
      );
    }
  });
}
