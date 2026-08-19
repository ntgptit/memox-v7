import '../../../../core/database/app_database.dart';

/// Data access for Trash.
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Reads delegate to the typed queries in
/// `queries/trash.drift`, so the tombstone SQL is checked by `drift_dev` at
/// build time like everything else (AD-02).
///
/// This class speaks Drift rows and companions. They stop here.
final class TrashDao {
  TrashDao(this._db);

  final AppDatabase _db;

  /// SQLite's bind-variable ceiling is 999 by default, and a deck deletion can
  /// name more ids than that in one subtree. Every array-bound statement below
  /// is chunked at this size — the same reason `CardExportDao` has its own.
  static const int idChunkSize = 400;

  /// Passed where a statement wants "a deck to exclude" and there is none.
  ///
  /// `cardMoveTargets` excludes the deck a card is *moving from*; a restore has
  /// no such deck — the origin is a perfectly good destination (BR-262 only
  /// forbids choosing it automatically). Deck ids are UUIDs, so the empty
  /// string can never name one.
  static const String excludeNoDeck = '';

  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- reads --------------------------------------------------------------

  Stream<List<TrashBatchRowsResult>> watchBatchRows() =>
      _db.trashBatchRows().watch();

  Future<List<TrashBatchRowsResult>> batchRows() => _db.trashBatchRows().get();

  Future<DeleteBatch?> batchById(String batchId) =>
      _db.batchById(batchId).getSingleOrNull();

  Future<List<DeleteBatch>> eligibleBatches(DateTime cutoff) =>
      _db.eligibleBatches(cutoff).get();

  Future<Deck?> tombstoneDeckInBatch({
    required String deckId,
    required String batchId,
  }) => _db.tombstoneDeckInBatch(deckId, batchId).getSingleOrNull();

  Future<Card?> tombstoneCardInBatch({
    required String cardId,
    required String batchId,
  }) => _db.tombstoneCardInBatch(cardId, batchId).getSingleOrNull();

  /// A deck row whether or not it is in Trash — see the statement's comment for
  /// the single caller that needs it.
  Future<Deck?> anyDeckById(String deckId) =>
      _db.anyDeckById(deckId).getSingleOrNull();

  Future<Deck?> activeDeckById(String deckId) =>
      _db.deckById(deckId).getSingleOrNull();

  Stream<List<Deck>> watchActiveDecks() => _db.allDecks().watch();

  Stream<List<CardMoveTargetsResult>> watchCardRestoreTargets(
    String rootDeckId,
  ) => _db.cardMoveTargets(rootDeckId, excludeNoDeck).watch();

  /// The deck itself plus every **active** descendant — the set a deck deletion
  /// is about to mark (BR-258).
  Future<List<String>> activeSubtreeDeckIds(String deckId) =>
      _db.activeSubtreeDeckIds(deckId).get();

  Future<List<String>> activeCardIdsInDecks(List<String> deckIds) =>
      _collect(deckIds, (chunk) => _db.activeCardIdsInDecks(chunk).get());

  Future<List<String>> batchDeckIds(String batchId) =>
      _db.batchDeckIds(batchId).get();

  Future<List<String>> batchCardIds(String batchId) =>
      _db.batchCardIds(batchId).get();

  /// How tall the batch's own subtree is, the item root counting as 1.
  Future<int?> batchSubtreeHeightProbe({
    required String deckId,
    required String batchId,
    required int maxWalk,
  }) => _db.batchSubtreeHeightProbe(deckId, batchId, maxWalk).getSingle();

