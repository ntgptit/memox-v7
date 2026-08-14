import '../repositories/card_repository.dart';

/// Deletes a card (UC-04 A2).
///
/// No validation here on purpose: the confirmation happened before this is
/// reached, and the study state and history cascade through the schema's
/// foreign keys rather than through a rule this layer could check.
///
/// When this was the deck's last card the deck goes back to `unset` in the
/// same write — BR-163 makes the type system state, not a setting, so there is
/// nothing for the user to reset afterwards.
class DeleteCardUseCase {
  const DeleteCardUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call(String cardId) => _repository.deleteCard(cardId);
}

/// The same deletion, returning the batch so the caller can offer Undo
/// (BR-182, BR-189).
///
/// A second use case rather than a flag, for the reason
/// `DeleteDeckForUndoUseCase` gives: the batch id is useful for the life of one
/// snackbar, and every other caller must not be handed it at all.
class DeleteCardForUndoUseCase {
  const DeleteCardForUndoUseCase(this._repository);

  final CardRepository _repository;

  Future<String> call(String cardId) => _repository.deleteCardForUndo(cardId);
}
