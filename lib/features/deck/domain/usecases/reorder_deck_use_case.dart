import '../models/deck_reorder_placement_model.dart';
import '../repositories/deck_repository.dart';

/// Changes one deck's position relative to one sibling.
class ReorderDeckUseCase {
  const ReorderDeckUseCase(this._repository);

  final DeckRepository _repository;

  Future<void> call({
    required String deckId,
    required String targetSiblingDeckId,
    required DeckReorderPlacement placement,
  }) => _repository.reorderDeck(
    deckId: deckId,
    targetSiblingDeckId: targetSiblingDeckId,
    placement: placement,
  );
}
