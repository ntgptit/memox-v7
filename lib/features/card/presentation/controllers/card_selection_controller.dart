import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/card_use_case_provider.dart';
import '../states/card_selection_state.dart';
import 'card_list_filter_controller.dart';
import 'card_list_now_controller.dart';
import 'card_list_tag_filter_controller.dart';

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
      ..watch(cardListSortSelectionProvider(deckId))
      // The tag filter is a fourth narrowing and belongs in the same list
      // (BR-232): a selection built while two tags were on, then acted on with
      // them off, deletes rows the user never saw.
      ..watch(cardListTagFilterProvider(deckId));

    return const CardSelectionState();
  }

  /// Writes [next] and ticks when the *mode* changes.
  ///
  /// **On the transition, not on every write.** Entering and leaving selection
  /// swaps the whole bar at the top of the screen and changes what a tap on a
  /// row does; that is the change a finger should feel. Toggling one more card
  /// inside the mode does not — the row itself already shows it, and a tick per
  /// card turns a five-card selection into five buzzes.
  ///
  /// Every entry path goes through here, which is why it is here and not at the
  /// long-press: the mode is also entered from a visible `Select` action, and
  /// left by deselecting the last card as well as by `clear`.
  void _write(CardSelectionState next) {
    if (next.isSelecting != state.isSelecting) {
      unawaited(HapticFeedback.selectionClick());
    }
    state = next;
  }

  /// Enters selection mode with [cardId] chosen — the long-press entry.
  void beginWith(String cardId) =>
      _write(CardSelectionState(isSelecting: true, selectedIds: {cardId}));

  /// Enters selection mode with nothing chosen — the visible `Select` action,
  /// for a user who does not know the gesture.
  void begin() => _write(const CardSelectionState(isSelecting: true));

  /// Adds or removes one card. Deselecting the last one leaves the mode: a
  /// contextual bar with nothing to act on is chrome in the way.
  void toggle(String cardId) {
    final next = <String>{...state.selectedIds};
    if (!next.remove(cardId)) next.add(cardId);
    if (next.isEmpty) {
      _write(const CardSelectionState());

      return;
    }

    _write(
      state.copyWith(
        isSelecting: true,
        selectedIds: next,
        isAllMatching: false,
      ),
    );
  }

  void clear() => _write(const CardSelectionState());

  /// Takes every card the live filter and search match — not just the loaded
  /// window (BR-167). The ids come from the same predicate the list and the
  /// count pills use, so "all" means what the screen is showing.
  Future<void> includeAllMatching() async {
    final ids = await ref.read(readCardIdsMatchingUseCaseProvider)(
      deckId,
      filter: ref.read(cardListFilterSelectionProvider(deckId)),
      searchTerm: ref.read(cardListSearchQueryProvider(deckId)),
      now: ref.read(cardListNowProvider),
      tags: ref.read(cardListTagFilterProvider(deckId)),
    );
    if (!ref.mounted) return;

    state = CardSelectionState(
      isSelecting: true,
      selectedIds: ids.toSet(),
      isAllMatching: true,
    );
  }
}
