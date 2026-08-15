import 'package:drift/drift.dart' show Table, TableInfo;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

import '../../../database/support/test_database.dart';

/// What makes the Progress stream re-emit, and how much it costs (BR-199).
///
/// A separate file from `progress_repository_test.dart` because it opens its own
/// databases: some of these need a query log, and one needs a history large
/// enough that an N+1 read would be visible. Sharing a `setUp` database with the
/// semantic tests would mean two live `AppDatabase` instances per test, which
/// drift warns about for good reason.
void main() {
  final DateTime now = DateTime.utc(2026, 8, 12, 12);

  Future<void> seedDeck(AppDatabase db) async {
    await insertRootDeck(db, id: 'root');
    await insertSubDeck(
      db,
      id: 'sub',
      parentId: 'root',
      rootDeckId: 'root',
      contentType: 'card',
    );
    await insertSession(db, id: 'session', deckId: 'sub', rootDeckId: 'root');
  }

  group('the stream re-emits', () {
    test('when a new answer is written', () async {
      final db = openTestDatabase();
      await seedDeck(db);
      await insertCard(db, id: 'c1', deckId: 'sub');

      final emissions = <ProgressOverview>[];
      final subscription = ProgressRepositoryImpl(ProgressDao(db))
          .watchProgressOverview(now: now, utcOffset: Duration.zero)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await insertHistory(
        db,
        id: 'a1',
        cardId: 'c1',
        sessionId: 'session',
        answeredAt: now,
      );
      // The fixture writes with a bare `customInsert`, which tells drift
      // nothing. Production writes an answer through a generated statement,
      // which declares its updates and notifies; this line stands in for that
      // declaration rather than for the write. The cascade cases below need no
      // such help — and that asymmetry is exactly the trap the DAO's second
      // subscription exists for.
      db.markTablesUpdated(<TableInfo<Table, Object?>>{db.studyAnswers});
      await pumpEventQueue();

      expect(emissions, hasLength(greaterThanOrEqualTo(2)));
      expect(emissions.first.today.totalCards, 0);
      expect(emissions.last.today.totalCards, 1);
    });

    test('when a card is deleted, although the answers go by cascade', () async {
      // **The regression test for the DAO's second subscription.** The generated
      // query declares `readsFrom: {studyAnswers}`, and deleting a card removes
      // its answers *inside SQLite* through a foreign key — a write drift never
      // hears about, because what it was told about is `cards`. Without the
      // extra `tableUpdates` listener the screen keeps a deleted card's history
      // on it indefinitely, which BR-188 forbids, and no assertion on the query
      // alone can see it.
      final db = openTestDatabase();
      await seedDeck(db);
      await insertCard(db, id: 'c1', deckId: 'sub');
      await insertHistory(
        db,
        id: 'a1',
        cardId: 'c1',
        sessionId: 'session',
        answeredAt: now,
      );

      final emissions = <ProgressOverview>[];
      final subscription = ProgressRepositoryImpl(ProgressDao(db))
          .watchProgressOverview(now: now, utcOffset: Duration.zero)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emissions.last.today.totalCards, 1);

      await (db.delete(db.cards)..where((t) => t.id.equals('c1'))).go();
      await pumpEventQueue();

      expect(emissions.last.today.totalCards, 0);
    });

    test('when a deck is deleted two cascade hops away', () async {
      final db = openTestDatabase();
      await seedDeck(db);
      await insertCard(db, id: 'c1', deckId: 'sub');
      await insertHistory(
        db,
        id: 'a1',
        cardId: 'c1',
        sessionId: 'session',
        answeredAt: now,
      );

      final emissions = <ProgressOverview>[];
      final subscription = ProgressRepositoryImpl(ProgressDao(db))
          .watchProgressOverview(now: now, utcOffset: Duration.zero)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emissions.last.hasLifetimeActivity, isTrue);

      await (db.delete(db.decks)..where((t) => t.id.equals('root'))).go();
      await pumpEventQueue();

      expect(emissions.last.hasLifetimeActivity, isFalse);
    });
  });

  group('what one emission costs', () {
    test('is one statement, whatever the history size', () async {
      // Invisible in the result: a repository issuing one query per day of the
      // window would return exactly the same snapshot. Only the statement count
      // tells them apart, and a seven-day window is precisely the shape that
      // invites an N+1.
      final statements = <String>[];
      final db = openTestDatabase(log: statements.add);
      await _seedHistory(db, now: now, days: 30, cardsPerDay: 4);

      statements.clear();
      await ProgressRepositoryImpl(
        ProgressDao(db),
      ).watchProgressOverview(now: now, utcOffset: Duration.zero).first;

      expect(
        statements.where((sql) => sql.toUpperCase().contains('CARD_DAYS')),
        hasLength(1),
      );
      expect(
        statements.where(
          (sql) => RegExp(
            r'\b(INSERT|UPDATE|DELETE)\b',
            caseSensitive: false,
          ).hasMatch(sql),
        ),
        isEmpty,
        reason: 'BR-190: reading progress must write nothing',
      );
    });

    test('scans study_answers once and builds no index at read time', () async {
      // `EXPLAIN QUERY PLAN`, recorded rather than asserted line by line: the
      // plan text is SQLite's and changes between versions. What is pinned is
      // the two things a regression would change — the table is visited once,
      // and SQLite is not compensating for a missing index with an
      // `AUTOMATIC COVERING INDEX`, which is its way of saying the schema is
      // wrong for the query.
      final db = openTestDatabase();
      await _seedHistory(db, now: now, days: 30, cardsPerDay: 4);

      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN '
            'WITH shifted (localSeconds, cardId, kind) AS ('
            '  SELECT CAST(a.answered_at AS INT) + (0 | 0), a.card_id, a.kind '
            '  FROM study_answers a'
            '), card_days (localDayStart, cardId, hasLearning) AS ('
            '  SELECT s.localSeconds - (s.localSeconds % 86400), s.cardId, '
            '  MAX(CASE WHEN s.kind = \'learning\' THEN 1 ELSE 0 END) '
            '  FROM shifted s GROUP BY 1, 2'
            ') SELECT cd.localDayStart, COUNT(*), COALESCE(SUM(cd.hasLearning), 0) '
            'FROM card_days cd GROUP BY cd.localDayStart '
            'ORDER BY cd.localDayStart ASC',
          )
          .get();
      final detail = plan
          .map((row) => row.read<String>('detail'))
          .join(' | ')
          .toUpperCase();

      // `SCAN A` is the `study_answers a` of the query — SQLite names the
      // alias. Two scans in total, one per grouping level, and no third: an
      // N+1 or a correlated subquery would add one per day.
      expect(detail, contains('SCAN A'));
      expect('SCAN '.allMatches(detail), hasLength(2));
      // SQLite builds an `AUTOMATIC COVERING INDEX` when it decides the schema
      // is wrong for the query and it is cheaper to index than to re-scan. Its
      // absence is the measurable form of "no index is needed here"; the two
      // `USE TEMP B-TREE FOR GROUP BY` steps are the sort this design pays
      // instead, and they are the number to re-measure before ever adding one.
      expect(detail, isNot(contains('AUTOMATIC COVERING INDEX')));
    });
  });
}

/// A history of [days] days, [cardsPerDay] distinct cards each, two answers per
/// card — enough that an N+1 read would show up as thirty statements.
Future<void> _seedHistory(
  AppDatabase db, {
  required DateTime now,
  required int days,
  required int cardsPerDay,
}) async {
  await insertRootDeck(db, id: 'root');
  await insertSubDeck(
    db,
    id: 'sub',
    parentId: 'root',
    rootDeckId: 'root',
    contentType: 'card',
  );
  await insertSession(db, id: 'session', deckId: 'sub', rootDeckId: 'root');

  int answerId = 0;
  for (int day = 0; day < days; day++) {
    for (int card = 0; card < cardsPerDay; card++) {
      final id = 'c-$day-$card';
      await insertCard(db, id: id, deckId: 'sub');
      for (int turn = 0; turn < 2; turn++) {
        await insertHistory(
          db,
          id: 'a-${answerId++}',
          cardId: id,
          sessionId: 'session',
          answeredAt: now.subtract(Duration(days: day, minutes: turn)),
        );
      }
    }
  }
}
