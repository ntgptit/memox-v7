import '../entities/card_entity.dart';
import '../models/card_text_model.dart';
import '../repositories/card_repository.dart';

/// Creates a card in a deck (UC-04, UC-08).
///
/// Applies BR-07 and BR-08 to both sides and refuses once with everything
/// wrong; what it hands the repository is already valid, which is what the
/// `CardText` parameters on the contract say.
///
/// The rules that need the tree as it stands at the moment of writing stay in
/// the repository, inside its transaction: BR-58 (no card under a root), BR-63
/// (a deck holds one kind of thing), the BR-62 first-card content lock and the
/// BR-09 review state. Checking any of them here would answer a question about
/// a moment that has already passed by the time the write runs.
class CreateCardUseCase {
  const CreateCardUseCase(this._repository);

  final CardRepository _repository;

  /// `async`, and that is not decoration. Without it `parseCardSides` throws
  /// **synchronously** from a method whose type says `Future`, so a refusal
  /// escapes before the future exists and `call(...).catchError(...)` — an
  /// ordinary Dart idiom — cannot see it. Every other failure from this layer
  /// arrives through the future; a validation failure arriving by a second
  /// mechanism is the asymmetry a controller gets wrong exactly once.
  Future<CardEntity> call({
    required String deckId,
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

    return _repository.createCard(
      deckId: deckId,
      front: form.front,
      back: form.back,
      example: form.example,
      hint: form.hint,
      pronunciation: form.pronunciation,
    );
  }
}
