import '../models/tag_name_model.dart';
import '../repositories/card_repository.dart';

/// Adds one tag to a selection (UC-04 A6, BR-93, BR-94, BR-166).
///
/// The name arrives as a [TagName], so the trimming and the length rule ran
/// before this layer; what the repository still owns is the folded-name reuse,
/// the ten-tag cap, and refusing the whole batch when one card would pass it.
class AddTagToCardsUseCase {
  const AddTagToCardsUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call({required List<String> cardIds, required TagName name}) =>
      _repository.addTagToCards(cardIds: cardIds, name: name);
}
