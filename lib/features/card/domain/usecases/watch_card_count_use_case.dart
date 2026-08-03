import '../models/card_list_filter_model.dart';
import '../repositories/card_repository.dart';

/// How many cards a [filter] would show — the "showing N of M" denominator and
/// the pill counts (UC-04, D3).
///
/// Separate from the list read because the count comes from its own statement —
/// see `CardRepository.watchFilteredCardCount` for why a window function beside
/// the rows would cancel the `LIMIT`'s early stop.
class WatchCardCountUseCase {
  const WatchCardCountUseCase(this._repository);

  final CardRepository _repository;

  Stream<int> call(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    DateTime? now,
  }) => _repository.watchFilteredCardCount(deckId, filter: filter, now: now);
}
