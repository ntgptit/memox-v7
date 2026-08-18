import 'search_match_rank_model.dart';

/// The two groups a result can belong to, in the order they are shown (BR-251).
///
/// An enum rather than two booleans or a string: the group decides a section
/// header, an icon, a semantic announcement and which cursor advances, and every
/// one of those is a `switch` the compiler should be able to check.
enum SearchResultGroup { decks, cards }

/// One thing the library search found.
///
/// **Sealed, so every consumer is exhaustive.** A third kind of result — a tag
/// as its own row, a media file — would fail every `switch` at compile time
/// rather than fall through a default branch into the deck layout.
///
/// **No Drift row, no router type, no `DeckEntity`.** A hit carries the text the
/// row renders and the ids the destination needs, and nothing else. Carrying a
/// deck entity would drag the scheduler columns, the content-type state machine
/// and BR-06 into a list that renders a name and a path — AD-17's warning
/// against inheriting another feature's data shape.
sealed class LibrarySearchHit {
  const LibrarySearchHit();

  /// Stable across re-reads: a deck id or a card id. What de-duplication and
  /// widget keys use.
  String get id;

  SearchResultGroup get group;

  /// Why this row is in the list. Rendered as ordering, never as a number on
  /// screen.
  SearchMatchRank get rank;

  /// The deck path, top of the tree first.
  ///
  /// **A deck hit's path excludes the deck itself; a card hit's includes the
  /// deck it lives in.** Both answer the same question — "where is this?" — and
  /// for a card the holding deck is part of the answer, while for a deck it is
  /// the row's own title one line below.
  List<String> get deckPath;
}

/// A deck whose name matched (BR-247).
final class DeckSearchHit extends LibrarySearchHit {
  const DeckSearchHit({
    required this.deckId,
    required this.name,
    required this.deckPath,
    required this.rank,
    required this.isCardDeck,
  });

  final String deckId;

  /// As stored, not folded — the folded form is a comparison key and would show
  /// the user a name they never typed.
  final String name;

  /// Whether this deck holds cards rather than sub-decks, which is the only
  /// thing the row needs to know about `content_type` — it decides one glyph.
  /// The full state machine stays in the Deck feature (AD-17).
  final bool isCardDeck;

  @override
  final List<String> deckPath;

  @override
  final SearchMatchRank rank;

  @override
  String get id => deckId;

  @override
  SearchResultGroup get group => SearchResultGroup.decks;

  @override
  bool operator ==(Object other) =>
      other is DeckSearchHit &&
      other.deckId == deckId &&
      other.name == name &&
      other.isCardDeck == isCardDeck &&
      other.rank == rank &&
      _sameStrings(other.deckPath, deckPath);

  @override
  int get hashCode =>
      Object.hash(deckId, name, isCardDeck, rank, Object.hashAll(deckPath));

  @override
  String toString() => 'DeckSearchHit($deckId, $name, ${rank.name})';
}

/// A card whose front, back or one of whose tags matched (BR-247, BR-252).
final class CardSearchHit extends LibrarySearchHit {
  const CardSearchHit({
    required this.cardId,
    required this.deckId,
    required this.front,
    required this.back,
    required this.deckPath,
    required this.rank,
    this.matchedTagName,
  });

  final String cardId;

  /// The deck the card lives in — the destination's second half, and what makes
  /// a card openable without a second read.
  final String deckId;

  final String front;

  /// The whole stored back. The row shows one line of it; the full text stays
  /// here so the semantic label can carry what the ellipsis cut.
  final String back;

  /// The best-ranked tag that matched, or null when the card matched on its own
  /// text.
  ///
  /// **It exists so a tag-only match is explicable.** Without it a card whose
  /// front and back contain nothing the user typed appears in the list with no
  /// visible reason, which reads as a bug in the search rather than as a tag
  /// doing its job.
  final String? matchedTagName;

  @override
  final List<String> deckPath;

  @override
  final SearchMatchRank rank;

  @override
  String get id => cardId;

  @override
  SearchResultGroup get group => SearchResultGroup.cards;

  @override
  bool operator ==(Object other) =>
      other is CardSearchHit &&
      other.cardId == cardId &&
      other.deckId == deckId &&
      other.front == front &&
      other.back == back &&
      other.matchedTagName == matchedTagName &&
      other.rank == rank &&
      _sameStrings(other.deckPath, deckPath);

  @override
  int get hashCode => Object.hash(
    cardId,
    deckId,
    front,
    back,
    matchedTagName,
    rank,
    Object.hashAll(deckPath),
  );

  @override
  String toString() => 'CardSearchHit($cardId, $front, ${rank.name})';
}

bool _sameStrings(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}
