import '../repositories/card_repository.dart';

/// Toggles the user's flag on a card (UC-04, BR-92).
///
/// Thin, and that is the accepted cost AD-12 names: even a one-line write gets a
/// use case so a controller never reaches the repository. It validates nothing —
/// a boolean has nothing to validate — and the repository keeps the write to the
/// one column.
class SetCardFlagUseCase {
  const SetCardFlagUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call({required String cardId, required bool isFlagged}) =>
      _repository.setCardFlag(cardId: cardId, isFlagged: isFlagged);
}
