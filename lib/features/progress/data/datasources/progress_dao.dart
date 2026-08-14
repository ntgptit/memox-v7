import '../../../../core/database/app_database.dart';

/// Data access for Progress by Deck.
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Both reads delegate to the typed
/// statements in `queries/progress.drift`, so the card-day collapse, the
/// current-location join and the recursive subtree walk are all checked by
/// `drift_dev` at build time (AD-02).
///
/// **Two statements, one per shape of the question**, exactly as `DeckDao` keeps
/// `watchRootDeckSummaries` and `watchChildDeckLevel` apart: a root's subtree is
/// reachable through `root_deck_id` in a flat GROUP BY (BR-56), while a deeper
/// level has no such column and has to be walked. Generalising them would pay for
/// the walk at the level where it is not needed.
///
/// **No write method exists, and that is the contract** (BR-188). Progress reads
/// what studying produced; it never adds to it.
///
/// This class speaks Drift result rows. They stop here: the mapper turns them
/// into domain models and nothing above the repository sees one (AD-01).
final class ProgressDao {
  ProgressDao(this._db);

  final AppDatabase _db;

  /// How many parent links the ancestry walk may follow before it stops.
  ///
  /// **A bound, not a page size.** The walk carries a `distance` that increases
  /// every lap, so `UNION` cannot deduplicate it: on a cyclic parent chain —
  /// corrupt data, which invariants exist to catch and not to survive — the
  /// statement would never return, and it holds the database isolate while it
  /// does not. The bound turns that into a short path.
  ///
  /// Truncating is acceptable **here and nowhere else in this file**, because
  /// the result is a path and the mapper already treats a path as chrome: a
  /// level with a shortened path is a far better outcome than a level that never
  /// loads, while a truncated *count* would be a lie. BR-55 caps a real chain at
  /// 10 decks, so 10 steps reach the root of every legal tree — proven by the
  /// ten-level path test in `progress_activity_hierarchy_test.dart`, which is
  /// what stops this number from silently becoming too small.
  static const int ancestryWalkLimit = 10;

  /// Every root deck's whole-subtree activity, plus the totals across every
  /// deck there is.
  ///
  /// [windowFrom] is the first local midnight of the 30-day window and is both
  /// the lower bound and the day-bucket origin — see the statement's comment for
  /// why those must be one parameter. [recentFrom] is the first local midnight
  /// of the 7-day window, and [windowUntil] the next local midnight after today,
  /// so an answer graded a second ago is already inside the window.
  Stream<List<RootDeckActivityResult>> watchRootDeckActivity({
    required DateTime windowFrom,
    required DateTime recentFrom,
    required DateTime windowUntil,
  }) => _db.rootDeckActivity(windowFrom, recentFrom, windowUntil).watch();

  /// One deck's own totals and each direct child's whole-subtree activity.
  ///
  /// A `LEFT JOIN` on the children, so a deck with no sub-decks still yields one
  /// row: no rows at all means the deck itself is gone, which the repository
  /// turns into a `NotFoundFailure`.
  Stream<List<ChildDeckActivityResult>> watchChildDeckActivity({
    required String parentDeckId,
    required DateTime windowFrom,
    required DateTime recentFrom,
    required DateTime windowUntil,
  }) => _db
      .childDeckActivity(
        windowFrom,
        recentFrom,
        windowUntil,
        parentDeckId,
        ancestryWalkLimit,
      )
      .watch();
}
