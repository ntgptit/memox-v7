part of 'trash_repository_impl.dart';

/// The restore half of [TrashRepositoryImpl] — same class, same library, split
/// out only so each source file stays under the size guard.
///
/// **Restore is a move, and it calls the move's rule function to prove it**
/// (BR-187). What is not shared is the *loading*: a move reads a live source
/// from SQLite, a restore reads a tombstone and measures its height over the
/// batch's own rows. That split is the same one `deckMoveRejection` was written
/// for.
mixin _TrashRestoreOperations implements TrashRepository {
  TrashDao get _dao;
  DateTime Function() get _clock;

  Future<T> _guard<T>(Future<T> Function() action);

  @override
  Future<void> restore({
    required String batchId,
    required TrashRestoreTarget target,
  }) => _guard(
    () => _dao.runInTransaction(() => _restoreInto(batchId, target: target)),
  );

  @override
  Future<void> undo(String batchId) => _guard(
    () => _dao.runInTransaction(() async {
      // **The origin is not stored anywhere special.** A tombstone keeps its
      // `parent_deck_id` / `deck_id`, so "where it was" is simply where it
      // still points — which is also why Undo needs no column of its own and
      // cannot drift from what a restore would read.
      // Reading the target first is also what proves the batch is still there,
      // so a `NotFoundFailure` from the restore below can only be about the
      // *origin* — the deck the item came from having gone to Trash itself.
      final target = await _undoTargetFor(batchId);
      try {
        await _restoreInto(batchId, target: target);
      } on ConflictFailure catch (error) {
        throw _undoRefusal(error);
      } on NotFoundFailure catch (error) {
        // The old deck is gone, which is the commonest way Undo stops being
        // possible: delete a card, then delete the deck it was in.
        throw _undoRefusal(error);
      }
    }),
  );

  /// One reason for every way Undo can be refused (BR-189).
  ///
  /// **The user chose nothing here**, so every refusal reads the same way to
  /// them: the old place will not take it back. One reason, and copy that
  /// points at Trash rather than at a picker they never opened — a target
  /// rejection they never saw would be an explanation of a choice they did not
  /// make.
  ConflictFailure _undoRefusal(Failure cause) => ConflictFailure(
    message: 'Refused: the original location no longer qualifies.',
    reason: TrashConflictReason.undoOriginUnavailable,
    cause: cause,
  );

  /// The one write path both [restore] and [undo] go through.
  Future<void> _restoreInto(
    String batchId, {
    required TrashRestoreTarget target,
  }) async {
    final batch = await _dao.batchById(batchId);
    if (batch == null) {
      throw const NotFoundFailure(message: 'That item is no longer in Trash.');
    }

    final itemType = TrashItemType.fromDbValue(batch.itemType);
    if (itemType == null) {
      throw const ConflictFailure(
        message: 'Refused: stored item_type is not a value this build knows.',
        reason: TrashConflictReason.unknownItemType,
      );
    }

    final now = _clock();
    if (itemType == TrashItemType.card) {
      await _restoreCard(batch, target: target, now: now);
    } else {
      await _restoreDeck(batch, target: target, now: now);
    }

    // The batch's rows are all active again, so the batch row owns nothing.
    // Leaving it would fail invariant 33 and put an empty entry in Trash.
    //
    // Safe *after* the clearing and only after it: this is a `DELETE` on a
    // table two `ON DELETE CASCADE`s point at, so with the rows still carrying
    // the id it would take them with it.
    await _dao.purgeBatch(batchId);
  }

  Future<void> _restoreCard(
    DeleteBatch batch, {
    required TrashRestoreTarget target,
    required DateTime now,
  }) async {
    final card = await _dao.tombstoneCardInBatch(
      cardId: batch.rootItemId,
      batchId: batch.id,
    );
    if (card == null) {
      throw const NotFoundFailure(message: 'That card is no longer in Trash.');
    }

    final targetDeckId = target.deckId;
    if (target is! TrashDeckTarget || targetDeckId == null) {
      // The top level holds decks, never cards (BR-58).
      throw const ConflictFailure(
        message: 'Refused: a card cannot be restored to the top level.',
        reason: TrashConflictReason.targetLevelMismatch,
      );
    }

    final targetDeck = await _dao.activeDeckById(targetDeckId);
    if (targetDeck == null) {
      throw const NotFoundFailure(message: 'That deck no longer exists.');
    }

    // BR-165's three conditions, re-read inside the transaction. The origin
    // deck may itself be a tombstone, so the tree it belongs to comes from a
    // read that can see one.
    final originDeck = await _dao.anyDeckById(card.deckId);
    final targetType = DeckContentType.fromDbValue(targetDeck.contentType);
    final isEligible =
        originDeck != null &&
        targetDeck.parentDeckId != null &&
        targetDeck.rootDeckId == originDeck.rootDeckId &&
        (targetType == DeckContentType.card ||
            targetType == DeckContentType.unset);
    if (!isEligible) {
      throw const ConflictFailure(
        message: 'Refused: that deck cannot hold this card.',
        reason: TrashConflictReason.targetNoLongerValid,
      );
    }

    await _dao.restoreBatchRows(batchId: batch.id, updatedAt: now);
    await _dao.updateCardById(
      card.id,
      CardsCompanion(
        deckId: Value<String>(targetDeck.id),
        updatedAt: Value<DateTime>(now),
      ),
    );
    // The target gains its first card, in the same step (BR-62, BR-187).
    if (targetType == DeckContentType.unset) {
      await _dao.updateDeckById(
        targetDeck.id,
        DecksCompanion(
          contentType: Value<String>(DeckContentType.card.dbValue),
          updatedAt: Value<DateTime>(now),
        ),
      );
    }
  }

  Future<void> _restoreDeck(
    DeleteBatch batch, {
    required TrashRestoreTarget target,
    required DateTime now,
  }) async {
    final deck = await _dao.tombstoneDeckInBatch(
      deckId: batch.rootItemId,
      batchId: batch.id,
    );
    if (deck == null) {
      throw const NotFoundFailure(message: 'That deck is no longer in Trash.');
    }

    final height = await _dao.batchSubtreeHeightProbe(
      deckId: deck.id,
      batchId: batch.id,
      maxWalk: DeckEntity.maxTreeDepth + 1,
    );
    if (height == null || height > DeckEntity.maxTreeDepth) {
      throw const ConflictFailure(
        message: 'Refused: the batch height probe hit its walk bound.',
        reason: TrashConflictReason.batchHeightUnknowable,
      );
    }

    if (deck.parentDeckId == null) {
      await _restoreRootDeck(batch, target: target, now: now);

      return;
    }

    final targetDeckId = target.deckId;
    if (target is! TrashDeckTarget || targetDeckId == null) {
      // Only a root may land at the top level; promoting a sub-deck would need
      // a scheduler of its own, which is a decision and not a restore (UC-09
      // A2).
      throw const ConflictFailure(
        message: 'Refused: only a top-level deck restores to the top level.',
        reason: TrashConflictReason.targetLevelMismatch,
      );
    }

    final targetRow = await _dao.activeDeckById(targetDeckId);
    if (targetRow == null) {
      throw const NotFoundFailure(message: 'That deck no longer exists.');
    }

    final sourceRootRow = await _dao.anyDeckById(deck.rootDeckId);
    final targetRootRow = await _dao.activeDeckById(targetRow.rootDeckId);
    final targetDepth = await _dao.deckDepthProbe(
      deckId: targetRow.id,
      maxWalk: DeckEntity.maxTreeDepth + 1,
    );
    if (targetRootRow == null || targetDepth < 1) {
      throw const ConflictFailure(
        message: 'Refused: the target tree could not be resolved.',
        reason: TrashConflictReason.targetNoLongerValid,
      );
    }

    final source = trashDeckEntityFromRow(deck);
    final rejection = deckMoveRejection(
      source: source,
      target: trashDeckEntityFromRow(targetRow),
      // No active deck can sit inside a deleted subtree (invariant 32), and
      // the target was just read as active.
      isTargetInSourceSubtree: false,
      sourceRootScheduler: sourceRootRow == null
          ? null
          : trashDeckEntityFromRow(sourceRootRow).schedulerType,
      sourceRootGeneration: sourceRootRow?.schedulerGeneration,
      targetRootScheduler: trashDeckEntityFromRow(targetRootRow).schedulerType,
      targetRootGeneration: targetRootRow.schedulerGeneration,
      targetDepth: targetDepth,
      sourceSubtreeHeight: height,
    );
    // `alreadyParent` is a no-op guard for a move and the normal case for a
    // restore: putting the subtree back where it came from is exactly what
    // Undo does. Every other rejection stands, with its own reason.
    if (rejection != null && rejection != DeckMoveRejection.alreadyParent) {
      throw ConflictFailure(
        message: 'The restore was refused by UC-09 rule ${rejection.name}.',
        reason: rejection,
      );
    }

    await _dao.restoreBatchRows(batchId: batch.id, updatedAt: now);
    await _dao.updateDeckById(
      deck.id,
      DecksCompanion(
        parentDeckId: Value<String?>(targetRow.id),
        updatedAt: Value<DateTime>(now),
      ),
    );
    // **Tombstones inside the subtree move too** (BR-188). A branch deleted
    // earlier still lives under this deck and must point at the tree it now
    // sits in, or invariant 6 fires and restoring it later hands back a deck
    // naming a root it does not belong to.
    await _dao.updateSubtreeRootDeck(
      deckId: deck.id,
      newRootDeckId: targetRootRow.id,
      updatedAt: now,
    );
    if (DeckContentType.fromDbValue(targetRow.contentType) ==
        DeckContentType.unset) {
      await _dao.updateDeckById(
        targetRow.id,
        DecksCompanion(
          contentType: Value<String>(DeckContentType.deck.dbValue),
          updatedAt: Value<DateTime>(now),
        ),
      );
    }
  }

  /// A root deck goes back to being a root — nothing to re-parent (BR-187).
  Future<void> _restoreRootDeck(
    DeleteBatch batch, {
    required TrashRestoreTarget target,
    required DateTime now,
  }) async {
    if (target is! TrashTopLevelTarget) {
      throw const ConflictFailure(
        message: 'Refused: a top-level deck restores only to the top level.',
        reason: TrashConflictReason.targetLevelMismatch,
      );
    }

    // `parent_deck_id` is already NULL and `root_deck_id` already points at
    // itself, so clearing the tombstones is the whole operation. Writing either
    // column again would be a second owner of a fact that never changed.
    await _dao.restoreBatchRows(batchId: batch.id, updatedAt: now);
  }

  /// The target Undo would use: the place the tombstone still points at.
  Future<TrashRestoreTarget> _undoTargetFor(String batchId) async {
    final batch = await _dao.batchById(batchId);
    if (batch == null) {
      throw const NotFoundFailure(message: 'That item is no longer in Trash.');
    }

    final itemType = TrashItemType.fromDbValue(batch.itemType);
    if (itemType == TrashItemType.card) {
      final card = await _dao.tombstoneCardInBatch(
        cardId: batch.rootItemId,
        batchId: batchId,
      );
      if (card == null) {
        throw const NotFoundFailure(
          message: 'That card is no longer in Trash.',
        );
      }

      return TrashDeckTarget(deckId: card.deckId, name: '', parentName: null);
    }

    final deck = await _dao.tombstoneDeckInBatch(
      deckId: batch.rootItemId,
      batchId: batchId,
    );
    if (deck == null) {
      throw const NotFoundFailure(message: 'That deck is no longer in Trash.');
    }

    final parentId = deck.parentDeckId;
    if (parentId == null) return const TrashTopLevelTarget();

    return TrashDeckTarget(deckId: parentId, name: '', parentName: null);
  }
}
