import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// The Study tab's reads, and it has no writes at all.
///
/// **The absence is the design** (BR-182). `StudyDao` beside it is full of
/// inserts and updates because a session is written from the moment it opens;
/// this class holds two SELECTs and a change signal, so a screen wired to it
/// cannot create a session by being looked at. "Rendering Home writes nothing"
/// is then a property of the type rather than a rule somebody has to keep.
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Rows stop here: the mapper turns them
/// into domain models and no Drift type crosses (AD-01).
final class StudyHomeDao {
  StudyHomeDao(this._db);

  final AppDatabase _db;

  /// Every table whose change can move something on Study Home.
  ///
  /// The union of what the two queries read, stated once. Decks and cards move
  /// the workload, `card_study_states` moves it on every answer, and the two
  /// session tables move the Resume card — a session ending is the single most
  /// visible change this screen has, and leaving `study_sessions` out is how a
  /// finished session keeps offering to be continued.
  List<TableInfo<Table, Object?>> get _watchedTables =>
      <TableInfo<Table, Object?>>[
        _db.decks,
        _db.cards,
        _db.cardStudyStates,
        _db.studySessions,
        _db.studyQueueItems,
      ];

  /// Fires once immediately, then once per write touching [_watchedTables].
  ///
  /// **The signal is separate from the read on purpose.** Two `watch()` streams
  /// zipped together would each carry their own snapshot, and the pair could
  /// then describe two different instants — a Resume card from before a session
  /// ended beside a deck list from after it, which is exactly the disagreement
  /// AD-13 exists to prevent. One signal driving one transactional read cannot.
  ///
  /// The leading event is what makes it a *state* stream rather than an event
  /// stream: `tableUpdates` reports changes, and a screen that only learned
  /// about changes would render nothing until somebody wrote something.
  ///
  /// **The subscription is opened in `onListen`, before that leading event —
  /// and the order is the whole point.** Written as `async* { yield null;
  /// yield* _db.tableUpdates(…); }` it looked equivalent and was not:
  /// `tableUpdates` only attaches to drift's update bus when something listens
  /// to it, and an `async*` generator suspends at its first `yield` until the
  /// consumer asks for more. The consumer here is `asyncMap`, which pauses
  /// while it awaits the read — so the `yield*` line, and with it the
  /// subscription, did not run until the **first read had already finished**.
  /// Any write that committed inside that window was never reported: a session
  /// ended by another screen while Home was opening left the Resume card
  /// offering it, and the counts frozen, until the next unrelated write.
  ///
  /// A single-subscription controller, so an event arriving while `asyncMap` is
  /// paused is buffered rather than dropped — the behaviour after subscription
  /// was already correct and is preserved.
  Stream<void> watchChanges() {
    late final StreamController<void> controller;
    StreamSubscription<Set<TableUpdate>>? subscription;

    controller = StreamController<void>(
      onListen: () {
        subscription = _db
            .tableUpdates(TableUpdateQuery.onAllTables(_watchedTables))
            .listen(
              (_) => controller.add(null),
              // Forwarded, both of them. The `yield*` this replaced carried an
              // error through to the screen — where it becomes an error state
              // with a retry (BR-184) — and completed when the database closed.
              // Dropping either would make a failing update bus look like a
              // screen that had simply stopped hearing about writes.
              onError: controller.addError,
              onDone: controller.close,
            );

        // After the subscription exists, never before it.
        controller.add(null);
      },
      onCancel: () async {
        await subscription?.cancel();
        subscription = null;
        // **Guarded, and the guard is load-bearing.** Closed with the
        // subscription that fed it — a controller left open is a `Sink` nothing
        // ever completes — but `onDone` above *also* closes it, and the two
        // together deadlock without this check: `close()` from `onDone` creates
        // a real done-future, runs `_cancel()`, which runs this callback, which
        // awaits `close()` again and gets handed that same pending future — a
        // future that only completes once this callback does. The consumer then
        // never sees `done` either, so forwarding it silently achieved nothing
        // and cost a `cancel()` that never returns.
        //
        // No test reached it: every test cancels before the database closes, so
        // `close()` is never the first of the two. The `db.close()`-while-
        // subscribed case in `study_home_test.dart` is what covers it now.
        if (!controller.isClosed) await controller.close();
      },
    );

    return controller.stream;
  }

  /// Both reads, inside one transaction, so they describe one instant.
  ///
  /// A read-only transaction: nothing inside it writes, and running it is how
  /// the two statements are held to the same snapshot without merging them into
  /// one unreadable query.
  Future<
    ({
      List<StudyHomeRootWorkloadResult> decks,
      StudyHomeResumeCandidateResult? resume,
    })
  >
  readSnapshot({
    required DateTime now,
    required DateTime startOfToday,
    required DateTime dayStart,
  }) => _db.transaction(() async {
    final decks = await _db.studyHomeRootWorkload(now, startOfToday).get();
    final resume = await _db
        .studyHomeResumeCandidate(dayStart)
        .getSingleOrNull();

    return (decks: decks, resume: resume);
  });
}
