import '../repositories/deck_repository.dart';

/// Puts an empty sub-deck's content type back to `unset` (UC-03 A3, BR-68).
///
/// Whether the deck is empty is decided by the repository inside its transaction.
/// The tree can change between the dialog opening and the confirm landing, so a
/// check here would be answering a question about a moment that has already
/// passed — and the answer would be a race.
class ResetDeckContentTypeUseCase {
  const ResetDeckContentTypeUseCase(this._repository);

  final DeckRepository _repository;

  Future<void> call(String deckId) => _repository.resetContentType(deckId);
}
