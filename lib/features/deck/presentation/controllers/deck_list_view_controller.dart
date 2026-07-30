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
