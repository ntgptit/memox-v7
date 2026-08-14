import '../../../../core/database/app_database.dart';
import '../../../../core/text/search_fold.dart';
import '../../domain/models/deck_search_ranking_model.dart';
import '../../domain/models/search_cursor_model.dart';
import '../../domain/models/search_match_rank_model.dart';
import '../../domain/models/search_result_model.dart';

/// Drift rows into the values search reasons about. Nothing above this file sees
/// a `Deck` or a `SearchCardRow` (AD-01).

/// The deck tree as the ranking sees it.
///
/// **`content_type == 'card'` collapses to one boolean here**, on purpose. The
/// row needs one glyph; the state machine — `unset` becoming `card` or `deck` on
/// first child, root decks frozen at `deck` (BR-60…BR-66, BR-163) — belongs to
/// the Deck feature, and copying it into a search result would be inheriting the
/// wrong half (AD-17).
///
/// The name is folded once per read rather than once per comparison: a library
/// of 500 decks folds 500 strings and then compares them, instead of folding the
/// same name again for every one of the three rank tests.
List<SearchableDeck> toSearchableDecks(List<Deck> rows) => <SearchableDeck>[
  for (final Deck row in rows)
    SearchableDeck(
      id: row.id,
      name: row.name,
      foldedName: foldForSearch(row.name),
      parentDeckId: row.parentDeckId,
      createdAt: row.createdAt,
      isCardDeck: row.contentType == _kCardContentType,
    ),
];

/// The `content_type` value that means "this deck holds cards" (BR-63).
///
/// A literal because `data/` reads the column and the Deck feature owns the
/// enum; importing that enum would tie this feature's mapper to Deck's domain
/// for one comparison. `search_deck_kind_test.dart` pins the string against a
/// deck the Deck repository actually created, so a rename of the value fails
/// here rather than quietly showing folder icons for every card deck.
const String _kCardContentType = 'card';

/// One card row into a hit plus the cursor that names its place.
///
/// Returns null when the row carries no rank. The statement's `WHERE
/// rank_tier < 9` makes that unreachable — `MIN` over three `CASE` expressions
/// is never NULL — but the column is typed nullable, and a row with no tier has
/// no place in a keyset order. Dropping it is the only honest answer; inventing
/// a tier would put it somewhere the next page would visit again.
({CardSearchHit hit, SearchCursor cursor})? toCardHit(
  SearchCardRow row,
  Map<String, SearchableDeck> decksById,
) {
  final int? tier = row.rankTier;
  if (tier == null) return null;
  final SearchMatchRank? rank = _rankOfTier(tier);
  if (rank == null) return null;

  return (
    hit: CardSearchHit(
      cardId: row.cardId,
      deckId: row.deckId,
      front: row.front,
      back: row.back,
      // The card's own deck is part of a card's answer to "where is this?", so
      // the path is built from the deck id rather than from its parent.
      deckPath: buildDeckPath(row.deckId, decksById),
      rank: rank,
      matchedTagName: row.matchedTag,
    ),
    cursor: SearchCursor(
      rankTier: tier,
      sortKey: row.sortKey,
      createdAt: row.createdAt,
      id: row.cardId,
    ),
  );
}

/// The enum value behind a stored tier, or null for one the domain does not
/// name.
///
/// The `switch` is over [SearchMatchRank]'s own values rather than over integer
/// literals, so adding a tier to the enum without teaching the SQL about it
/// fails here instead of ranking every row of that tier as `contains`.
SearchMatchRank? _rankOfTier(int tier) {
  for (final SearchMatchRank rank in SearchMatchRank.values) {
    if (rank.tier == tier) return rank;
  }

  return null;
}
