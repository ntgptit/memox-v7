import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate;

import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../domain/models/deck_search_ranking_model.dart';
import '../../domain/models/search_cursor_model.dart';
import '../../domain/models/search_page_model.dart';
import '../../domain/models/search_query_model.dart';
import '../../domain/models/search_result_model.dart';
import '../../domain/repositories/library_search_repository.dart';
import '../datasources/library_search_dao.dart';
import '../mappers/library_search_mapper.dart';

/// Global Library Search over the local database (UC-12).
///
/// **Two reads per emission and never one per row.** The deck set is read whole
/// — bounded by BR-55's ten levels and already streamed that way for the
/// move-target picker — and every path on the page, a card's included, is
/// derived from it. The card page is one keyset-bounded statement. So a page of
/// fifty results costs two statements, not fifty-one.
///
/// **The watch is hand-built rather than a `.watch()` on one query.** A result
/// row renders text from `cards`, a tag name from `tags` and a *path* from
/// `decks`, and no single generated `readsFrom` covers all three — a rename of
/// an ancestor touches only `decks`, so a card-query watch would leave the stale
/// path on screen with nothing to correct it (BR-189).
final class LibrarySearchRepositoryImpl implements LibrarySearchRepository {
  LibrarySearchRepositoryImpl(AppDatabase database)
    : _dao = LibrarySearchDao(database);

  /// For tests that want to drive the DAO seam directly.
  LibrarySearchRepositoryImpl.withDao(this._dao);

  final LibrarySearchDao _dao;

  @override
  Stream<LibrarySearchPage> watchSearchPage({
    required SearchQuery query,
    required LibrarySearchCursor after,
    required int pageSize,
  }) {
    // BR-184. Not a shortcut for speed: an empty query must open **no**
    // statement, so the guard is above the DAO rather than inside the read.
    if (query.isEmpty) {
      return Stream<LibrarySearchPage>.value(LibrarySearchPage.empty);
    }

    return Stream<LibrarySearchPage>.multi((
      MultiStreamController<LibrarySearchPage> listener,
    ) {
      var isCancelled = false;
      // Table updates can land faster than a read completes, and a read that
      // started earlier may finish later. Only the newest one may emit —
      // otherwise the list flickers back to a snapshot the database has already
      // moved past.
      var generation = 0;

      Future<void> push() async {
        final int mine = ++generation;
        try {
          final LibrarySearchPage page = await _readPage(
            query: query,
            after: after,
            pageSize: pageSize,
          );
          if (isCancelled || mine != generation) return;
          listener.add(page);
        } on Object catch (error, stackTrace) {
          if (isCancelled || mine != generation) return;
          listener.addError(mapDatabaseError(error), stackTrace);
        }
      }

      final StreamSubscription<Set<TableUpdate>> subscription = _dao
          .onLibraryChanged()
          .listen(
            (Set<TableUpdate> _) => push(),
            onError: (Object error, StackTrace stackTrace) =>
                listener.addError(mapDatabaseError(error), stackTrace),
          );

      // `tableUpdates` reports changes only, so the first value has to be
      // asked for. Unawaited on purpose: the listener is fed from inside
      // `push`, and awaiting here would block the subscription being returned.
      unawaited(push());

      listener.onCancel = () async {
        isCancelled = true;
        await subscription.cancel();
      };
    });
  }

  /// One page, from one instant.
  ///
  /// **Decks are walked to exhaustion before the first card appears** (BR-186).
  /// The page is filled with deck matches and topped up with card matches only
  /// once the deck group has nothing left, so the two sections never interleave
  /// and a load-more can never insert a deck below a card.
  Future<LibrarySearchPage> _readPage({
    required SearchQuery query,
    required LibrarySearchCursor after,
    required int pageSize,
  }) => _dao.runInTransaction(() async {
    final List<SearchableDeck> decks = toSearchableDecks(await _dao.allDecks());
    final Map<String, SearchableDeck> byId = <String, SearchableDeck>{
      for (final SearchableDeck deck in decks) deck.id: deck,
    };

    var deckHits = const <DeckSearchHit>[];
    SearchCursor? nextDeckCursor = after.afterDeck;
    var areDecksExhausted = after.areDecksExhausted;
    var remaining = pageSize;

    if (!areDecksExhausted) {
      final DeckPage page = rankDeckMatches(
        decks: decks,
        query: query,
        after: after.afterDeck,
        limit: remaining,
      );
      deckHits = <DeckSearchHit>[
        for (final RankedDeck each in page.ranked) each.hit,
      ];
      if (page.ranked.isNotEmpty) nextDeckCursor = page.ranked.last.cursor;
      areDecksExhausted = page.isExhausted;
      remaining -= deckHits.length;
    }

    final cardHits = <CardSearchHit>[];
    SearchCursor? nextCardCursor = after.afterCard;
    var areCardsExhausted = after.areCardsExhausted;

    if (areDecksExhausted && !areCardsExhausted && remaining > 0) {
      final SearchCursor from = after.afterCard ?? SearchCursor.beforeFirst;
      // One more than the window, so "is there another page?" comes from this
      // read rather than from a count that could disagree with it.
      final List<SearchCardRow> rows = await _dao.searchCardPage(
        folded: query.folded,
        afterTier: from.rankTier,
        afterKey: from.sortKey,
        afterCreatedAt: from.createdAt,
        afterId: from.id,
        limit: remaining + 1,
      );
      final bool hasMoreCards = rows.length > remaining;
      final List<SearchCardRow> window = hasMoreCards
          ? rows.sublist(0, remaining)
          : rows;
      for (final SearchCardRow row in window) {
        final mapped = toCardHit(row, byId);
        if (mapped == null) continue;
        cardHits.add(mapped.hit);
        nextCardCursor = mapped.cursor;
      }
      areCardsExhausted = !hasMoreCards;
    }

    return LibrarySearchPage(
      decks: deckHits,
      cards: cardHits,
      cursor: LibrarySearchCursor(
        afterDeck: nextDeckCursor,
        afterCard: nextCardCursor,
        areDecksExhausted: areDecksExhausted,
        areCardsExhausted: areCardsExhausted,
      ),
    );
  });
}
