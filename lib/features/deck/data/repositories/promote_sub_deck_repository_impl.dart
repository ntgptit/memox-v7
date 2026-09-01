part of 'deck_repository_impl.dart';

/// The deliberate destructive conversion from a branch into a new root.
///
/// This is not a `moveDeck(targetParentDeckId: null)` shortcut. A root owns a
/// scheduler, its generation and its lock; a branch has none of those fields.
/// Promotion therefore takes an explicit scheduler and resets only the
/// extracted subtree as one transaction (BR-269, UC-23).
mixin _PromoteSubDeckOperation implements DeckRepository {
  DeckDao get _dao;
  DateTime Function() get _clock;
  StudyRepository get _study;

  Future<T> _guard<T>(Future<T> Function() action);
  Future<Deck> _requireDeckRow(String deckId);
  DeckContentType _knownContentType(Deck deck);
  Future<void> _unsetParentIfEmptied(String parentDeckId);

  @override
  Future<void> promoteSubDeckToRoot({
    required String deckId,
    required SchedulerType schedulerType,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      // Re-read all facts inside the write transaction. A menu can stay open
      // while another mutation changes the branch or adds its first card.
      final source = await _requireDeckRow(deckId);
      final oldParentDeckId = source.parentDeckId;
      if (oldParentDeckId == null) {
        throw const ConflictFailure(
          message: 'Refused: only a sub-deck can become a new root.',
          reason: DeckConflictReason.promotionNeedsSubDeck,
        );
      }
      if (schedulerType == SchedulerType.unknown) {
        throw const ConflictFailure(
          message: 'Refused: that study mode is unknown to this version.',
          reason: DeckConflictReason.promotionSchedulerUnknown,
        );
      }

      // Root decks never directly hold cards. `content_type` alone is not
      // enough here: corrupt or stale metadata must not create an invalid root.
      _knownContentType(source);
      if (await _dao.directCardCount(source.id) > 0) {
        throw const ConflictFailure(
          message: 'Refused: a promoted root cannot directly hold cards.',
          reason: DeckConflictReason.promotionDeckHasCards,
        );
      }

      final subtreeDeckIds = await _dao.subtreeDeckIds(source.id);
      final subtreeCardIds = await _dao.subtreeCardIds(source.id);
      final now = _clock();
      final rootPosition = await _dao.nextSiblingPosition(null);

      // Set root-only columns on the source first. Descendants already have
      // their scheduler columns null by invariant; root pointer rewriting below
      // reaches every node and does not disturb their parent relationships.
      await _dao.updateDeckById(
        source.id,
        DecksCompanion(
          parentDeckId: const Value<String?>(null),
          rootDeckId: Value<String>(source.id),
          siblingPosition: Value<int>(rootPosition),
          contentType: Value<String>(DeckContentType.deck.dbValue),
          schedulerType: Value<String?>(schedulerType.dbValue),
          schedulerVersion: const Value<int?>(_initialSchedulerVersion),
          schedulerConfig: const Value<String?>(null),
          schedulerGeneration: const Value<int?>(_initialSchedulerGeneration),
          firstAnsweredAt: const Value<DateTime?>(null),
          studyConfig: const Value<String?>(null),
          updatedAt: Value<DateTime>(now),
        ),
      );
      await _dao.updateSubtreeRootDeck(
        deckId: source.id,
        newRootDeckId: source.id,
        updatedAt: now,
      );
      await _dao.resetTreeStudyStates(
        rootDeckId: source.id,
        schedulerType: schedulerType,
        generation: _initialSchedulerGeneration,
      );

      // A root-wide queue can already contain a card in this branch even when
      // its `deck_id` remains the former root; both id sets are needed.
      await _study.invalidateSessionsForPromotedSubtree(
        deckIds: subtreeDeckIds,
        cardIds: subtreeCardIds,
        endedAt: now,
      );
      await _unsetParentIfEmptied(oldParentDeckId);
    }),
  );
}
