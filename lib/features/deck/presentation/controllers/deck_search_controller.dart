import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/deck_search_result_model.dart';
import '../providers/deck_use_case_provider.dart';

part 'deck_search_controller.g.dart';

/// What the user has typed into the search field of one level.
///
/// An input-state notifier, the same kind as the filter and sort choices: a
/// value the UI owns that a view is parameterized by. Keyed by level, so walking
/// into a deck starts a new search rather than carrying the previous query into
/// a scope the user has already left.
@riverpod
class DeckSearchQuery extends _$DeckSearchQuery {
  @override
  String build(String? parentDeckId) => '';

  /// One mutator, deliberately. Clearing is `update('')` — a second method for
  /// it would be the shape `command_query_separation_test.dart` refuses, and it
  /// refuses it correctly: a notifier with two setters is the shape that grows a
  /// third.
  void update(String query) => state = query;
}

/// The matches for that query, or an empty list when nothing has been typed.
///
/// Automatic retry is off for the same reason the deck list turns it off: while
/// Riverpod retries, the state is `AsyncLoading`, and a failed local read would
/// spin instead of showing what went wrong.
@Riverpod(retry: noAutomaticRetry)
Stream<List<DeckSearchResult>> deckSearchResults(
  Ref ref,
  String? parentDeckId,
) {
  return ref.watch(searchDecksUseCaseProvider)(
    query: ref.watch(deckSearchQueryProvider(parentDeckId)),
    parentDeckId: parentDeckId,
  );
}
