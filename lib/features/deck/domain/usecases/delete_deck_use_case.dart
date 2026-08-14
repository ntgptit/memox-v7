import '../repositories/deck_repository.dart';

/// Deletes a deck and everything under it (UC-03, BR-03, BR-04).
///
/// No validation here on purpose: the impact was shown and confirmed before this
/// is reached, and the cascade is enforced by the schema's foreign keys rather
/// than by a rule this layer could check.
class DeleteDeckUseCase {
  const DeleteDeckUseCase(this._repository);

  final DeckRepository _repository;

  Future<void> call(String deckId) => _repository.deleteDeck(deckId);
}

/// The same deletion, returning the batch so the caller can offer Undo
/// (BR-182, BR-189).
///
/// A second use case rather than a flag, because the two have different
/// contracts: this one hands back something the caller must use within the life
/// of one snackbar, and every other delete caller must not be handed it at all.
class DeleteDeckForUndoUseCase {
  const DeleteDeckForUndoUseCase(this._repository);

  final DeckRepository _repository;

  Future<String> call(String deckId) => _repository.deleteDeckForUndo(deckId);
}
