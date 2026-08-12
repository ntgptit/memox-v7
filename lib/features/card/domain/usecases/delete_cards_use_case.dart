import '../repositories/card_repository.dart';

/// Deletes a selection of cards (UC-04 A6, BR-166).
///
/// The confirmation happened before this is reached; study state and history
/// cascade through the schema's foreign keys, and a deck left empty gives its
/// content type back inside the same write, per BR-163.
class DeleteCardsUseCase {
  const DeleteCardsUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call(List<String> cardIds) => _repository.deleteCards(cardIds);
}
