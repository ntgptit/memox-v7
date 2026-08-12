import '../../../../core/database/app_database.dart';

/// The minimum Deck persistence surface required by card writes.
///
/// Card creation must validate its target, resolve the root scheduler and lock
/// an `unset` deck to `card` in the same transaction as the Card insert
/// (BR-09, BR-62). Card **deletion** owns the other half of that lifecycle: it
/// puts the deck back to `unset` when it removes the last direct card
/// (BR-163), in the same transaction for the same reason. Keeping this adapter
/// inside the Card feature prevents a forbidden dependency on Deck's data
/// layer while both adapters still share the exact same [AppDatabase]
/// transaction boundary.
final class CardDeckContextDao {
  CardDeckContextDao(this._db);

  final AppDatabase _db;

  Future<Deck?> deckById(String deckId) =>
      _db.deckById(deckId).getSingleOrNull();

  /// Cards held **directly** by [deckId] — the count BR-163 reads to decide
  /// whether the deck still has a content type to keep.
  ///
  /// Called from inside the delete transaction, never before it: a count read
  /// outside sees a database another writer may change before the update
  /// lands, which is the race the whole transaction exists to prevent.
  Future<int> directCardCount(String deckId) =>
      _db.directCardCount(deckId).getSingle();

  Future<int> updateDeckById(String deckId, DecksCompanion changes) =>
      (_db.update(
        _db.decks,
      )..where((Decks deck) => deck.id.equals(deckId))).write(changes);

  /// The decks this card's deck may move into (BR-165).
  ///
  /// Watched, not read once: the picker stays open while the tree can change
  /// under it, and a target that stops being valid must leave the list rather
  /// than be refused after the tap.
  Stream<List<CardMoveTargetsResult>> watchMoveTargets({
    required String rootDeckId,
    required String sourceDeckId,
  }) => _db.cardMoveTargets(rootDeckId, sourceDeckId).watch();
}
