import '../../../../core/database/app_database.dart';

/// The minimum Deck persistence surface required by `createCard`.
///
/// Card creation must validate its target, resolve the root scheduler and lock
/// an `unset` deck to `card` in the same transaction as the Card insert
/// (BR-09, BR-62). Keeping this adapter inside the Card feature prevents a
/// forbidden dependency on Deck's data layer while both adapters still share
/// the exact same [AppDatabase] transaction boundary.
final class CardDeckContextDao {
  CardDeckContextDao(this._db);

  final AppDatabase _db;

  Future<Deck?> deckById(String deckId) =>
      _db.deckById(deckId).getSingleOrNull();

  Future<int> updateDeckById(String deckId, DecksCompanion changes) =>
      (_db.update(
        _db.decks,
      )..where((Decks deck) => deck.id.equals(deckId))).write(changes);
}
