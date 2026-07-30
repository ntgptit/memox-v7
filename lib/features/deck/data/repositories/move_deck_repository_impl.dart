part of 'deck_repository_impl.dart';

/// The subtree-move half of [DeckRepositoryImpl] — same class, same library,
/// split out only so each source file stays readable.
mixin _MoveDeckOperation implements DeckRepository {
  DeckDao get _dao;
  DateTime Function() get _clock;

  Future<T> _guard<T>(Future<T> Function() action);
  Future<Deck> _requireDeckRow(String deckId);
  DeckContentType _knownContentType(Deck deck);
  Future<int> _requireDeckDepth(String deckId);
  Future<int> _requireSubtreeHeight(String deckId);

  @override
  Future<void> moveDeck({
    required String deckId,
    required String targetParentDeckId,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      // The rule set is UC-09 step 2 and it lives in the domain, in
      // `deckMoveRejection`. This half only gathers the facts it needs — from
      // SQLite, one at a time, inside the transaction so a refused move changes
      // nothing: no parent pointer, no root pointer, no content type, no
      // timestamp.
      //
      // Until M4.10 these eight rules were written out here as eight
      // `ConflictFailure(message: '<sentence>')` throws, with no import of the
      // domain function that already expressed them. Two spellings of one rule
      // set, free to drift, and the reasons arrived at the user as one sentence
      // because a message is not something the UI may render.
      final source = await _requireDeckRow(deckId);
      final target = await _requireDeckRow(targetParentDeckId);
      final sourceEntity = deckEntityFromRow(source);
      final targetEntity = deckEntityFromRow(target);
      final subtreeIds = await _dao.subtreeDeckIds(source.id);
      final targetType = _knownContentType(target);

      // Each root read once. The entity mapper is what turns the stored
      // scheduler string into the enum the rule compares, so the rule never
      // sees a database value.
      final sourceRoot = deckEntityFromRow(
        await _requireDeckRow(source.rootDeckId),
      );
      final targetRoot = deckEntityFromRow(
        await _requireDeckRow(target.rootDeckId),
      );

      final rejection = deckMoveRejection(
        source: sourceEntity,
        target: targetEntity,
        isTargetInSourceSubtree: subtreeIds.contains(target.id),
        sourceRootScheduler: sourceRoot.schedulerType,
        sourceRootGeneration: sourceRoot.schedulerGeneration,
        targetRootScheduler: targetRoot.schedulerType,
        targetRootGeneration: targetRoot.schedulerGeneration,
        targetDepth: await _requireDeckDepth(target.id),
        sourceSubtreeHeight: await _requireSubtreeHeight(source.id),
      );
      if (rejection != null) {
        throw ConflictFailure(
          // The message is for the log; the reason is what the screen reads.
          message: 'The move was refused by UC-09 rule ${rejection.name}.',
          reason: rejection,
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
