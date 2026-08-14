import 'search_match_rank_model.dart';

/// Where one group's next page continues from (BR-188).
///
/// **The four fields are exactly the sort order**, in the same order: rank tier,
/// then the folded text the group is sorted by, then `created_at`, then the id.
/// That is what makes the cursor *total* — no two rows compare equal, so "every
/// row strictly after this one" names a boundary with nothing on it, and a page
/// can neither repeat a row nor step over one when a write lands between two
/// pages.
///
/// **An offset would not do.** `LIMIT … OFFSET` counts rows from the start, so
/// creating a card that sorts above the window shifts every later page by one:
/// the reader sees the last row of page 1 again at the top of page 2, and never
/// sees the row that moved past the boundary. Nothing about that is visible in a
/// test that does not write between two pages, which is why it survives.
final class SearchCursor {
  const SearchCursor({
    required this.rankTier,
    required this.sortKey,
    required this.createdAt,
    required this.id,
  });

  /// A cursor below every real row, so the first page and every later page run
  /// the same statement rather than a first-page copy that can drift from it.
  static final SearchCursor beforeFirst = SearchCursor(
    rankTier: SearchMatchRank.beforeFirstTier,
    sortKey: '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    id: '',
  );

  final int rankTier;

  /// The folded text this group orders by — a deck's folded name, a card's
  /// folded front. Folded rather than displayed, so two names that differ only
  /// in case cannot swap places between two reads.
  final String sortKey;

  final DateTime createdAt;

  /// The primary key, and the reason the order is total.
  final String id;

  /// Whether [other] sorts strictly after this cursor, under the same rule the
  /// SQL half applies.
  ///
  /// Used by the deck half, which ranks in Dart. Restated rather than shared
  /// with the SQL: the two run in different languages, and
  /// `search_pagination_test.dart` pins them to the same answer on the same
  /// data.
  bool isBefore(SearchCursor other) => compareTo(other) < 0;

  /// The total order itself, so a sort and a "strictly after" test cannot
  /// disagree — a comparator that only ever answers -1 or 1 is not a valid
  /// ordering for `List.sort`, and the bug it produces is a shuffled page rather
  /// than a crash.
  int compareTo(SearchCursor other) {
    if (rankTier != other.rankTier) return rankTier.compareTo(other.rankTier);
    final int byKey = sortKey.compareTo(other.sortKey);
    if (byKey != 0) return byKey;
    final int byCreated = createdAt.compareTo(other.createdAt);
    if (byCreated != 0) return byCreated;

    return id.compareTo(other.id);
  }

  @override
  bool operator ==(Object other) =>
      other is SearchCursor &&
      other.rankTier == rankTier &&
      other.sortKey == sortKey &&
      other.createdAt == createdAt &&
      other.id == id;

  @override
  int get hashCode => Object.hash(rankTier, sortKey, createdAt, id);

  @override
  String toString() => 'SearchCursor($rankTier, $sortKey, $createdAt, $id)';
}

/// Where a whole search continues from: one cursor per group, plus whether that
/// group has anything left.
///
/// **Two cursors, because the groups are read by two different mechanisms** —
/// decks are ranked in Dart over the tree, cards by the SQL statement — and one
/// shared cursor would have to mean two different things depending on which
/// group the last row of a page came from.
///
/// **Decks are exhausted before cards start** (BR-186). A page is filled with
/// decks first and topped up with cards only once the deck group has run out,
/// so "Decks then Cards" is a property of the paging rather than something the
/// UI re-sorts after the fact.
final class LibrarySearchCursor {
  const LibrarySearchCursor({
    this.afterDeck,
    this.afterCard,
    this.areDecksExhausted = false,
    this.areCardsExhausted = false,
  });

  /// The first page of any query.
  static const LibrarySearchCursor start = LibrarySearchCursor();

  /// Null means "from the start of the deck group".
  final SearchCursor? afterDeck;

  /// Null means "from the start of the card group".
  final SearchCursor? afterCard;

  final bool areDecksExhausted;
  final bool areCardsExhausted;

  /// Nothing left in either group — the load-more affordance is not offered.
  bool get isExhausted => areDecksExhausted && areCardsExhausted;

  @override
  bool operator ==(Object other) =>
      other is LibrarySearchCursor &&
      other.afterDeck == afterDeck &&
      other.afterCard == afterCard &&
      other.areDecksExhausted == areDecksExhausted &&
      other.areCardsExhausted == areCardsExhausted;

  @override
  int get hashCode =>
      Object.hash(afterDeck, afterCard, areDecksExhausted, areCardsExhausted);
}
