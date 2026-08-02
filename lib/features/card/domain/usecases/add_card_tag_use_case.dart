import '../failures/tag_validation_failure.dart';
import '../models/tag_name_model.dart';
import '../repositories/card_repository.dart';

/// Adds a tag to a card (BR-93, BR-94).
///
/// BR-93's trim and length run here, at the type boundary: [rawName] becomes a
/// [TagName] or the call is refused before the repository is touched — the same
/// arrangement `parseCardSides` gives the card sides. BR-94's ten-tag cap is the
/// repository's, because it needs the count as it stands at the moment of the
/// write.
class AddCardTagUseCase {
  const AddCardTagUseCase(this._repository);

  final CardRepository _repository;

  /// `async` so a refusal arrives through the future, like every other failure
  /// from this layer — `TagName.parse` reports rather than throws, so the throw
  /// is `refuseInvalidTag`'s and it happens after the future exists.
  Future<void> call({required String cardId, required String rawName}) async {
    final parsed = TagName.parse(rawName);
    final problem = parsed.problem;
    if (problem != null) {
      refuseInvalidTag(<TagValidationProblem>{problem});
    }

    await _repository.addCardTag(cardId: cardId, name: parsed.name!);
  }
}
