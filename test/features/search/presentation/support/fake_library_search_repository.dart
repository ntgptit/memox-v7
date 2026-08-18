import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_match_rank_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/domain/repositories/library_search_repository.dart';

/// One recorded call to the contract.
///
/// The list of these is what proves the empty-query rule: a controller test can
/// assert the repository was never *asked*, which no assertion on the rendered
/// result can do.
typedef SearchCall = ({
  SearchQuery query,
  LibrarySearchCursor after,
  int pageSize,
});

/// A stand-in for the search repository, driven by a function.
///
/// **Implements the domain contract, not a Drift seam.** A fake that mimicked
/// the DAO would let a controller test pass against SQL the repository never
/// writes; this one can only answer the questions the contract admits.
final class FakeLibrarySearchRepository implements LibrarySearchRepository {
  FakeLibrarySearchRepository(this._respond);

  /// Answers every page with [page], whatever was asked.
  factory FakeLibrarySearchRepository.serving(LibrarySearchPage page) =>
      FakeLibrarySearchRepository(
        (SearchQuery _, LibrarySearchCursor _, int _) =>
            Stream<LibrarySearchPage>.value(page),
      );

  /// Answers the first page from [first] and every later one from [next].
  factory FakeLibrarySearchRepository.paged({
    required LibrarySearchPage first,
    required LibrarySearchPage next,
  }) => FakeLibrarySearchRepository(
    (SearchQuery _, LibrarySearchCursor after, int _) =>
        Stream<LibrarySearchPage>.value(
          after == LibrarySearchCursor.start ? first : next,
        ),
  );

  /// Fails every page.
  factory FakeLibrarySearchRepository.failing([Failure? failure]) =>
      FakeLibrarySearchRepository(
        (SearchQuery _, LibrarySearchCursor _, int _) =>
            Stream<LibrarySearchPage>.error(
              failure ?? const DatabaseFailure(message: 'read failed'),
            ),
      );

  /// Fails only pages after the first, so the list stays on screen under a
  /// footer that says the next page did not arrive.
  factory FakeLibrarySearchRepository.failingAfter(LibrarySearchPage first) =>
      FakeLibrarySearchRepository(
        (SearchQuery _, LibrarySearchCursor after, int _) =>
            after == LibrarySearchCursor.start
            ? Stream<LibrarySearchPage>.value(first)
            : Stream<LibrarySearchPage>.error(
                const DatabaseFailure(message: 'page read failed'),
              ),
      );

  final Stream<LibrarySearchPage> Function(
    SearchQuery query,
    LibrarySearchCursor after,
    int pageSize,
  )
  _respond;

  /// Every call, in order. Empty is the assertion that matters most.
  final List<SearchCall> calls = <SearchCall>[];

  @override
  Stream<LibrarySearchPage> watchSearchPage({
    required SearchQuery query,
    required LibrarySearchCursor after,
    required int pageSize,
  }) {
    calls.add((query: query, after: after, pageSize: pageSize));

    return _respond(query, after, pageSize);
  }
}

/// A page built from bare parts, for tests whose subject is something else.
LibrarySearchPage fakeSearchPage({
  List<DeckSearchHit> decks = const <DeckSearchHit>[],
  List<CardSearchHit> cards = const <CardSearchHit>[],
  bool hasMore = false,
}) => LibrarySearchPage(
  decks: decks,
  cards: cards,
  cursor: LibrarySearchCursor(
    areDecksExhausted: true,
    areCardsExhausted: !hasMore,
    afterCard: hasMore ? SearchCursor.beforeFirst : null,
  ),
);

/// A deck hit from bare parts.
DeckSearchHit fakeDeckHit({
  String id = 'deck-1',
  String name = 'Nouns',
  List<String> path = const <String>['Korean', 'Grammar'],
  SearchMatchRank rank = SearchMatchRank.contains,
  bool isCardDeck = false,
}) => DeckSearchHit(
  deckId: id,
  name: name,
  deckPath: path,
  rank: rank,
  isCardDeck: isCardDeck,
);

/// A card hit from bare parts.
CardSearchHit fakeCardHit({
  String id = 'card-1',
  String deckId = 'deck-1',
  String front = 'noun',
  String back = 'danh từ',
  List<String> path = const <String>['Korean', 'Grammar', 'Nouns'],
  SearchMatchRank rank = SearchMatchRank.exact,
  String? matchedTagName,
}) => CardSearchHit(
  cardId: id,
  deckId: deckId,
  front: front,
  back: back,
  deckPath: path,
  rank: rank,
  matchedTagName: matchedTagName,
);
