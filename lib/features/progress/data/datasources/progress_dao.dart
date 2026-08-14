import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate, TableUpdateQuery;

import '../../../../core/database/app_database.dart';

/// Data access for Progress — one read, and nothing else.
///
/// Receives an already-open [AppDatabase]; `core/database/connection.dart` is
/// the only place allowed to open one (AD-08). There is no write method here at
/// all, which is how BR-190's read-only guarantee is kept structurally rather
/// than by review.
///
/// This class speaks Drift rows. They stop here: the repository maps them to
/// domain models and never lets one across (AD-01).
final class ProgressDao {
  ProgressDao(this._db);

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
}
