/// How well one piece of folded text matches a folded query (BR-250).
///
/// **Three tiers and no scoring function.** A relevance score is a number nobody
/// can predict, which makes "why is this row above that one?" unanswerable and
/// makes a paging cursor built from it unstable the moment the formula is
/// tweaked. Exact, then prefix, then contains is a rule a user can hold in their
/// head and a test can pin exactly.
///
/// [tier] is the number the SQL half sorts on. It is written out again in
/// `queries/search.drift` because SQL cannot import an enum;
/// `search_rank_parity_test.dart` holds the two to the same values, so a change
/// here that is not made there fails rather than silently re-orders every card
/// page while leaving the deck page alone.
enum SearchMatchRank {
  exact(0),
  prefix(1),
  contains(2);

  const SearchMatchRank(this.tier);

  /// Lower sorts first.
  final int tier;

  /// The tier the SQL uses for "this field does not match at all".
  ///
  /// Deliberately far above [contains] rather than `3`: it is a sentinel the
  /// `WHERE` filters on, and leaving a gap means a fourth real tier can be added
  /// without every stored comparison changing meaning.
  static const int noMatchTier = 9;

  /// The tier a cursor uses to sit **below every real row**, so the first page
  /// and every later page are the same statement (BR-253).
  static const int beforeFirstTier = -1;

  /// The rank of [foldedCandidate] against [foldedQuery], or null when it does
  /// not match at all.
  ///
  /// Both arguments must already be folded — this compares, it does not
  /// normalise, because a second fold here is a second rule that can disagree
  /// with the stored columns.
  static SearchMatchRank? of({
    required String foldedCandidate,
    required String foldedQuery,
  }) {
    if (foldedQuery.isEmpty) return null;
    if (foldedCandidate == foldedQuery) return SearchMatchRank.exact;
    final int at = foldedCandidate.indexOf(foldedQuery);
    if (at < 0) return null;

    return at == 0 ? SearchMatchRank.prefix : SearchMatchRank.contains;
  }

  /// The better (lower) of two ranks, where null means "did not match".
  ///
  /// A card matches on its front, its back or any of its tags, and its place in
  /// the list is decided by its **best** field — otherwise a card whose tag is
  /// the query exactly would rank below one that merely contains it in a
  /// sentence (BR-250).
  static SearchMatchRank? best(SearchMatchRank? a, SearchMatchRank? b) {
    if (a == null) return b;
    if (b == null) return a;

    return a.tier <= b.tier ? a : b;
  }
}
