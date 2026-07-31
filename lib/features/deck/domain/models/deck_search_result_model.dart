import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';

part 'deck_search_result_model.freezed.dart';

/// One deck that matched a search, with the path that leads to it.
///
/// **The path is the whole point.** In a tree ten levels deep three sub-decks
/// can all be called "Nouns", and a result list of bare names is a list of
/// identical rows the user has to open one at a time to tell apart.
@freezed
abstract class DeckSearchResult with _$DeckSearchResult {
  const factory DeckSearchResult({
    required DeckEntity deck,

    /// Ancestor names, top of the tree first, excluding the deck itself.
    ///
    /// Names rather than entities: the row renders them and nothing navigates
    /// to a step of the trail — tapping a result goes to the deck, not to one
    /// of its parents.
    required List<String> ancestorNames,
  }) = _DeckSearchResult;

  const DeckSearchResult._();

  /// How deep the match sits below the scope that was searched.
  ///
  /// Drives the ordering: a deck whose own name matches outranks one buried six
  /// levels further down, because the shallower one is more likely to be the
  /// thing the user had in mind.
  int get depth => ancestorNames.length;
}
