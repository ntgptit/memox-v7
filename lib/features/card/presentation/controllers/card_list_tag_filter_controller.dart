import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/tag_filter_model.dart';
import '../providers/card_use_case_provider.dart';
import 'card_list_filter_controller.dart';
import 'card_list_now_controller.dart';
import 'card_list_window_controller.dart';

part 'card_list_tag_filter_controller.g.dart';

/// Which tags the card list is narrowed to, **applied** (BR-231, BR-232).
///
/// An input-state notifier beside the filter, the search term and the sort, and
/// it resets the window for exactly their reason: a window grown over 142 cards
/// describes nothing once the list is the 12 that carry one tag (BR-232).
/// `family` on the deck id so two decks do not share a tag filter.
///
/// **One value and one mutator, like every other input-state notifier here.**
/// `apply` replaces the selection whole; clearing is `apply(TagFilter.none)`,
/// and dropping ids that no longer exist is `apply(tags.retaining(…))`. Each of
/// those was briefly its own method, and each was the same operation wearing a
/// name — the composition belongs to [TagFilter], which is where the algebra
/// already lives.
///
/// **There is no `toggle` here.** The overlay owns a draft and commits it once
/// (M4.14 T5), so a tap on a checkbox cannot reset the window behind a sheet the
/// user has not finished with — that would re-read the list N times for one
/// intention.
@riverpod
class CardListTagFilter extends _$CardListTagFilter {
  @override
  TagFilter build(String deckId) => TagFilter.none;

  void apply(TagFilter tags) {
    if (tags == state) return;
    state = tags;
    // Same invalidation the other three inputs use: the window is a value with
    // one mutator, and re-creating its autoDispose notifier starts it fresh.
    ref.invalidate(cardListWindowProvider(deckId));
  }
}

/// The draft the filter overlay edits before `Apply` (M4.14 T5, W6).
///
/// Seeded from the applied filter each time the overlay opens — through
/// `showMxFormSheet`'s `reset`, which runs from the tap that shows the sheet
/// rather than from a life-cycle callback. Closing without applying simply drops
/// it (UC-18 A5).
///
/// **One mutator, and the toggle lives in [TagFilter].** `select(draft.toggled(
/// id))` reads longer than `toggle(id)` and is the honest shape: what a checkbox
/// produces is a *new selection*, and the rule for building one belongs to the
/// value object both the draft and the applied filter are made of — not to two
/// notifiers that would each own half of it.
@riverpod
class CardListTagFilterDraft extends _$CardListTagFilterDraft {
  @override
  TagFilter build(String deckId) => TagFilter.none;

  void select(TagFilter tags) => state = tags;
}

/// How many cards the **draft** would match — the number on `Apply` (M4.14 T6).
///
/// The same count statement the header uses, with the draft's tags instead of
/// the applied ones, so the preview and the result cannot disagree: one
/// predicate, two callers (BR-231).
@Riverpod(retry: noAutomaticRetry)
Stream<int> cardListTagDraftCount(Ref ref, String deckId) {
  final filter = ref.watch(cardListFilterSelectionProvider(deckId));

  return ref.watch(watchCardCountUseCaseProvider)(
    deckId,
    filter: filter,
    searchTerm: ref.watch(cardListSearchQueryProvider(deckId)),
    now: filter == CardListFilter.due ? ref.watch(cardListNowProvider) : null,
    tags: ref.watch(cardListTagFilterDraftProvider(deckId)),
  );
}
