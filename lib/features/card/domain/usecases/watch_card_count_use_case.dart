import '../repositories/card_repository.dart';

/// How many cards the deck holds, for the "showing N of M" line (UC-04).
///
/// Separate from the list read because the count comes from its own statement —
/// see `CardRepository.watchCardCountByDeck` for why a window function beside
/// the rows would cancel the `LIMIT`'s early stop.
class WatchCardCountUseCase {
  const WatchCardCountUseCase(this._repository);

  final CardRepository _repository;

  Stream<int> call(String deckId) => _repository.watchCardCountByDeck(deckId);
}
