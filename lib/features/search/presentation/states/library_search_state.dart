import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/search_page_model.dart';
import '../../domain/models/search_query_model.dart';
import '../../domain/models/search_result_model.dart';

/// What the search surface is doing, as one closed set (AD-11).
///
/// **Not a pile of booleans.** `isLoading && hasResults && hasError` is eight
/// states of which four cannot happen, and the four that cannot are exactly the
/// ones a widget renders by accident. An enum makes the impossible ones
/// unspellable and the `switch` exhaustive.
///
/// [debouncing] is deliberately distinct from [loading]: nothing has been asked
/// of the database yet, so a spinner would describe work that is not happening.
/// Telling them apart here lets the UI choose to render them the same without
/// that choice being baked into the state.
enum LibrarySearchPhase {
  /// Nothing typed. No read has been made, and none will be (BR-249).
  initial,

  /// Typed, and the debounce window has not closed. No statement has run.
  debouncing,

  /// The first page of the settled query is in flight.
  loading,

  /// A page has arrived. It may still be empty — that is a result, not a
  /// failure.
  ready,

  /// The first page failed. Nothing is listed under the message: results from an
  /// older query left there would claim to answer the query in the field.
  failed,
}

/// Everything the search surface renders, in one immutable value.
///
/// **Data and task status are separate fields** (AD-11): [decks] and [cards] are
/// what is known, [phase] and [isLoadingMore] are what is happening. One
/// `isLoading` covering both is what makes a load-more erase the list it is
/// extending.
final class LibrarySearchState {
  const LibrarySearchState({
    required this.query,
    required this.decks,
    required this.cards,
    required this.phase,
    required this.hasMore,
    required this.isLoadingMore,
    this.error,
    this.pageError,
    this.retryPageIndex,
  });

  /// Before anything is typed, and again the moment the field is cleared.
  static const LibrarySearchState initial = LibrarySearchState(
    query: SearchQuery.empty,
    decks: <DeckSearchHit>[],
    cards: <CardSearchHit>[],
    phase: LibrarySearchPhase.initial,
    hasMore: false,
    isLoadingMore: false,
  );

  /// The settled, normalised query the results belong to. Not what is in the
  /// field — that is still being typed and belongs to the field.
  final SearchQuery query;

  final List<DeckSearchHit> decks;
  final List<CardSearchHit> cards;
  final LibrarySearchPhase phase;

  /// Whether a load-more affordance should be offered at all.
  final bool hasMore;

  /// A **next page** is in flight. Separate from [phase] on purpose: what is
  /// already listed stays, and only the footer changes.
  final bool isLoadingMore;

  /// The failure of the first page. Non-null exactly when [phase] is
  /// [LibrarySearchPhase.failed].
  final Object? error;

  /// The failure of a later page. Everything already found stays listed; only
  /// the footer offers the retry, because the missing part is the footer's.
  final Object? pageError;

  /// Which page a retry should re-read, or null when nothing failed.
  ///
  /// **The index rather than a callback**, so the state stays a value: a widget
  /// invalidates that one page and the chain below it re-reads itself, which is
  /// the same retry idiom the deck list already uses.
  final int? retryPageIndex;

  bool get hasResults => decks.isNotEmpty || cards.isNotEmpty;

  /// A finished search that found nothing — distinct from [initial], where
  /// nothing was asked.
  bool get hasNoResults => phase == LibrarySearchPhase.ready && !hasResults;
}

/// Flattens every open page into the one value the screen renders.
///
/// **De-duplicated by id, and that is structural rather than defensive.** Each
/// page re-emits when the library changes, so a delete inside page 1 can pull a
/// row that page 2 already holds up into page 1. The keyset stops a *page* from
/// repeating a row; only this stops two live pages from overlapping across a
/// write between them.
///
/// **A pure function over the pages, not a provider body.** It takes what the
/// providers resolved to and returns a value, so every rule below — which
/// failure clears the list, which one only changes the footer, when a reload
/// counts as loading-more — is assertable without a container.
LibrarySearchState foldSearchPages({
  required SearchQuery query,
  required List<AsyncValue<LibrarySearchPage>> pages,
}) {
  final decks = <DeckSearchHit>[];
  final seenDecks = <String>{};
  final cards = <CardSearchHit>[];
  final seenCards = <String>{};

  var phase = LibrarySearchPhase.ready;
  var hasMore = false;
  var isLoadingMore = false;
  Object? pageError;
  int? retryPageIndex;

  for (var index = 0; index < pages.length; index++) {
    final AsyncValue<LibrarySearchPage> slot = pages[index];

    if (slot.hasError) {
      // The first page failing empties the list; a later page failing does not.
      // Results under "could not search" would claim to answer the query in the
      // field; results above "could not load more" are exactly what was found.
      if (index == 0) {
        return LibrarySearchState(
          query: query,
          decks: const <DeckSearchHit>[],
          cards: const <CardSearchHit>[],
          phase: LibrarySearchPhase.failed,
          hasMore: false,
          isLoadingMore: false,
          error: slot.error,
          retryPageIndex: 0,
        );
      }
      pageError = slot.error;
      retryPageIndex = index;
      break;
    }

    final LibrarySearchPage? page = slot.value;
    if (slot.isLoading) {
      // Riverpod keeps the previous value while re-reading, which is what keeps
      // the list on screen instead of blanking it between two queries.
      if (index == 0) phase = LibrarySearchPhase.loading;
      if (index > 0) isLoadingMore = true;
    }
    if (page == null) break;

    for (final DeckSearchHit deck in page.decks) {
      if (seenDecks.add(deck.id)) decks.add(deck);
    }
    for (final CardSearchHit card in page.cards) {
      if (seenCards.add(card.id)) cards.add(card);
    }
    // The newest page decides: an earlier one saying "there is more" was
    // answering about a boundary the later page has already crossed.
    hasMore = page.hasMore;
  }

  return LibrarySearchState(
    query: query,
    decks: List<DeckSearchHit>.unmodifiable(decks),
    cards: List<CardSearchHit>.unmodifiable(cards),
    phase: phase,
    hasMore: hasMore && pageError == null,
    isLoadingMore: isLoadingMore,
    pageError: pageError,
    retryPageIndex: retryPageIndex,
  );
}
