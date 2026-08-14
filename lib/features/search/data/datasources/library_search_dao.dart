import 'package:drift/drift.dart' show TableUpdate, TableUpdateQuery;

import '../../../../core/database/app_database.dart';

/// Data access for Global Library Search.
///
/// Receives the same already-open [AppDatabase] the rest of the app uses — one
/// opener (AD-08), one database. This class speaks Drift rows; they stop here,
/// and the repository maps them to domain values (AD-01).
///
/// **Not `final`, and the exception is narrow.** The repository's ordering
/// guard — only the newest read may emit — cannot be exercised through a real
/// database, because nothing there lets two reads complete in the reverse order
/// they started. `search_read_ordering_test.dart` subclasses this to control
/// that, and it is the only subclass; production still builds it from an
/// `AppDatabase` and nothing else.
class LibrarySearchDao {
  LibrarySearchDao(this._db);

  final AppDatabase _db;

  /// Runs [action] as one read transaction, so the deck set and the card page
  /// come from a single instant (AD-13).
  ///
  /// **Without it the two halves are two snapshots.** A rename landing between
  /// them would put the new name in the deck section and the old one inside a
  /// card's path, on the same frame, and nothing would look wrong enough to
  /// report.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  /// Every deck, ordered so a tree can be rebuilt from it.
  ///
  /// **The same statement the move-target picker reads, deliberately.** A deck
  /// tree is capped at ten levels (BR-55) and lives on the device, so the set is
  /// bounded by construction; matching names and building the path of every hit
  /// — deck hits *and* card hits — from this one read is what keeps the paths a
  /// single statement rather than one per row.
  Future<List<Deck>> allDecks() => _db.allDecks().get();

  /// One page of card matches, ranked and keyset-bounded by `search.drift`.
  ///
  /// [limit] is asked one larger than the page by the caller, so "is there
  /// another page?" is answered by this read rather than by a second count that
  /// could disagree with it.
  Future<List<SearchCardRow>> searchCardPage({
    required String folded,
    required int afterTier,
    required String afterKey,
    required DateTime afterCreatedAt,
    required String afterId,
    required int limit,
  }) => _db
      .searchCardPage(
        folded,
        afterTier,
        afterKey,
        afterCreatedAt,
        afterId,
        limit,
      )
      .get();

  /// Fires whenever anything a result row shows could have changed.
  ///
  /// **Hand-written rather than left to the generated `readsFrom`, and `decks`
  /// is the reason.** The card statement reads `cards`, `card_tags` and `tags`,
  /// so drift invalidates it correctly on those — but a result row also renders
  /// a *path*, which comes from the deck read beside it. Renaming an ancestor,
  /// or moving a card's deck, changes only `decks`, so a watch built from the
  /// card query alone would leave a stale path on screen with nothing to
  /// correct it (BR-189).
  Stream<Set<TableUpdate>> onLibraryChanged() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([
      _db.decks,
      _db.cards,
      _db.cardTags,
      _db.tags,
    ]),
  );
}
