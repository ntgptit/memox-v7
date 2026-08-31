part of 'deck_repository_impl.dart';

/// Persisted sibling ordering. This deliberately shares no implementation with
/// MoveDeck: a reorder has one invariant — the two decks stay siblings — and
/// must not touch parent/root pointers, scheduler state, cards or descendants.
mixin _ReorderDeckOperation implements DeckRepository {
  DeckDao get _dao;
  DateTime Function() get _clock;

  Future<T> _guard<T>(Future<T> Function() action);
  Future<Deck> _requireDeckRow(String deckId);

  @override
  Future<void> reorderDeck({
    required String deckId,
    required String targetSiblingDeckId,
    required DeckReorderPlacement placement,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      final source = await _requireDeckRow(deckId);
      final target = await _requireDeckRow(targetSiblingDeckId);
      if (source.parentDeckId != target.parentDeckId) {
        throw const ConflictFailure(
          message: 'Refused: reorder target is not a sibling.',
        );
      }
      if (source.id == target.id) return;

      final siblings = await _dao.siblingDecks(source.parentDeckId);
      final reordered = <Deck>[for (final sibling in siblings) sibling];
      reordered.removeWhere((Deck sibling) => sibling.id == source.id);
      final targetIndex = reordered.indexWhere(
        (Deck sibling) => sibling.id == target.id,
      );
      if (targetIndex == -1) {
        // Both rows were active when read above. This defensive guard makes a
        // future DAO/query change fail closed rather than write an arbitrary
        // position if that assumption stops holding.
        throw const ConflictFailure(
          message: 'Refused: reorder target disappeared from its sibling set.',
        );
      }

      final insertionIndex = switch (placement) {
        DeckReorderPlacement.before => targetIndex,
        DeckReorderPlacement.after => targetIndex + 1,
      };
      reordered.insert(insertionIndex, source);
      if (_sameSiblingOrder(siblings, reordered)) return;

      final now = _clock();
      for (var index = 0; index < reordered.length; index++) {
        final deck = reordered[index];
        if (deck.siblingPosition == index) continue;
        await _dao.updateDeckById(
          deck.id,
          DecksCompanion(
            siblingPosition: Value<int>(index),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }
    }),
  );

  bool _sameSiblingOrder(List<Deck> left, List<Deck> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].id != right[index].id) return false;
    }

    return true;
  }
}
