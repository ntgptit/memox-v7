import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/domain/models/search_match_rank_model.dart';

/// BR-250: exact, then prefix, then contains — and nothing in between.
void main() {
  SearchMatchRank? rankOf(String candidate, String query) =>
      SearchMatchRank.of(foldedCandidate: candidate, foldedQuery: query);

  test('the three tiers are recognised', () {
    expect(rankOf('noun', 'noun'), SearchMatchRank.exact);
    expect(rankOf('nouns', 'noun'), SearchMatchRank.prefix);
    expect(rankOf('common nouns', 'noun'), SearchMatchRank.contains);
    expect(rankOf('verb', 'noun'), isNull);
  });

  test('the tiers sort in the order the design states', () {
    expect(SearchMatchRank.exact.tier, lessThan(SearchMatchRank.prefix.tier));
    expect(
      SearchMatchRank.prefix.tier,
      lessThan(SearchMatchRank.contains.tier),
    );
    expect(
      SearchMatchRank.contains.tier,
      lessThan(SearchMatchRank.noMatchTier),
      reason: 'the SQL filters on `rank_tier < noMatchTier`',
    );
    expect(
      SearchMatchRank.beforeFirstTier,
      lessThan(SearchMatchRank.exact.tier),
      reason: 'the first page uses a cursor below every real row',
    );
  });

  test('an empty query matches nothing rather than everything', () {
    // `instr(x, '')` is 1 in SQLite, so an empty needle is a *prefix* match on
    // every row. That is the whole library returned for a query the user has
    // not typed, and BR-249 says the read must not happen at all — but the
    // domain still has to refuse it rather than rely on the caller.
    expect(rankOf('anything', ''), isNull);
  });

  test('folding is the caller\'s job, and asymmetry is visible', () {
    // Deliberate: this compares, it does not normalise. A second fold here
    // would be a second rule that can disagree with the stored columns.
    expect(rankOf('CÔNG NGHỆ', 'công'), isNull);
    expect(rankOf('công nghệ', 'công'), SearchMatchRank.prefix);
  });

  test('the best of two ranks wins, and null means no match', () {
    expect(
      SearchMatchRank.best(SearchMatchRank.contains, SearchMatchRank.exact),
      SearchMatchRank.exact,
    );
    expect(
      SearchMatchRank.best(SearchMatchRank.exact, SearchMatchRank.contains),
      SearchMatchRank.exact,
    );
    expect(
      SearchMatchRank.best(null, SearchMatchRank.prefix),
      SearchMatchRank.prefix,
    );
    expect(
      SearchMatchRank.best(SearchMatchRank.prefix, null),
      SearchMatchRank.prefix,
    );
    expect(SearchMatchRank.best(null, null), isNull);
  });
}
