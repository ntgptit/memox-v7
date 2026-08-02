import '../../../../core/database/app_database.dart';

/// Data access for the Card side of the vertical.
///
/// Receives the same already-open [AppDatabase] instance as the Card feature's
/// deck-context adapter — one opener (AD-08), one database. Drift transactions
/// are scoped to that database, so `CardRepositoryImpl` can apply BR-09 and
/// BR-62 atomically without importing Deck's data layer.
///
/// This class speaks Drift rows and companions. They stop here: the
/// repository maps them to domain entities and never lets one across (AD-01).
final class CardDao {
  CardDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically — the card + review state + content-type lock
  /// write (BR-09, BR-62) goes through this.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- reads -------------------------------------------------------------

  /// Newest first, capped at [limit] — see `card.drift` for why both.
  Stream<List<Card>> watchCardsByDeck(String deckId, {required int limit}) =>
      _db.cardsByDeck(deckId, limit).watch();

  /// The deck's whole card count, for the "showing N of M" line.
  Stream<int> watchCardCountByDeck(String deckId) =>
      _db.cardCountByDeck(deckId).watchSingle();

  Future<Card?> cardById(String cardId) =>
      _db.cardById(cardId).getSingleOrNull();

  Future<CardReviewState?> reviewStateByCard(String cardId) =>
      _db.reviewStateByCard(cardId).getSingleOrNull();

  // ---- writes ------------------------------------------------------------

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
