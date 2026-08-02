import '../repositories/card_repository.dart';

/// Removes a tag from a card (BR-93). Thin — there is nothing to validate about
/// detaching a tag, and the repository leaves the tag row for other cards.
class RemoveCardTagUseCase {
  const RemoveCardTagUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call({required String cardId, required String tagId}) =>
      _repository.removeCardTag(cardId: cardId, tagId: tagId);
}
