import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/card_list_filter_model.dart';
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

/// The four pill counts (D3). Each is its own statement — the mirror of the four
/// filtered reads — so a pill can say how many its filter would show. Only the
/// Due-now count reads `now`, from the composition-root clock.
@Riverpod(retry: noAutomaticRetry)
Stream<int> cardAllCount(Ref ref, String deckId) =>
    ref.watch(watchCardCountUseCaseProvider)(deckId);

@Riverpod(retry: noAutomaticRetry)
Stream<int> cardDueCount(Ref ref, String deckId) => ref.watch(
  watchCardCountUseCaseProvider,
)(deckId, filter: CardListFilter.dueNow, now: ref.watch(cardListNowProvider));

@Riverpod(retry: noAutomaticRetry)
Stream<int> cardNewCount(Ref ref, String deckId) => ref.watch(
  watchCardCountUseCaseProvider,
)(deckId, filter: CardListFilter.isNew);

@Riverpod(retry: noAutomaticRetry)
Stream<int> cardFlaggedCount(Ref ref, String deckId) => ref.watch(
  watchCardCountUseCaseProvider,
)(deckId, filter: CardListFilter.flagged);
