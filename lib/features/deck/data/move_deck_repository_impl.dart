part of 'deck_repository_impl.dart';

/// The subtree-move half of [DeckRepositoryImpl] — same class, same library,
/// split out only so each source file stays readable.
mixin _MoveDeckOperation implements DeckRepository {
  DeckDao get _dao;
  DateTime Function() get _clock;

  Future<T> _guard<T>(Future<T> Function() action);
  Future<Deck> _requireDeckRow(String deckId);
  DeckContentType _knownContentType(Deck deck);

  @override
  Future<void> moveDeck({
    required String deckId,
    required String targetParentDeckId,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      // Validation order follows UC-09 step 2 exactly.
      final source = await _requireDeckRow(deckId);
      final target = await _requireDeckRow(targetParentDeckId);
      if (source.parentDeckId == null) {
        // Moving a root would put scheduler columns on a non-root (BR-06).
        // Demoting a root is a new decision, not a move — same reasoning as
        // UC-09 A2 in the other direction.
        throw const ConflictFailure(
          message: 'A top-level deck cannot be moved into another deck.',
        );
      }
      if (target.id == source.id) {
        throw const ConflictFailure(
          message: 'A deck cannot be moved into itself.',
        );
      }
      final subtreeIds = await _dao.subtreeDeckIds(source.id);
      if (subtreeIds.contains(target.id)) {
        // The cycle guard (BR-69, BR-70).
        throw const ConflictFailure(
          message: 'A deck cannot be moved into one of its own sub-decks.',
        );
      }
      final targetType = _knownContentType(target);
      if (targetType == DeckContentType.card) {
        throw const ConflictFailure(
          message: 'The target deck holds cards, so it cannot hold decks.',
        );
      }
      final sourceRoot = await _requireDeckRow(source.rootDeckId);
      final targetRoot = await _requireDeckRow(target.rootDeckId);
      if (sourceRoot.schedulerType != targetRoot.schedulerType) {
        // Never silently converted (BR-73, BR-74).
        throw const ConflictFailure(
          message: 'The target uses a different study mode.',
        );
      }
      if (sourceRoot.schedulerGeneration != targetRoot.schedulerGeneration) {
        throw const ConflictFailure(
          message: 'The target is on a different learning cycle.',
        );
      }

      final now = _clock();
      await _dao.updateDeckById(
        source.id,
        DecksCompanion(
          parentDeckId: Value<String?>(target.id),
          updatedAt: Value<DateTime>(now),
        ),
      );
      if (targetType == DeckContentType.unset) {
        // The moved deck is the target's first child (BR-62).
        await _dao.updateDeckById(
          target.id,
          DecksCompanion(
            contentType: Value<String>(DeckContentType.deck.dbValue),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }
      // Every node of the subtree, one statement, same atomic step (BR-71).
      await _dao.updateSubtreeRootDeck(
        deckId: source.id,
        newRootDeckId: targetRoot.id,
        updatedAt: now,
      );
    }),
  );
}
