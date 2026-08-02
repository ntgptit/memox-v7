import '../models/card_list_item_model.dart';
import '../repositories/card_repository.dart';

/// One deck's cards with their state, for the management list (UC-04 W1, D5).
///
/// Thin, like the other reads, and it keeps the window opinion out of the domain
/// the same way `WatchCardsByDeckUseCase` does: the caller passes [limit], so the
/// screen stays the one place that decides how far the window is open.
class WatchCardListItemsUseCase {
  const WatchCardListItemsUseCase(this._repository);

  final CardRepository _repository;

  Stream<List<CardListItemModel>> call(String deckId, {required int limit}) =>
      _repository.watchCardListItems(deckId, limit: limit);
}
