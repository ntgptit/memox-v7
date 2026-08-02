import '../entities/card_entity.dart';
import '../repositories/card_repository.dart';

/// One deck's cards, newest first, capped at the window the screen is showing
/// (UC-04).
///
/// Thin, and that is the accepted cost AD-12 names: uniformity is what makes a
/// new feature a clone rather than a judgement call at every operation, so a
/// read gets a use case even when it forwards.
///
/// It forwards [limit] rather than choosing it. How far the window has grown is
/// presentation state — the screen owns the scroll that grows it — and a
/// default here would be a second opinion about it that nothing can see.
class WatchCardsByDeckUseCase {
  const WatchCardsByDeckUseCase(this._repository);

  final CardRepository _repository;

  Stream<List<CardEntity>> call(String deckId, {required int limit}) =>
      _repository.watchCardsByDeck(deckId, limit: limit);
}
