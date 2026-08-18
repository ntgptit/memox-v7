import 'search_cursor_model.dart';
import 'search_result_model.dart';

/// One page of a library search: decks first, then cards, plus where the next
/// page starts (BR-251, BR-253).
///
/// **Both groups in one value, because the screen shows both at once.** Two
/// repository calls would be two snapshots, so a rename landing between them
/// would put the old deck name in the deck section and the new one in a card's
/// path on the same frame (AD-13). One read, one instant.
///
/// **A page is filled with decks first and topped up with cards.** The deck
/// group is walked to exhaustion before the first card appears, so the sections
/// never interleave and a load-more never inserts a deck below a card.
final class LibrarySearchPage {
  const LibrarySearchPage({
    required this.decks,
    required this.cards,
    required this.cursor,
  });

  /// The empty page a query with nothing in it resolves to — returned without
  /// reading anything (BR-249).
  static const LibrarySearchPage empty = LibrarySearchPage(
    decks: <DeckSearchHit>[],
    cards: <CardSearchHit>[],
    cursor: LibrarySearchCursor(
      areDecksExhausted: true,
      areCardsExhausted: true,
    ),
  );

  final List<DeckSearchHit> decks;
  final List<CardSearchHit> cards;

  /// Where the **next** page continues from, and whether there is one.
  final LibrarySearchCursor cursor;

  bool get isEmpty => decks.isEmpty && cards.isEmpty;

  bool get hasMore => !cursor.isExhausted;

  @override
  String toString() =>
      'LibrarySearchPage(decks: ${decks.length}, cards: ${cards.length}, '
      'hasMore: $hasMore)';
}
