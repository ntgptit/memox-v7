import '../models/card_list_filter_model.dart';
import '../models/card_list_item_model.dart';
import '../models/card_list_sort_model.dart';
import '../repositories/card_repository.dart';

/// One deck's cards with their state and tags, for the management list, narrowed
/// by [filter] (UC-04 W1, D3, D5).
///
/// Thin, and it keeps the window and filter opinions out of the domain: the
/// screen passes [limit] and [filter], so it stays the one place that decides
/// how far the window is open and which cards it shows.
class WatchCardListItemsUseCase {
  const WatchCardListItemsUseCase(this._repository);

  final CardRepository _repository;

  Stream<List<CardListItemModel>> call(
    String deckId, {
    required int limit,
    CardListFilter filter = CardListFilter.all,
    CardListSort sort = CardListSort.newest,
    String? searchTerm,
    DateTime? now,
  }) => _repository.watchCardListItems(
    deckId,
    limit: limit,
    filter: filter,
    sort: sort,
    // Both of these were accepted here and then dropped on the floor — the
    // parameters are optional with defaults, so the call compiled and every
    // search typed into the card list filtered the count but never the rows
    // ("Showing 3 of 1"), and the sort control changed nothing. The repository
    // tests could not see it (they call the repository directly) and neither
    // could the widget tests (they fake the repository); only driving the real
    // app end-to-end put both layers in one line of sight.
    searchTerm: searchTerm,
    now: now,
  );
}
