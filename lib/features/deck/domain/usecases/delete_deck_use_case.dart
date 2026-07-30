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
