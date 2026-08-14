import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminder/data/datasources/reminder_dao.dart';
import 'package:memox/features/reminder/data/repositories/reminder_settings_repository_impl.dart';
import 'package:memox/features/reminder/data/repositories/reminder_workload_repository_impl.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';

import '../../../database/support/test_database.dart';
import '../../../helpers/fixtures/study_fixtures.dart';

/// The two database-backed halves, on a real SQLite file built by the
/// production schema.
///
/// **Not a mocked DAO.** BR-188's "counted exactly once" is a property of a
/// `GROUP BY` over a join; a fake would agree with whatever the test author
/// believed the query did, which is the belief under test.
void main() {
  late AppDatabase db;
  late ReminderDao dao;

  // A local day that starts well away from the UTC one, so an implementation
  // that quietly used UTC midnight would split overdue from due-today in the
  // wrong place and be caught here.
  const offset = Duration(hours: 7);
  // 2026-07-29 19:00 local.
  final now = DateTime.utc(2026, 7, 29, 12);
  // 2026-07-29 00:00 local.
  final dayStart = DateTime.utc(2026, 7, 28, 17);

  setUp(() {
    db = openTestDatabase();
    dao = ReminderDao(db);
  });

  tearDown(() => db.close());

  group('settings (BR-182, BR-183)', () {
    ReminderSettingsRepositoryImpl repository() =>
        ReminderSettingsRepositoryImpl(dao, clock: () => now);

    test('a fresh database reads as off at 20:00', () async {
      final settings = await repository().readSettings();

      expect(settings.isEnabled, isFalse);
      expect(settings.time, ReminderTime.suggested);
    });

    test('both columns are written together and read back', () async {
      final nine = ReminderTime.parse(9 * 60).time!;

      await repository().saveSettings(isEnabled: true, time: nine);
      final settings = await repository().readSettings();

      expect(settings.isEnabled, isTrue);
      expect(settings.time, nine);
    });

    test('the write stamps updated_at from the injected clock', () async {
      await repository().saveSettings(
        isEnabled: true,
        time: ReminderTime.suggested,
      );

      final row = await dao.readSettingsRow();
      // `isAtSameMomentAs`, not `equals`: drift stores a DATETIME as unix
      // seconds and hands it back in the host's zone, so the two values are the
      // same instant written two ways.
      expect(row.updatedAt.isAtSameMomentAs(now), isTrue);
    });

    test('the stream re-emits after a write', () async {
      final repo = repository();
      final seen = <bool>[];
      final subscription = repo.watchSettings().listen(
        (settings) => seen.add(settings.isEnabled),
      );
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await repo.saveSettings(isEnabled: true, time: ReminderTime.suggested);
      await pumpEventQueue();

      expect(seen, <bool>[false, true]);
    });

    test('a read that cannot reach the database is a typed failure', () async {
      // The controllers catch `on Failure`. An unmapped throw from the read
      // escaped through `unawaited`, left the command at `isSubmitting: true`
      // for good, and locked the screen with no banner to explain it (AD-01).
      final repo = repository();
      // The one-row table with no row: `getSingle()` throws a raw `StateError`,
      // which is exactly the shape that used to escape unmapped.
      await db.customStatement('DELETE FROM app_settings');

      await expectLater(repo.readSettings(), throwsA(isA<Failure>()));
    });

    test('the study columns are untouched by a reminder write', () async {
      // One table, two features. A reminder write that moved `card_limit`
      // would change how sessions are built, silently.
      final before = await dao.readSettingsRow();

      await repository().saveSettings(
        isEnabled: true,
        time: ReminderTime.suggested,
      );

      final after = await dao.readSettingsRow();
      expect(after.cardLimit, before.cardLimit);
      expect(after.newCardOrder, before.newCardOrder);
    });
  });

  group('workload (BR-184, BR-188)', () {
    ReminderWorkloadRepositoryImpl repository() =>
        ReminderWorkloadRepositoryImpl(dao);

    test('an empty library owes nothing', () async {
      final workload = await repository().readWorkload(
        now: now,
        utcOffset: offset,
      );

      expect(workload, isEmpty);
    });

    test('unlearned cards never appear (BR-184)', () async {
      final fixture = await deckWithCards(db, cardCount: 3);
      for (final cardId in fixture.cardIds) {
        await insertReviewState(db, cardId: cardId);
      }

      final workload = await repository().readWorkload(
        now: now,
        utcOffset: offset,
      );

      expect(workload, isEmpty);
    });

    test('cards due after now are not owed yet', () async {
      final fixture = await deckWithCards(db, cardCount: 2);
      await makeLearned(
        db,
        fixture.cardIds,
        dueAt: now.add(const Duration(hours: 1)),
      );

      final workload = await repository().readWorkload(
        now: now,
        utcOffset: offset,
      );

      expect(workload, isEmpty);
    });

    test('overdue and due-today are split at the local day start', () async {
      final fixture = await deckWithCards(db, cardCount: 3);
      // One from before local midnight, two from earlier today.
      await makeLearned(db, <String>[
        fixture.cardIds[0],
      ], dueAt: dayStart.subtract(const Duration(hours: 1)));
      await makeLearned(db, <String>[
        fixture.cardIds[1],
        fixture.cardIds[2],
      ], dueAt: dayStart.add(const Duration(hours: 1)));

      final workload = await repository().readWorkload(
        now: now,
        utcOffset: offset,
      );

      expect(workload.single.overdueCount, 1);
      expect(workload.single.dueTodayCount, 2);
    });

    test('overdue age is counted in local day boundaries (BR-161)', () async {
      final fixture = await deckWithCards(db, cardCount: 1);
      // 23:00 local two days ago: only 44 hours back, but three local
      // calendar days are involved and two boundaries have passed.
      await makeLearned(
        db,
        fixture.cardIds,
        dueAt: dayStart.subtract(const Duration(hours: 25)),
      );

      final workload = await repository().readWorkload(
        now: now,
        utcOffset: offset,
      );

      expect(workload.single.overdueDayCount, 2);
    });

    test('a card is counted once, under its root (BR-188)', () async {
      // Three levels: a card at the bottom must be attributed to the root,
      // not to its own deck and not to both.
      await insertRootDeck(db, id: 'root');
      await insertSubDeck(
        db,
        id: 'mid',
        parentId: 'root',
        rootDeckId: 'root',
        contentType: 'deck',
      );
      await insertSubDeck(
        db,
        id: 'leaf',
        parentId: 'mid',
        rootDeckId: 'root',
        contentType: 'card',
      );
      await insertCard(db, id: 'c1', deckId: 'leaf', front: 'a', back: 'b');
      await makeLearned(db, <String>['c1'], dueAt: dayStart);

      final workload = await repository().readWorkload(
        now: now,
        utcOffset: offset,
      );

      expect(workload, hasLength(1));
      expect(workload.single.deckId, 'root');
      expect(workload.single.dueCount, 1);
    });

    test('two roots are two rows, each with its own name', () async {
      // Built by hand rather than through `deckWithCards` twice: that helper
      // names its cards `card-<i>`, so a second call collides on the primary
      // key — and the collision would read as a schema problem rather than as
      // the fixture reusing an id.
      for (final root in <String>['r1', 'r2']) {
        await insertRootDeck(db, id: root);
        await insertSubDeck(
          db,
          id: 'd-$root',
          parentId: root,
          rootDeckId: root,
          contentType: 'card',
        );
        await insertCard(
          db,
          id: 'c-$root',
          deckId: 'd-$root',
          front: 'front-$root',
          back: 'back-$root',
        );
      }
      await makeLearned(db, <String>['c-r2'], dueAt: dayStart);

      final workload = await repository().readWorkload(
        now: now,
        utcOffset: offset,
      );

      // Only the deck whose card was made due owes anything; the second root
      // is absent rather than present with zeroes.
      expect(workload.map((deck) => deck.deckId), <String>['r2']);
      expect(workload.single.deckName, isNotEmpty);
    });

    test('reading the workload writes nothing (BR-189)', () async {
      final fixture = await deckWithCards(db, cardCount: 2);
      await makeLearned(db, fixture.cardIds, dueAt: dayStart);

      final before = await db
          .customSelect('SELECT card_id, due_at, learned_at FROM card_study_states')
          .get();

      await repository().readWorkload(now: now, utcOffset: offset);

      final after = await db
          .customSelect('SELECT card_id, due_at, learned_at FROM card_study_states')
          .get();
      expect(
        after.map((row) => row.data.toString()),
        before.map((row) => row.data.toString()),
      );
    });
  });
}
