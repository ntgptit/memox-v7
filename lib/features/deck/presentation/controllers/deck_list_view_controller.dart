import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../states/deck_list_view_state.dart';

part 'deck_list_view_controller.g.dart';

/// Which decks the root list is showing.
///
/// An input-state notifier, the same kind as `DeckListNow`: a value the UI owns
/// that a view is parameterized by. Neither a query of the data layer nor a
/// command against it — switching the filter reads nothing and writes nothing, it
/// changes which rows of an already-loaded snapshot are on screen.
///
/// **Its own notifier rather than a field on a shared one.** Filter and sort are
/// independent choices, and one notifier holding both would need two mutators —
/// which `command_query_separation_test.dart` refuses, correctly: a notifier with
/// two setters is the shape that grows a third.
@riverpod
class DeckListFilterChoice extends _$DeckListFilterChoice {
  @override
  DeckListFilter build() => DeckListFilter.all;

  void select(DeckListFilter filter) => state = filter;
}

/// The order the root list is shown in.
///
/// Defaults to [DeckListSort.recent], which is the order the repository already
/// returns — so the first frame after this was introduced looks exactly like the
/// last frame before it, and the toolbar starts by describing what is on screen
/// rather than changing it.
@riverpod
class DeckListSortChoice extends _$DeckListSortChoice {
  @override
  DeckListSort build() => DeckListSort.recent;

  void select(DeckListSort sort) => state = sort;
}

/// Whether the level summary panel is showing.
///
/// The third input-state notifier beside filter and sort, and the same kind of
/// value: something the UI owns that a view is parameterized by, reading nothing
/// and writing nothing.
///
/// **Not keyed by level, deliberately.** The reason the design gives for making
/// the panel dismissible is a mood rather than a place — on a day spent
/// reorganising decks it is in the way of the list it sits on top of — and a
/// user who dismisses it at the root and finds it back two taps later has not
/// been listened to. Filter and sort are global for the same reason.
///
/// Defaults to [DeckSummaryVisibility.auto] rather than to showing. The old
/// default put the panel on screen on every level including the ones with
/// nothing due, where it existed only to be dismissed. `auto` is still a global
/// choice — what it follows is local, which is the point: the same preference
/// produces a panel on the level that has work waiting and none on the level
/// that does not.
///
/// One mutator, so a caller says which state it wants rather than toggling —
/// the close button and the link that brings it back both know their answer, and
/// both are saying "from now on", which is why neither can return to `auto`.
@riverpod
class DeckSummaryVisibilityChoice extends _$DeckSummaryVisibilityChoice {
  @override
  DeckSummaryVisibility build() => DeckSummaryVisibility.auto;

  void setVisible({required bool isVisible}) => state = isVisible
      ? DeckSummaryVisibility.shown
      : DeckSummaryVisibility.hidden;
}
