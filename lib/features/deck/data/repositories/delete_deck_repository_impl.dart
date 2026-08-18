part of 'deck_repository_impl.dart';

/// The delete half of [DeckRepositoryImpl] — same class, same library,
/// split out only so each source file stays under the size guard.
///
/// It is one responsibility rather than the last N lines: moving a deck to
/// Trash is one transaction that creates a batch, marks the active subtree,
/// closes the sessions it invalidates and hands the parent its content type
/// back (BR-256, BR-258, BR-259, BR-260). The move operation next door has
/// exactly the same shape for the same reason.
mixin _DeleteDeckOperation implements DeckRepository {
  DeckDao get _dao;
  ContentTrashRepository get _trash;

  Future<T> _guard<T>(Future<T> Function() action);
  Future<Deck> _requireDeckRow(String deckId);
  Future<void> _unsetParentIfEmptied(String parentDeckId);

  @override
  /// Moves a deck and its whole active subtree to Trash, then hands the parent
  /// its content type back if that was its last child (BR-256, BR-260).
  ///
  /// **Nothing is hard-deleted any more.** Since v8 this marks a batch: the
  /// rows stay, so the cards keep their ids, their study states, their history
  /// and their tags until the batch is purged (BR-259). What the user
  /// experiences is unchanged — the subtree leaves every active surface in the
  /// same instant (BR-257) — and what they gain is thirty days to change their
  /// mind.
  ///
  /// **The parent is read before the marking and counted after, both inside one
  /// transaction.** Before, because the row that names the parent is about to
  /// become invisible to the count; after, because the count has to describe
  /// the tree the deletion leaves behind. Split across two transactions they
  /// describe two different databases.
  ///
  /// Returns nothing, deliberately: the batch id an Undo would need belongs to
  /// the use case that offers Undo, not to every caller of delete. See
  /// `DeleteDeckUseCase`.
  Future<void> deleteDeck(String deckId) => _guard(
    () => _dao.runInTransaction(() async {
      final deck = await _requireDeckRow(deckId);
      final parentDeckId = deck.parentDeckId;
      // The batch, the descendants and the sessions they invalidate — all of
      // it inside this transaction (BR-256, BR-258, BR-259).
      await _trash.markDeckDeleted(deckId);

      if (parentDeckId == null) return;
      await _unsetParentIfEmptied(parentDeckId);
    }),
  );

  @override
  /// The same deletion, returning the batch so the caller can offer Undo
  /// (BR-256, BR-263).
  ///
  /// **One transaction path, two signatures.** `deleteDeck` above is a
  /// one-element call into this, for exactly the reason `deleteCard` is one
  /// into `deleteCards`: a second write path is a second place for the
  /// emptied-parent rule to be forgotten.
  Future<String> deleteDeckForUndo(String deckId) => _guard(
    () => _dao.runInTransaction(() async {
      final deck = await _requireDeckRow(deckId);
      final parentDeckId = deck.parentDeckId;
      final batchId = await _trash.markDeckDeleted(deckId);

      if (parentDeckId != null) {
        await _unsetParentIfEmptied(parentDeckId);
      }

      return batchId;
    }),
  );
}
