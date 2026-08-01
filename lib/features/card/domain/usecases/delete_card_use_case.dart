import '../repositories/card_repository.dart';

/// Deletes a card (UC-04 A2).
///
/// No validation here on purpose: the confirmation happened before this is
/// reached, and the review state and history cascade through the schema's
/// foreign keys rather than through a rule this layer could check.
///
/// The deck's `content_type` is deliberately left alone, even when this was the
/// last card (BR-67) — resetting it is a separate, confirmed action.
class DeleteCardUseCase {
  const DeleteCardUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call(String cardId) => _repository.deleteCard(cardId);
}
