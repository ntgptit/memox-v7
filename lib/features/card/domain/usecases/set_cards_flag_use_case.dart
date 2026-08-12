import '../repositories/card_repository.dart';

/// Sets or clears the flag on a selection (UC-04 A6, BR-92, BR-166).
///
/// [isFlagged] is required rather than inferred: a batch toggle read from the
/// first card turns one mixed selection into another, which is not an outcome
/// anybody asked for.
class SetCardsFlagUseCase {
  const SetCardsFlagUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call({required List<String> cardIds, required bool isFlagged}) =>
      _repository.setCardsFlag(cardIds: cardIds, isFlagged: isFlagged);
}
