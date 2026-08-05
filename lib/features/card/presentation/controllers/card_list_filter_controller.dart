import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_sort_model.dart';
import '../providers/card_use_case_provider.dart';
import 'card_list_now_controller.dart';
import 'card_list_window_controller.dart';

part 'card_list_filter_controller.g.dart';

/// Which filter the card list is showing (D3).
///
/// An input-state notifier: the UI owns the value and the list read is
/// parameterized by it. [select] resets the window by invalidating it rather
/// than calling a mutator on it — a window opened over 142 cards is meaningless
/// over the 23 that are due, so switching filters starts the window fresh
/// (§4.3). `family` on the deck id so two decks do not share a filter.
@riverpod
class CardListFilterSelection extends _$CardListFilterSelection {
  @override
  CardListFilter build(String deckId) => CardListFilter.all;

  void select(CardListFilter filter) {
    if (filter == state) return;
    state = filter;
    // Invalidate rather than a `reset()` on the window: the window stays a value
    // with one mutator (`grow`), and re-creating its autoDispose notifier starts
    // it at `kCardWindowSize`.
    ref.invalidate(cardListWindowProvider(deckId));
  }
}

/// What the user has typed into the card list's search field (S1).
///
/// An input-state notifier beside the filter and the sort, and it resets the
/// window for the same reason they do: a window grown over the whole deck is
/// meaningless over the handful of cards a term matches.
@riverpod
class CardListSearchQuery extends _$CardListSearchQuery {
  @override
  String build(String deckId) => '';

  void update(String query) {
    if (query == state) return;
    state = query;
    ref.invalidate(cardListWindowProvider(deckId));
  }
}

/// Which order the card list is in (D3).
///
/// Its own notifier beside [CardListFilterSelection], and it resets the window
/// the same way: the list is a growing window, not pages, so re-ordering under a
/// reader who has grown it to 150 rows re-reads 150 rows in a new order and
/// leaves them nowhere they recognise. Starting at the first window is both the
/// cheaper read and the honest position.
@riverpod
class CardListSortSelection extends _$CardListSortSelection {
  @override
  CardListSort build(String deckId) => CardListSort.newest;

  void select(CardListSort sort) {
    if (sort == state) return;
    state = sort;
    ref.invalidate(cardListWindowProvider(deckId));
  }
}

/// The four pill counts (D3). Each is its own statement — the mirror of the four
/// filtered reads — so a pill can say how many its filter would show. Only the
/// Due count reads `now`, from the composition-root clock.
@Riverpod(retry: noAutomaticRetry)
Stream<int> cardAllCount(Ref ref, String deckId) =>
    ref.watch(watchCardCountUseCaseProvider)(deckId);

/// How many cards are due **and have been reviewed before** — the state table's
/// `due`, not BR-22's queue.
///
/// The two differ by exactly the new cards, and the difference is why this is
/// not the number the Start-study button shows: a session takes the queue, so
/// the button adds this to [cardNewCount]. Reading this one as "how many the
/// session will hand over" is the mistake the split exists to prevent.
@Riverpod(retry: noAutomaticRetry)
Stream<int> cardDueCount(Ref ref, String deckId) => ref.watch(
  watchCardCountUseCaseProvider,
)(deckId, filter: CardListFilter.due, now: ref.watch(cardListNowProvider));

@Riverpod(retry: noAutomaticRetry)
Stream<int> cardNewCount(Ref ref, String deckId) => ref.watch(
  watchCardCountUseCaseProvider,
)(deckId, filter: CardListFilter.isNew);

@Riverpod(retry: noAutomaticRetry)
Stream<int> cardFlaggedCount(Ref ref, String deckId) => ref.watch(
  watchCardCountUseCaseProvider,
)(deckId, filter: CardListFilter.flagged);
