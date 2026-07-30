import '../repositories/deck_repository.dart';

/// Moves a subtree under a new parent (UC-09).
///
/// The rule set lives in `domain/failures/deck_move_failure.dart` and is applied
/// inside the repository's transaction, where the tree cannot change underneath
/// it. This is the entry point, not a second copy of the rules — that second copy
/// existed until M4.10, and what it cost is recorded there.
class MoveDeckUseCase {
  const MoveDeckUseCase(this._repository);

  final DeckRepository _repository;

  Future<void> call({
    required String deckId,
    required String targetParentDeckId,
  }) => _repository.moveDeck(
    deckId: deckId,
    targetParentDeckId: targetParentDeckId,
  );
}
