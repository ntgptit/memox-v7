import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_home_dao.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/domain/models/study_day_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';

import '../../../../database/support/test_database.dart';

/// A real SQLite database and the Study Home read wired to it.
///
/// **A real database, not a double.** Everything the files using this are about
/// is a property of the SQL: whether the workload reaches a card three levels
/// down, whether the due set is partitioned exactly at the local-day boundary,
/// whether a session from an earlier day is excluded, and whether the read
/// writes nothing. A fake would assert that the code calls the methods it was
/// written to call, which is the one thing nobody doubts.
///
/// Its own file because the guard caps a source file at 400 lines and the single
/// file these came from reached 751. Sharing the fixtures is also what keeps the
/// three from drifting into three slightly different databases.
final class StudyHomeDbHarness {
  StudyHomeDbHarness() {
    queryLog = <String>[];
    db = openTestDatabase(log: queryLog.add);
    repository = StudyHomeRepositoryImpl(StudyHomeDao(db));
  }

  /// Local midnight is `testNow`'s own day at UTC+0, so `startOfToday` is
  /// 2026-07-29 00:00Z and `now` is noon on it — a day with room on both sides
  /// of the boundary, which is what makes the partition constructible.
  static final StudyDayModel day = StudyDayModel(
    now: testNow,
    utcOffset: Duration.zero,
  );

  late final AppDatabase db;
  late final List<String> queryLog;
  late final StudyHomeRepositoryImpl repository;

  Future<StudyHomeModel> read() => repository.watchStudyHome(day).first;

  /// The SQL out of the interceptor's log lines.
  ///
  /// `QueryLogInterceptor` writes `123us  SELECT …  (2 rows)`; the assertions
  /// are about the statements, so the timing and the outcome are stripped here
  /// rather than being matched around at every call site.
  List<String> statements() => queryLog
      .map(
        (line) => line
            .replaceFirst(RegExp(r'^\d+us( SLOW)?\s+'), '')
            .replaceFirst(RegExp(r'\s+\([^()]*\)$'), ''),
      )
      .toList();

  /// A card that finished the chain and is due [before] the read instant.
  Future<void> seedDueCard(
    String id, {
    required String deckId,
    required Duration before,
  }) async {
    await insertCard(db, id: id, deckId: deckId);
    await insertReviewState(db, cardId: id, dueAt: testNow.subtract(before));
  }

  /// A card that has not finished the chain (BR-90): no schedule at all.
  Future<void> seedNewCard(String id, {required String deckId}) async {
    await insertCard(db, id: id, deckId: deckId);
    await insertReviewState(db, cardId: id);
  }

  Future<void> seedQueueItem(
    String sessionId,
    String cardId, {
    String mode = 'self_assess',
  }) => db.customInsert(
    'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
    "position, status) VALUES (?, ?, 1, ?, 0, 'pending')",
    variables: <Variable<Object>>[
      Variable<String>(sessionId),
      Variable<String>(mode),
      Variable<String>(cardId),
    ],
  );
}
