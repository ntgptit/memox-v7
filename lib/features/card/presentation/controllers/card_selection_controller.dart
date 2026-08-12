import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/card_use_case_provider.dart';
import '../states/card_selection_state.dart';
import 'card_list_filter_controller.dart';
import 'card_list_now_controller.dart';

part 'card_selection_controller.g.dart';

/// Selection mode for one deck's card list (UC-04 A6, BR-167).
///
/// **A selection notifier writes nothing.** It is not a query of the data
/// layer, not a command against it, and not a single-value input like
/// `CardListNow`: it is the set of rows the user has pointed at, with the small
/// bounded vocabulary a selection has — enter, toggle, clear, take everything
/// matching. Every database mutation lives in its own command controller, so
/// the spinner and the failure belong to the write rather than to the set.
/// `command_query_separation_test.dart` bounds this kind by name, the way it
/// bounds the study session.
///
/// **It watches the filter, the search term and the sort, and clears itself
/// when any of them moves.** A selection made under one filter and acted on
/// under another is a mutation the user did not agree to — they would be
/// deleting rows they had just filtered away. Watching rather than being told
/// by the screen means no call site can forget.
@riverpod
class CardSelection extends _$CardSelection {
  @override
  CardSelectionState build(String deckId) {
    ref
      ..watch(cardListFilterSelectionProvider(deckId))
      ..watch(cardListSearchQueryProvider(deckId))
      ..watch(cardListSortSelectionProvider(deckId));

    return const CardSelectionState();
  }

  /// Enters selection mode with [cardId] chosen — the long-press entry.
  void beginWith(String cardId) =>
      state = CardSelectionState(isSelecting: true, selectedIds: {cardId});

  /// Enters selection mode with nothing chosen — the visible `Select` action,
  /// for a user who does not know the gesture.
  void begin() => state = const CardSelectionState(isSelecting: true);

  /// Adds or removes one card. Deselecting the last one leaves the mode: a
  /// contextual bar with nothing to act on is chrome in the way.
  void toggle(String cardId) {
    final next = <String>{...state.selectedIds};
    if (!next.remove(cardId)) next.add(cardId);
    if (next.isEmpty) {
      state = const CardSelectionState();

      return;
    }

    state = state.copyWith(
      isSelecting: true,
      selectedIds: next,
      isAllMatching: false,
    );
  }

  void clear() => state = const CardSelectionState();

  /// Takes every card the live filter and search match — not just the loaded
  /// window (BR-167). The ids come from the same predicate the list and the
  /// count pills use, so "all" means what the screen is showing.
  Future<void> includeAllMatching() async {
    final ids = await ref.read(readCardIdsMatchingUseCaseProvider)(
      deckId,
      filter: ref.read(cardListFilterSelectionProvider(deckId)),
      searchTerm: ref.read(cardListSearchQueryProvider(deckId)),
      now: ref.read(cardListNowProvider),
    );
    if (!ref.mounted) return;

    state = CardSelectionState(
      isSelecting: true,
      selectedIds: ids.toSet(),
      isAllMatching: true,
    );
  }
}
