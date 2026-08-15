import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';

import '../../../database/support/test_database.dart';
import 'support/study_home_db_harness.dart';

/// Study Home's read as a *stream*: what it costs, what it never writes, and
/// what it must not miss (UC-14, BR-200).
///
/// Three of these exist because of bugs no assertion on the returned model could
/// have caught — a write dropped before the first read finished, a statement
/// count that grows with the library, and a `done` that deadlocked the cancel
/// meant to deliver it.
void main() {
  late StudyHomeDbHarness harness;
  late AppDatabase db;
  final day = StudyHomeDbHarness.day;

  setUp(() {
    harness = StudyHomeDbHarness();
    db = harness.db;
  });

  Future<StudyHomeModel> read() => harness.read();

  Future<void> seedDueCard(
    String id, {
    required String deckId,
    required Duration before,
  }) => harness.seedDueCard(id, deckId: deckId, before: before);

  Future<void> seedNewCard(String id, {required String deckId}) =>
      harness.seedNewCard(id, deckId: deckId);

  Future<void> seedQueueItem(String sessionId, String cardId) =>
      harness.seedQueueItem(sessionId, cardId);

  group('the read is a read', () {
    test('it writes nothing — no session, no lock, no queue', () async {
      await insertRootDeck(db, id: 'root');
      await seedNewCard('c0', deckId: 'root');
      harness.queryLog.clear();

      await read();

      // Not "no session row appeared" alone: a statement log is what catches a
      // write that happens to be idempotent. `BEGIN`/`COMMIT` are the read-only
      // transaction the snapshot runs in.
      final writes = harness.queryLog.where(
        (sql) => RegExp(
          r'\b(INSERT|UPDATE|DELETE)\b',
          caseSensitive: false,
        ).hasMatch(sql),
      );
      expect(writes, isEmpty, reason: harness.queryLog.join('\n'));

      final sessions = await db
          .customSelect('SELECT COUNT(*) AS c FROM study_sessions')
          .getSingle();
      expect(sessions.read<int>('c'), 0);
      final locked = await db
          .customSelect(
            'SELECT COUNT(*) AS c FROM decks WHERE first_answered_at IS NOT NULL',
          )
          .getSingle();
      expect(locked.read<int>('c'), 0);
    });

    test(
      'one snapshot costs two statements, whatever the library holds',
      () async {
        // The N+1 assertion, and it is invisible to any check on the *result*: a
        // harness.repository asking per deck returns exactly the same model.
        for (var i = 0; i < 12; i++) {
          await insertRootDeck(db, id: 'root-$i');
          await seedDueCard(
            'c-$i',
            deckId: 'root-$i',
            before: const Duration(hours: 1),
          );
        }
        harness.queryLog.clear();

        final home = await read();

        expect(home.decks, hasLength(12));
        final selects = harness
            .statements()
            .where((sql) => sql.startsWith('SELECT'))
            .toList();
        expect(selects, hasLength(2), reason: selects.join('\n'));
      },
    );

    test('the stream re-emits when a session ends', () async {
      await insertRootDeck(db, id: 'root');
      await seedDueCard('c0', deckId: 'root', before: const Duration(hours: 2));
      await insertSession(db, id: 's1', deckId: 'root', rootDeckId: 'root');
      await seedQueueItem('s1', 'c0');

      final emissions = <StudyHomeModel>[];
      final subscription = harness.repository
          .watchStudyHome(day)
          .listen(emissions.add);
      await pumpEventQueue();

      // The typed API, not `customStatement`: drift raises a table update from
      // the former and deliberately none from the latter, and production writes
      // go through the former. A test using raw SQL here would prove the stream
      // does not refresh — about a mechanism the app never uses.
      await (db.update(
        db.studySessions,
      )..where((s) => s.id.equals('s1'))).write(
        StudySessionsCompanion(
          status: const Value<String>('completed'),
          endedAt: Value<DateTime>(testNow),
        ),
      );
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions.first.resume, isNotNull);
      expect(emissions.last.resume, isNull);
    });

    test(
      'the stream re-emits when a card is answered into the future',
      () async {
        await insertRootDeck(db, id: 'root');
        await seedDueCard(
          'c0',
          deckId: 'root',
          before: const Duration(hours: 2),
        );

        final emissions = <StudyHomeModel>[];
        final subscription = harness.repository
            .watchStudyHome(day)
            .listen(emissions.add);
        await pumpEventQueue();

        await (db.update(
          db.cardStudyStates,
        )..where((s) => s.cardId.equals('c0'))).write(
          CardStudyStatesCompanion(
            dueAt: Value<DateTime>(testNow.add(const Duration(days: 2))),
          ),
        );
        await pumpEventQueue();
        await subscription.cancel();

        expect(emissions.first.decks.single.dueTodayCount, 1);
        expect(emissions.last.decks.single.dueCount, 0);
      },
    );

    test(
      'a change raised while the first read is in flight is not lost',
      () async {
        await insertRootDeck(db, id: 'root');

        final emissions = <StudyHomeModel>[];
        final subscription = harness.repository
            .watchStudyHome(day)
            .listen(emissions.add);

        // **Deliberately not pumped first.** The first snapshot read is still in
        // flight here, and this is the window the old shape dropped: written as
        // `async* { yield null; yield* tableUpdates; }`, the generator suspended
        // at its first yield and did not subscribe to the update bus until the
        // read had finished — so anything committed in between was never
        // reported, and the tab sat on stale counts until an unrelated write.
        //
        // `markTablesUpdated` raises exactly the notification a write raises,
        // without queueing behind the connection the read is holding, which
        // makes the interleaving deterministic instead of a race this test
        // would only lose sometimes.
        db.markTablesUpdated(<TableInfo<Table, Object?>>{db.decks});

        await pumpEventQueue();
        await subscription.cancel();

        expect(
          emissions.length,
          greaterThanOrEqualTo(2),
          reason: 'the update raised during the first read never arrived',
        );
      },
    );

    test('one signal costs one transaction and two statements', () async {
      // This screen stays subscribed while a session runs on top of it, so the
      // marginal cost of a signal is paid once per answered turn. The number is
      // asserted rather than argued: a snapshot that grew a third statement
      // would be invisible to every assertion made on the model.
      await insertRootDeck(db, id: 'root');
      await seedDueCard('c0', deckId: 'root', before: const Duration(hours: 1));

      final emissions = <StudyHomeModel>[];
      final subscription = harness.repository
          .watchStudyHome(day)
          .listen(emissions.add);
      await pumpEventQueue();
      harness.queryLog.clear();

      await (db.update(
        db.cardStudyStates,
      )..where((s) => s.cardId.equals('c0'))).write(
        CardStudyStatesCompanion(
          dueAt: Value<DateTime>(testNow.add(const Duration(days: 1))),
        ),
      );
      await pumpEventQueue();
      await subscription.cancel();

      final run = harness.statements();
      expect(run.where((sql) => sql.startsWith('SELECT')), hasLength(2));
      expect(run.where((sql) => sql == 'BEGIN'), hasLength(1));
    });

    test('closing the database completes the stream and cancel returns', () async {
      // **The one path nothing exercised, and the one that deadlocked.** Every
      // other test cancels before the database closes, so the controller is
      // already cancelled by the time anything tries to close it. Here the bus
      // closes *first*: `onDone` closes the controller, that runs `onCancel`,
      // and without the `isClosed` guard `onCancel` awaits the very done-future
      // it is supposed to complete — `cancel()` never returns and the consumer
      // never sees `done` either, so forwarding it achieved nothing.
      await insertRootDeck(db, id: 'root');

      var isDone = false;
      final subscription = harness.repository
          .watchStudyHome(day)
          .listen(null, onDone: () => isDone = true);
      await pumpEventQueue();

      await db.close();
      await pumpEventQueue();

      // Would hang forever on the unguarded double close.
      await subscription.cancel().timeout(const Duration(seconds: 5));

      expect(isDone, isTrue);
    });

    test('the stream re-emits when a deck is added', () async {
      final emissions = <StudyHomeModel>[];
      final subscription = harness.repository
          .watchStudyHome(day)
          .listen(emissions.add);
      await pumpEventQueue();

      await db
          .into(db.decks)
          .insert(
            DecksCompanion.insert(
              id: 'root',
              name: 'deck root',
              rootDeckId: 'root',
              contentType: 'deck',
              schedulerType: const Value<String?>('eight_box'),
              schedulerGeneration: const Value<int?>(1),
              createdAt: testNow,
              updatedAt: testNow,
            ),
          );
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions.first.decks, isEmpty);
      expect(emissions.last.decks, hasLength(1));
    });
  });
}
