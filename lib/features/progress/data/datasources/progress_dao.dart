import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate, TableUpdateQuery;

import '../../../../core/database/app_database.dart';

/// Data access for Progress — three reads, and nothing else.
///
/// Receives an already-open [AppDatabase]; `core/database/connection.dart` is
/// the only place allowed to open one (AD-08). Every read delegates to a typed
/// statement in `queries/progress.drift`, so the card-day collapse, the
/// current-location join and the recursive subtree walk are all checked by
/// `drift_dev` at build time (AD-02).
///
/// **Three statements, one per shape of the question.** The overview collapses
/// the whole history into one row per active day and needs no deck at all; a
/// root's subtree is reachable through `root_deck_id` in a flat GROUP BY
/// (BR-56); a deeper level has no such column and has to be walked. Generalising
/// them would pay for the walk at the levels where it is not needed — the same
/// split `DeckDao` keeps between `watchRootDeckSummaries` and
/// `watchChildDeckLevel`.
///
/// **No write method exists, and that is the contract** (BR-190, BR-198).
/// Progress reads what studying produced; it never adds to it, which is how the
/// read-only guarantee is kept structurally rather than by review.
///
/// This class speaks Drift result rows. They stop here: the mapper turns them
/// into domain models and nothing above the repository sees one (AD-01).
final class ProgressDao {
  ProgressDao(this._db);

  /// How many ancestors a level's path walk climbs before it stops.
  ///
  /// Truncating is acceptable **here and nowhere else in this file**, because
  /// the result is a path and the mapper already treats a path as chrome: a
  /// level with a shortened path is a far better outcome than a level that never
  /// loads, while a truncated *count* would be a lie. BR-55 caps a real chain at
  /// 10 decks, so 10 steps reach the root of every legal tree — proven by the
  /// ten-level path test in `progress_activity_hierarchy_test.dart`, which is
  /// what stops this number from silently becoming too small.
  static const int ancestryWalkLimit = 10;

  final AppDatabase _db;

  /// Local days with activity, oldest first (BR-182).
  ///
  /// **Two update sources, and the second one is not optional.** The generated
  /// query declares `readsFrom: {studyAnswers}`, so drift re-runs it whenever a
  /// row is written *through* that table. Deleting a card — or a deck, which
  /// cascades to its cards — removes `study_answers` rows through a foreign key
  /// inside SQLite, which drift never sees: the write it is told about is on
  /// `cards` or `decks`. Without the second subscription the screen keeps
  /// showing a deleted card's history until something else happens to touch an
  /// answer, which BR-188 forbids and which no unit test on the query alone can
  /// catch.
  ///
  /// The shape is `CardDao.watchCardList`'s, for the same reason it exists
  /// there: one logical stream, two things that invalidate it.
  Stream<List<ProgressActivityDaysResult>> watchActivityDays({
    required Duration utcOffset,
  }) {
    final query = _db.progressActivityDays(utcOffset.inSeconds);

    return Stream<List<ProgressActivityDaysResult>>.multi((listener) {
      final subscriptions = <StreamSubscription<Object?>>[
        query.watch().listen(listener.add, onError: listener.addError),
        _db
            .tableUpdates(TableUpdateQuery.onAllTables([_db.cards, _db.decks]))
            .listen(
              (Set<TableUpdate> _) =>
                  query.get().then(listener.add).catchError(listener.addError),
              onError: listener.addError,
            ),
      ];
      listener.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

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