  /// How many rows a purge of [batchId] would reach that are not part of
  /// [allowedBatchIds] (BR-265). Zero means the purge is safe.
  Future<int> purgeBlockerCount({
    required String batchId,
    required List<String> allowedBatchIds,
  }) async {
    // An empty allowed set would produce `NOT IN ()`, which SQLite rejects; and
    // semantically it means "nothing may be taken", so every tombstone under
    // the batch is a blocker. Answering without the round trip keeps the
    // statement's own contract simple.
    if (allowedBatchIds.isEmpty) return 1;

    var total = 0;
    for (final chunk in _chunks(allowedBatchIds)) {
      total += await _db.purgeBlockerCount(batchId, chunk).getSingle();
    }

    return total;
  }

  Future<int> deckDepthProbe({
    required String deckId,
    required int maxWalk,
  }) async {
    final probe = await _db.deckDepthProbe(deckId, maxWalk).getSingleOrNull();
    if (probe == null || !probe.reachedRoot) return -1;

    return probe.depth;
  }

  // ---- writes -------------------------------------------------------------

  Future<void> insertBatch(DeleteBatchesCompanion batch) =>
      _db.into(_db.deleteBatches).insert(batch);

  /// Marks [deckIds] and returns how many rows actually changed.
  ///
  /// The count is the caller's proof that the ids it read are the ids it wrote:
  /// the statement refuses a row that is already a tombstone, so a short count
  /// means something went to Trash between the read and the write — and a batch
  /// short of its item root is invariant 37's violation.
  Future<int> markDecksDeleted({
    required List<String> deckIds,
    required String batchId,
    required DateTime updatedAt,
  }) => _sumChunks(
    deckIds,
    (chunk) => _db.markDecksDeleted(batchId, updatedAt, chunk),
  );

  Future<int> markCardsDeleted({
    required List<String> cardIds,
    required String batchId,
    required DateTime updatedAt,
  }) => _sumChunks(
    cardIds,
    (chunk) => _db.markCardsDeleted(batchId, updatedAt, chunk),
  );

  Future<void> restoreBatchRows({
    required String batchId,
    required DateTime updatedAt,
  }) async {
    await _db.restoreDecksInBatch(updatedAt, batchId);
    await _db.restoreCardsInBatch(updatedAt, batchId);
  }

  Future<void> purgeBatch(String batchId) => _db.purgeBatch(batchId);

  Future<int> updateDeckById(String deckId, DecksCompanion changes) =>
      (_db.update(
        _db.decks,
      )..where((Decks deck) => deck.id.equals(deckId))).write(changes);

  Future<int> updateCardById(String cardId, CardsCompanion changes) =>
      (_db.update(
        _db.cards,
      )..where((Cards card) => card.id.equals(cardId))).write(changes);

  /// Rewrites `root_deck_id` for a whole subtree, tombstones included (BR-262).
  Future<int> updateSubtreeRootDeck({
    required String deckId,
    required String newRootDeckId,
    required DateTime updatedAt,
  }) => _db.updateSubtreeRootDeck(newRootDeckId, updatedAt, deckId);

  Future<int> directChildDeckCount(String deckId) =>
      _db.directChildDeckCount(deckId).getSingle();

  Future<int> directCardCount(String deckId) =>
      _db.directCardCount(deckId).getSingle();

  // ---- chunking -----------------------------------------------------------

  Iterable<List<String>> _chunks(List<String> ids) sync* {
    for (var start = 0; start < ids.length; start += idChunkSize) {
      final end = start + idChunkSize;
      yield ids.sublist(start, end > ids.length ? ids.length : end);
    }
  }

  Future<List<String>> _collect(
    List<String> ids,
    Future<List<String>> Function(List<String> chunk) read,
  ) async {
    if (ids.isEmpty) return const <String>[];

    final all = <String>[];
    for (final chunk in _chunks(ids)) {
      all.addAll(await read(chunk));
    }

    return all;
  }

  Future<int> _sumChunks(
    List<String> ids,
    Future<int> Function(List<String> chunk) write,
  ) async {
    if (ids.isEmpty) return 0;

    var written = 0;
    for (final chunk in _chunks(ids)) {
      written += await write(chunk);
    }

    return written;
  }
}
