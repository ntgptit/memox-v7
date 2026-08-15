import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_item_model.dart';
import '../providers/card_use_case_provider.dart';
import 'card_list_filter_controller.dart';
import 'card_list_now_controller.dart';
import 'card_list_tag_filter_controller.dart';
import 'card_list_window_controller.dart';

part 'card_list_controller.g.dart';

/// One deck's cards, capped at the window the user has scrolled open.
///
/// **The window size is `watch`ed, not passed** — growing it (a load-more tap)
/// moves `cardListWindowProvider`, this rebuilds, and the stream re-subscribes
/// at the larger `limit`. So the screen owns how far the window is open and the
/// read follows it, with no cursor threaded through (see `card.drift`).
///
/// `family` on the deck id, `autoDispose` by the generator default: leaving the
/// deck drops the subscription and the window with it.
///
/// Automatic retry is off (`noAutomaticRetry`): while Riverpod retries, the
/// state is `AsyncLoading`, so a failed local read would spin on a spinner
/// instead of reaching the error state the screen draws.
@Riverpod(retry: noAutomaticRetry)
class CardList extends _$CardList {
  @override
  Stream<List<CardListItemModel>> build(String deckId) {
    final filter = ref.watch(cardListFilterSelectionProvider(deckId));
    final sort = ref.watch(cardListSortSelectionProvider(deckId));
    final search = ref.watch(cardListSearchQueryProvider(deckId));
    final limit = ref.watch(cardListWindowProvider(deckId));
    // `now` only matters to the Due filter, so only that filter watches it —
    // the others must not re-subscribe every time the clock ticks.
    final now = filter == CardListFilter.due
        ? ref.watch(cardListNowProvider)
        : null;

    return ref.watch(watchCardListItemsUseCaseProvider)(
      deckId,
      limit: limit,
      filter: filter,
      sort: sort,
      searchTerm: search,
      now: now,
      // The applied tag selection, not the overlay's draft: the list follows
      // `Apply`, so a half-built selection never re-reads it (BR-232, M4.14 T5).
      tags: ref.watch(cardListTagFilterProvider(deckId)),
    );
  }
}

/// The deck's whole card count, for the "showing N of M" line.
///
/// A separate notifier from [CardList] because it is a separate statement: the
/// count cannot ride beside the rows without making SQLite materialise the whole
/// deck (see `CardRepository.watchCardCountByDeck`). The screen combines the two
/// AsyncValues; it does not ask the domain to pretend they are one.
@Riverpod(retry: noAutomaticRetry)
class CardCount extends _$CardCount {
  @override
  Stream<int> build(String deckId) {
    // The denominator of "showing N of M" is the *active* filter's total (§4.3),
    // so it follows the filter — the pills each read their own fixed count.
    final filter = ref.watch(cardListFilterSelectionProvider(deckId));
    final search = ref.watch(cardListSearchQueryProvider(deckId));
    final now = filter == CardListFilter.due
        ? ref.watch(cardListNowProvider)
        : null;

    return ref.watch(watchCardCountUseCaseProvider)(
      deckId,
      filter: filter,
      searchTerm: search,
      now: now,
      // The denominator has to be the list's own predicate, tag filter
      // included, or the header reads "Showing 12 of 3" (BR-231).
      tags: ref.watch(cardListTagFilterProvider(deckId)),
    );
  }
}
