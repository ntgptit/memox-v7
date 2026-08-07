import '../entities/card_entity.dart';
import '../models/card_text_model.dart';
import '../repositories/card_repository.dart';

/// Edits a card's content (UC-04 A1, BR-10).
///
/// The same two rules as creating, applied the same way — and that sameness is
/// the point of [parseCardSides]: an edit that validated differently from a
/// create is a card that can be saved in a state it could not be created in.
///
/// It cannot touch the study state or the history: the repository writes only
/// to `cards`, so BR-10 holds structurally rather than by remembering to.
class UpdateCardUseCase {
  const UpdateCardUseCase(this._repository);

  final CardRepository _repository;

  /// `async` for the reason spelled out on [CreateCardUseCase.call]: a refusal
  /// must arrive through the future, like every other failure.
  Future<CardEntity> call({
    required String cardId,
    required String rawFront,
    required String rawBack,
    String rawExample = '',
    String rawHint = '',
    String rawPronunciation = '',
  }) async {
    final form = parseCardForm(
      rawFront: rawFront,
      rawBack: rawBack,
      rawExample: rawExample,
      rawHint: rawHint,
      rawPronunciation: rawPronunciation,
    );

    return _repository.updateCard(
      cardId: cardId,
      front: form.front,
      back: form.back,
      example: form.example,
      hint: form.hint,
      pronunciation: form.pronunciation,
    );
  }
}
