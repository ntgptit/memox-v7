import '../../../../core/database/app_database.dart';

/// Data access for the Deck/Card vertical.
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Reads delegate to the typed queries
/// in `queries/deck.drift`, so every piece of business SQL — the recursive
/// subtree walk included — is checked by `drift_dev` at build time (AD-02).
///
/// This class speaks Drift rows and companions. They stop here: the repository
/// maps them to domain entities and never lets one across (AD-01).
final class DeckDao {
  DeckDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically. A thrown error rolls the whole block back —
  /// multi-step writes (BR-62, BR-09, BR-71) all go through this.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- decks -------------------------------------------------------------

  Stream<List<Deck>> watchRootDecks() => _db.rootDecks().watch();

  /// One root's whole tree at any depth, via `root_deck_id` (BR-56, BR-57).
  Stream<List<Deck>> watchDecksInTree(String rootDeckId) =>
      _db.decksInTree(rootDeckId).watch();

  Stream<List<Deck>> watchChildDecks(String parentDeckId) =>
      _db.childDecks(parentDeckId).watch();

  Future<Deck?> deckById(String deckId) =>
      _db.deckById(deckId).getSingleOrNull();

  /// The deck itself plus every descendant, recursively.
  Future<List<String>> subtreeDeckIds(String deckId) =>
      _db.subtreeDeckIds(deckId).get();

  Future<int> directChildDeckCount(String deckId) =>
      _db.directChildDeckCount(deckId).getSingle();

  Future<int> directCardCount(String deckId) =>
      _db.directCardCount(deckId).getSingle();

  Future<int> subtreeCardCount(String deckId) =>
      _db.subtreeCardCount(deckId).getSingle();

  Future<void> insertDeck(DecksCompanion deck) =>
      _db.into(_db.decks).insert(deck);

  Future<int> updateDeckById(String deckId, DecksCompanion changes) =>
      (_db.update(
        _db.decks,
      )..where((Decks deck) => deck.id.equals(deckId))).write(changes);

  Future<int> deleteDeckById(String deckId) => (_db.delete(
    _db.decks,
  )..where((Decks deck) => deck.id.equals(deckId))).go();

  /// Rewrites `root_deck_id` for [deckId] and its whole subtree (BR-71).
  Future<int> updateSubtreeRootDeck({
    required String deckId,
    required String newRootDeckId,
    required DateTime updatedAt,
  }) => _db.updateSubtreeRootDeck(newRootDeckId, updatedAt, deckId);

  // ---- cards -------------------------------------------------------------

  Stream<List<Card>> watchCardsByDeck(String deckId) =>
      _db.cardsByDeck(deckId).watch();

  Future<Card?> cardById(String cardId) =>
      _db.cardById(cardId).getSingleOrNull();

  Future<CardReviewState?> reviewStateByCard(String cardId) =>
      _db.reviewStateByCard(cardId).getSingleOrNull();

  Future<void> insertCard(CardsCompanion card) =>
      _db.into(_db.cards).insert(card);

  Future<int> updateCardById(String cardId, CardsCompanion changes) =>
      (_db.update(
        _db.cards,
      )..where((Cards card) => card.id.equals(cardId))).write(changes);

  Future<int> deleteCardById(String cardId) => (_db.delete(
    _db.cards,
  )..where((Cards card) => card.id.equals(cardId))).go();

  Future<void> insertReviewState(CardReviewStatesCompanion state) =>
      _db.into(_db.cardReviewStates).insert(state);
}
