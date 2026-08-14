import 'package:drift/drift.dart' show Table, TableInfo;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

import '../../../database/support/test_database.dart';

/// Progress against real SQLite (UC-12, BR-182…BR-190).
///
/// **Not a mock, for the usual reason and one extra.** The usual reason is that
/// every rule under test is behaviour of SQLite — two levels of `GROUP BY`, the
/// `ON DELETE CASCADE` that makes a deleted card disappear from history, the
/// integer day arithmetic. The extra reason is the type pin in
/// `progress.drift`: bind the offset as a REAL and the day bucket comes back
/// fractional, which no assertion on a fake could ever see.
void main() {
  /// Midday, so a positive offset and a negative one both stay inside the same
  /// UTC day and the boundary cases below are the only ones being constructed.
  final DateTime now = DateTime.utc(2026, 8, 12, 12);

  late AppDatabase db;
  late ProgressRepositoryImpl repository;

  /// One card-bearing deck and one open session, which every history row needs.
  Future<void> seedDeck() async {
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

  Future<void> seedCard(String id) =>
      insertCard(db, id: id, deckId: 'sub').then((_) {});

  int answerId = 0;
  Future<void> answer(
    String cardId, {
    required DateTime at,
    String kind = 'scheduled',
  }) => insertHistory(
    db,
    id: 'answer-${answerId++}',
    cardId: cardId,
    sessionId: 'session',
    kind: kind,
    answeredAt: at,
  );

  Future<ProgressOverview> read({Duration offset = Duration.zero}) =>
      repository.watchProgressOverview(now: now, utcOffset: offset).first;

  setUp(() async {
    answerId = 0;
    db = openTestDatabase();
    repository = ProgressRepositoryImpl(ProgressDao(db));
    await seedDeck();
  });

  group('the activity unit is a card-day', () {
    test('the same card answered many times in a day counts once', () async {
      // The bug this catches is counting `study_answers` rows. A learning
      // session walks five stages over one card, so a user who learned one card
      // would be told they studied five.
      await seedCard('c1');
      for (int turn = 0; turn < 5; turn++) {
        await answer(
          'c1',
          at: now.subtract(Duration(minutes: turn)),
          kind: 'learning',
        );
      }

      final overview = await read();

      expect(overview.today.totalCards, 1);
      expect(overview.today.learningCards, 1);
    });

    test('the same card answered on two days counts twice', () async {
      await seedCard('c1');
      await answer('c1', at: now);
      await answer('c1', at: now.subtract(const Duration(days: 1)));

      final overview = await read();

      expect(overview.today.totalCards, 1);
      expect(overview.lastSevenDays[5].totalCards, 1);
      expect(overview.currentStreakDays, 2);
    });

    test('two cards on one day count two', () async {
      await seedCard('c1');
      await seedCard('c2');
      await answer('c1', at: now);
      await answer('c2', at: now);

      expect((await read()).today.totalCards, 2);
    });
  });

  group('the Learning / Reviewing partition (BR-185)', () {
    test('a card with any learning answer is Learning, not both', () async {
      // The card that decides the rule: finished off the learning chain in the
      // morning, reviewed in the evening. Counting it on both sides would make
      // the halves sum to more than the total, on a screen that says they add
      // up.
      await seedCard('c1');
      await answer(
        'c1',
        at: now.subtract(const Duration(hours: 6)),
        kind: 'learning',
      );
      await answer('c1', at: now);

      final today = (await read()).today;

      expect(today.totalCards, 1);
      expect(today.learningCards, 1);
      expect(today.reviewingCards, 0);
    });

    test('relearning counts as Reviewing', () async {
      await seedCard('c1');
      await answer('c1', at: now, kind: 'relearning');

      final today = (await read()).today;

      expect(today.learningCards, 0);
      expect(today.reviewingCards, 1);
    });

    test('mixed kinds across cards partition the day', () async {
      await seedCard('learn-only');
      await seedCard('review-only');
      await seedCard('both');
      await answer('learn-only', at: now, kind: 'learning');
      await answer('review-only', at: now);
      await answer('both', at: now, kind: 'learning');
      await answer('both', at: now, kind: 'relearning');

      final today = (await read()).today;

      expect(today.totalCards, 3);
      expect(today.learningCards, 2);
      expect(today.reviewingCards, 1);
      expect(today.learningCards + today.reviewingCards, today.totalCards);
    });
  });

  group('what does not create activity', () {
    test('browse writes no answer, so it changes nothing (BR-183)', () async {
      // There is nothing to insert, and that is the assertion: `browse` is
      // absent from `study_answers.mode`'s CHECK entirely (BR-111), so a
      // session that only browsed leaves the table — and Progress — untouched.
      await seedCard('c1');

      final overview = await read();

      expect(overview.hasLifetimeActivity, isFalse);
      expect(overview.currentStreakDays, 0);
    });

    test('a card deleted after the fact disappears from past days too '
        '(BR-188)', () async {
      await seedCard('c1');
      await seedCard('c2');
      await answer('c1', at: now.subtract(const Duration(days: 3)));
      await answer('c2', at: now.subtract(const Duration(days: 3)));
      expect((await read()).lastSevenDays[3].totalCards, 2);

      // Deleted through drift's API rather than `customStatement`, because
      // that is what production does and because the difference is the whole
      // point: a raw statement tells drift nothing, so its stream cache would
      // hand the next subscriber the pre-delete rows and this test would pass
      // while the screen showed a deleted card's history. `CardDao` deletes
      // through the same API.
      await (db.delete(db.cards)..where((t) => t.id.equals('c1'))).go();

      expect((await read()).lastSevenDays[3].totalCards, 1);
    });

    test('deleting the deck cascades all the way to history', () async {
      await seedCard('c1');
      await answer('c1', at: now);
      expect((await read()).hasLifetimeActivity, isTrue);

      await (db.delete(db.decks)..where((t) => t.id.equals('root'))).go();

      expect((await read()).hasLifetimeActivity, isFalse);
    });
  });

  test('reset keeps history, so it keeps every number (BR-188)', () async {
    // Reset drops and recreates `card_study_states` and bumps the generation.
    // `study_answers` is append-only and is deliberately not touched (BR-43),
    // so a user who resets a deck must not lose the streak they earned on it.
    await seedCard('c1');
    await answer('c1', at: now.subtract(const Duration(days: 1)));
    await answer('c1', at: now);
    final before = await read();

    await db.delete(db.cardStudyStates).go();
    await db.customUpdate(
      'UPDATE decks SET scheduler_generation = scheduler_generation + 1',
      updates: <TableInfo<Table, Object?>>{db.decks},
    );

    final after = await read();

    expect(after.currentStreakDays, before.currentStreakDays);
    expect(after.today.totalCards, before.today.totalCards);
    expect(
      after.lastSevenDays.map((day) => day.totalCards),
      before.lastSevenDays.map((day) => day.totalCards),
    );
  });

  group('the local day boundary', () {
    test(
      'an answer one second before local midnight belongs to today',
      () async {
        await seedCard('c1');
        // 2026-08-13 00:00 UTC+7 is 2026-08-12 17:00 UTC.
        await answer('c1', at: DateTime.utc(2026, 8, 12, 16, 59, 59));

        final overview = await read(offset: const Duration(hours: 7));

        expect(overview.today.totalCards, 1);
      },
    );

    test(
      'an answer at local midnight belongs to tomorrow, not today',
      () async {
        await seedCard('c1');
        await answer('c1', at: DateTime.utc(2026, 8, 12, 17));

        // The window ends at today, so an answer that has crossed into tomorrow
        // is in no visible day — which is right, and is what makes the interval
        // half-open (BR-184) rather than a matter of rounding.
        final overview = await read(offset: const Duration(hours: 7));

        expect(overview.today.totalCards, 0);
        expect(overview.hasLifetimeActivity, isTrue);
      },
    );

    test('a negative offset moves the boundary the other way', () async {
      await seedCard('c1');
      // 2026-08-12 00:00 UTC-5 is 2026-08-12 05:00 UTC; one second earlier is
      // still the 11th for that user.
      await answer('c1', at: DateTime.utc(2026, 8, 12, 4, 59, 59));

      final overview = await read(offset: const Duration(hours: -5));

      expect(overview.today.totalCards, 0);
      expect(overview.lastSevenDays[5].totalCards, 1);
    });
  });

  test('opening Progress writes nothing at all (BR-190)', () async {
    await seedCard('c1');
    await answer('c1', at: now);
    final before = await _rowCounts(db);

    await read();
    await read();

    expect(await _rowCounts(db), before);
  });

  test('the day bucket comes back as an integer', () async {
    // The regression guard for the `(:utcOffsetSeconds | 0)` type pin. Bound as
    // a REAL, the bucket is a fractional REAL and `row.read<int>` throws — so
    // this test fails loudly rather than returning a subtly wrong day.
    await seedCard('c1');
    await answer('c1', at: now);

    final rows = await db
        .progressActivityDays(const Duration(hours: 7).inSeconds)
        .get();

    expect(rows, hasLength(1));
    expect(rows.single.localDayStart, isA<int>());
    expect(rows.single.localDayStart % 86400, 0);
  });
}

/// Every table's row count, so "nothing was written" is checked against the
/// whole schema rather than the two tables somebody expected to be at risk.
Future<Map<String, int>> _rowCounts(AppDatabase db) async => <String, int>{
  for (final table in db.allTables)
    table.actualTableName: (await db.select(table).get()).length,
};
