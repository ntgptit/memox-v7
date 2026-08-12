import '../repositories/card_repository.dart';

/// Moves cards into another deck of the same tree (UC-04 A5, BR-165).
///
/// **One use case for one and for many.** The interaction is the same whether
/// the user moved a card from its editor or a selection from the list, and the
/// repository takes a list either way — a separate single-card use case would
/// be a second name for the same call, and the two would drift the first time
/// one grew a rule.
///
/// No validation here. Every rule BR-165 states — same root, target not a
/// root, target not holding decks, target not the source — needs the tree as
/// it stands at the moment of writing, so it lives inside the repository's
/// transaction. Checking here as well would be a second owner of the rule and
/// a race with the write.
class MoveCardsUseCase {
  const MoveCardsUseCase(this._repository);

  final CardRepository _repository;

  Future<void> call({
    required List<String> cardIds,
    required String targetDeckId,
  }) => _repository.moveCards(cardIds: cardIds, targetDeckId: targetDeckId);
}
