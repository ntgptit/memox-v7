import 'search_cursor_model.dart';
import 'search_match_rank_model.dart';
import 'search_query_model.dart';
import 'search_result_model.dart';

/// The tree as search sees it: enough to match a name, order the match and name
/// the path, and nothing else.
///
/// **Not `DeckEntity`.** That type carries the scheduler columns, the generation
/// and the content-type state machine, none of which a result row can act on —
/// and taking it here would make this feature import the Deck feature's domain
/// wholesale for four fields (AD-17). The data layer maps rows into this; the
/// ranking below never sees a Drift type.
final class SearchableDeck {
  const SearchableDeck({
    required this.id,
    required this.name,
    required this.foldedName,
    required this.parentDeckId,
    required this.createdAt,
    required this.isCardDeck,
  });

  final String id;

  /// As stored — what a row renders and what a path segment shows.
  final String name;

  /// [name] through the shared fold, computed once per read rather than per
  /// comparison. Decks have no folded **column**: their names are matched in
  /// Dart, where the same `foldForSearch` the stored columns were written with
  /// is available, so no `lower()` is ever needed (BR-183).
  final String foldedName;

  final String? parentDeckId;
  final DateTime createdAt;
  final bool isCardDeck;
}

/// A deck hit together with the cursor that names its place in the order.
typedef RankedDeck = ({DeckSearchHit hit, SearchCursor cursor});

/// One page of deck matches, and whether the group has anything left.
typedef DeckPage = ({List<RankedDeck> ranked, bool isExhausted});

/// BR-55 caps a real tree at ten levels. The walk below is bounded by it so
/// corrupt cyclic data terminates instead of hanging — cycle *detection* stays
/// where it belongs, in invariant Q8.
const int _kMaxAncestorWalk = 10;

/// Every deck whose name matches [query], ordered and cut to one page (BR-185,
/// BR-186, BR-188).
///
/// **Ranked and paged in Dart rather than in SQL, and the reason is the schema.**
/// `cards.front_folded` and `tags.name_folded` exist; `decks` has no folded
/// column, so a SQL deck search would have to compare `lower(name)` — ASCII-only,
/// which is the exact asymmetry that made `CÔNG NGHỆ` unfindable and the folded
/// columns necessary in the first place (BR-183). The alternatives were adding a
/// column, which is a schema change BR-190 refuses without measurement, or
/// folding in Dart over the tree, which is what this does.
///
/// **The deck set is read whole, and it is bounded by construction.** A tree is
/// at most ten levels deep, lives on the device, and is already streamed whole
/// for the move-target picker — the same read, for the same reason recorded
/// there. It is one statement per emission, not one per row: the path of every
/// hit *and* of every card hit is derived from this one set, which is precisely
/// what stops the paths being an N+1.
///
/// [after] null starts at the beginning of the group. The returned page holds at
/// most [limit] hits; `isExhausted` is true when nothing sorts after the last of
/// them.
DeckPage rankDeckMatches({
  required List<SearchableDeck> decks,
  required SearchQuery query,
  required SearchCursor? after,
  required int limit,
}) {
  if (query.isEmpty || limit <= 0) {
    return (ranked: const <RankedDeck>[], isExhausted: true);
  }

  final Map<String, SearchableDeck> byId = <String, SearchableDeck>{
    for (final SearchableDeck deck in decks) deck.id: deck,
  };

  final List<RankedDeck> matches = <RankedDeck>[];
  for (final SearchableDeck deck in decks) {
    final SearchMatchRank? rank = SearchMatchRank.of(
      foldedCandidate: deck.foldedName,
      foldedQuery: query.folded,
    );
    if (rank == null) continue;

    matches.add((
      hit: DeckSearchHit(
        deckId: deck.id,
        name: deck.name,
        deckPath: buildDeckPath(deck.parentDeckId, byId),
        rank: rank,
        isCardDeck: deck.isCardDeck,
      ),
      cursor: SearchCursor(
        rankTier: rank.tier,
        sortKey: deck.foldedName,
        createdAt: deck.createdAt,
        id: deck.id,
      ),
    ));
  }

  matches.sort((RankedDeck a, RankedDeck b) => a.cursor.compareTo(b.cursor));

  final List<RankedDeck> afterCursor = after == null
      ? matches
      : matches
            .where((RankedDeck each) => after.isBefore(each.cursor))
            .toList(growable: false);

  // One more than the page, so "is there another page?" is answered by the same
  // read rather than by a second count that could disagree with it.
  final bool hasMore = afterCursor.length > limit;
  final List<RankedDeck> page = hasMore
      ? afterCursor.sublist(0, limit)
      : afterCursor;

  return (ranked: page, isExhausted: !hasMore);
}

/// The names from the root down to [deckId], top of the tree first.
///
/// [deckId] null returns an empty path — that is a root deck's parent, and a
/// root has nothing above it. Pass a card's deck id to get the path *including*
/// the deck the card lives in; pass a deck's parent id to get the path
/// *excluding* the deck itself.
///
/// Walking up rather than down: every deck already knows its parent, so the walk
/// is bounded by the depth cap, where a walk down would have to index the whole
/// set by parent first. A missing parent — a row whose ancestor is gone — ends
/// the walk with what was found rather than throwing: a partial path is still
/// the most useful thing that can be said about where the row is.
List<String> buildDeckPath(String? deckId, Map<String, SearchableDeck> byId) {
  final List<String> names = <String>[];
  String? current = deckId;
  for (var step = 0; step < _kMaxAncestorWalk && current != null; step++) {
    final SearchableDeck? deck = byId[current];
    if (deck == null) break;
    names.add(deck.name);
    current = deck.parentDeckId;
  }

  return names.reversed.toList(growable: false);
}
