import '../entities/card_entity.dart';
import '../repositories/card_repository.dart';

/// The cards of one deck, re-emitted on every change (UC-04).
///
/// Thin, and that is the accepted cost AD-12 names: uniformity is what makes a
/// new feature a clone rather than a judgement call at every operation, so a
/// read gets a use case even when it forwards.
class WatchCardsByDeckUseCase {
  const WatchCardsByDeckUseCase(this._repository);

  final CardRepository _repository;

  Stream<List<CardEntity>> call(String deckId) =>
      _repository.watchCardsByDeck(deckId);
}
