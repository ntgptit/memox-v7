import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/datasources/study_home_dao.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/domain/models/study_day_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import '../../../database/support/test_database.dart';

/// Study Home's read, against real SQLite (UC-12, BR-182…BR-184).
///
/// **A real database, not a double.** Everything in doubt here is a property of
/// the SQL: whether the workload reaches a card three levels down, whether the
/// due set is partitioned exactly at the local-day boundary, whether a session
/// from an earlier day or a stale generation is excluded, and whether the read
/// writes nothing. A fake would assert that the code calls the methods it was
/// written to call, which is the one thing nobody doubts.
void main() {
  late AppDatabase db;
  late List<String> queryLog;
  late StudyHomeRepositoryImpl repository;

  /// Local midnight is `testNow`'s own day at UTC+0, so `startOfToday` is
  /// 2026-07-29 00:00Z and `now` is noon on it — a day with room on both sides
  /// of the boundary, which is what makes the partition constructible.
  final day = StudyDayModel(now: testNow, utcOffset: Duration.zero);

  setUp(() {
    queryLog = <String>[];
    db = openTestDatabase(log: queryLog.add);
    repository = StudyHomeRepositoryImpl(StudyHomeDao(db));
  });

  Future<StudyHomeModel> read() => repository.watchStudyHome(day).first;

  /// The SQL out of the interceptor's log lines.
  ///
  /// `QueryLogInterceptor` writes `123us  SELECT …  (2 rows)`; the assertions
  /// below are about the statements, so the timing and the outcome are stripped
  /// here rather than being matched around at every call site.
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

  Future<void> seedQueueItem(String sessionId, String cardId) =>
      db.customInsert(
        'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
        "position, status) VALUES (?, 'self_assess', 1, ?, 0, 'pending')",
        variables: <Variable<Object>>[
          Variable<String>(sessionId),
          Variable<String>(cardId),
        ],
      );

  group('workload', () {
    test('aggregates the whole subtree, at every depth', () async {
      // Three levels, one due card each. The read groups by `root_deck_id`
      // (BR-56, BR-57), which is why it needs no recursion — and why a card at
      // level 3 must still be counted against the root.
      await insertRootDeck(db, id: 'root');
      await insertSubDeck(
        db,
        id: 'branch',
        parentId: 'root',
        rootDeckId: 'root',
      );
      await insertSubDeck(
        db,
        id: 'leaf',
        parentId: 'branch',
        rootDeckId: 'root',
      );
      for (final deckId in <String>['root', 'branch', 'leaf']) {
        await seedDueCard(
          'c-$deckId',
          deckId: deckId,
          before: const Duration(hours: 1),
        );
      }

      final home = await read();

      expect(home.decks, hasLength(1));
      expect(home.decks.single.dueTodayCount, 3);
      expect(home.decks.single.totalCardCount, 3);
    });

    test('splits due exactly at the local-day boundary', () async {
      // BR-162's partition. `startOfToday` is 00:00Z; the three cards sit one
      // second before it, exactly on it, and at the read instant — so every
      // boundary this rule has is constructed rather than assumed.
      await insertRootDeck(db, id: 'root');
      await insertCard(db, id: 'yesterday', deckId: 'root');
      await insertReviewState(
        db,
        cardId: 'yesterday',
        dueAt: day.startOfToday.subtract(const Duration(seconds: 1)),
      );
      await insertCard(db, id: 'midnight', deckId: 'root');
      await insertReviewState(db, cardId: 'midnight', dueAt: day.startOfToday);
      await insertCard(db, id: 'now', deckId: 'root');
      await insertReviewState(db, cardId: 'now', dueAt: testNow);

      final deck = (await read()).decks.single;

      expect(deck.overdueCount, 1);
      expect(deck.dueTodayCount, 2);
      // The partition closes: the two halves are the whole Reviewing set of
      // BR-142, so a session still draws from one number.
      expect(deck.dueCount, deck.overdueCount + deck.dueTodayCount);
    });

    test('a card due after now counts in neither half', () async {
      await insertRootDeck(db, id: 'root');
      await insertCard(db, id: 'later', deckId: 'root');
      await insertReviewState(
        db,
        cardId: 'later',
        dueAt: testNow.add(const Duration(seconds: 1)),
      );

      final deck = (await read()).decks.single;

      expect(deck.dueCount, 0);
      expect(deck.newCount, 0);
      expect(deck.totalCardCount, 1);
    });

    test('new is the other side of learned_at, never a subtraction', () async {
      await insertRootDeck(db, id: 'root');
      await seedNewCard('new-1', deckId: 'root');
      await seedDueCard(
        'due-1',
        deckId: 'root',
        before: const Duration(days: 3),
      );

      final deck = (await read()).decks.single;

      expect(deck.newCount, 1);
      expect(deck.overdueCount, 1);
      expect(deck.dueTodayCount, 0);
    });

    test('sibling trees are counted apart', () async {
      await insertRootDeck(db, id: 'a');
      await insertRootDeck(db, id: 'b');
      await seedDueCard('c-a', deckId: 'a', before: const Duration(days: 2));
      await seedNewCard('c-b', deckId: 'b');

      final home = await read();

      final a = home.decks.firstWhere((deck) => deck.deckId == 'a');
      final b = home.decks.firstWhere((deck) => deck.deckId == 'b');
      expect(a.overdueCount, 1);
      expect(a.newCount, 0);
      expect(b.overdueCount, 0);
      expect(b.newCount, 1);
    });

    test('a root with no cards is listed, with zeroes', () async {
      // It has to be listed: dropping it in SQL would make "decks but no cards"
      // indistinguishable from "no decks", and those are two screens (BR-184).
      await insertRootDeck(db, id: 'root');

      final home = await read();

      expect(home.decks.single.totalCardCount, 0);
      expect(home.decks.single.hasWorkload, isFalse);
      expect(home.decks.single.isStudiable, isFalse);
      expect(home.hasNoCards, isTrue);
      expect(home.studiableDecks, isEmpty);
    });

    test('no decks at all is the empty-library state', () async {
      final home = await read();

      expect(home.decks, isEmpty);
      expect(home.isLibraryEmpty, isTrue);
      // Not the same state, and the difference decides which screen renders.
      expect(home.hasNoCards, isFalse);
      expect(home.resume, isNull);
    });

    test('a sub-deck never appears as a row of its own', () async {
      await insertRootDeck(db, id: 'root');
      await insertSubDeck(
        db,
        id: 'branch',
        parentId: 'root',
        rootDeckId: 'root',
      );

      final home = await read();

      expect(home.decks.map((deck) => deck.deckId), <String>['root']);
    });

    test('the scheduler is the root-s own, and null degrades', () async {
      await insertRootDeck(db, id: 'sm2', schedulerType: 'sm2');
      await insertRootDeck(db, id: 'none', schedulerType: null);

      final home = await read();

      expect(
        home.decks.firstWhere((deck) => deck.deckId == 'sm2').schedulerType,
        SchedulerType.sm2,
      );
      // Listed and openable; only the label is withheld.
      expect(
        home.decks.firstWhere((deck) => deck.deckId == 'none').schedulerType,
        SchedulerType.unknown,
      );
    });
  });

  group('ordering (BR-183)', () {
    test('overdue outranks due today, which outranks new', () async {
      await insertRootDeck(db, id: 'new-heavy');
      await insertRootDeck(db, id: 'due-today');
      await insertRootDeck(db, id: 'overdue');
      for (var i = 0; i < 50; i++) {
        await seedNewCard('n$i', deckId: 'new-heavy');
      }
      for (var i = 0; i < 10; i++) {
        await seedDueCard(
          't$i',
          deckId: 'due-today',
          before: const Duration(hours: 1),
        );
      }
      await seedDueCard(
        'o0',
        deckId: 'overdue',
        before: const Duration(days: 4),
      );

      final home = await read();

      // One overdue card beats ten due today, which beats fifty new: the keys
      // are ranked, not summed. A total would have put `new-heavy` first.
      expect(home.decks.map((deck) => deck.deckId), <String>[
        'overdue',
        'due-today',
        'new-heavy',
      ]);
    });

    test('a deck with no workload sorts last but stays studiable', () async {
      await insertRootDeck(db, id: 'quiet');
      await insertRootDeck(db, id: 'busy');
      await insertCard(db, id: 'resting', deckId: 'quiet');
      await insertReviewState(
        db,
        cardId: 'resting',
        dueAt: testNow.add(const Duration(days: 5)),
      );
      await seedNewCard('n0', deckId: 'busy');

      final home = await read();

      expect(home.decks.map((deck) => deck.deckId), <String>['busy', 'quiet']);
      expect(home.studiableDecks.map((deck) => deck.deckId), <String>[
        'busy',
        'quiet',
      ]);
    });

    test('ties break on the folded name, then the id', () async {
      // Three decks with identical (0, 0, 0) workload. `Đà Nẵng` is the case that
      // makes the fold load-bearing: SQLite-s `lower()` leaves `Đ` alone, so an
      // ORDER BY in SQL would sort it by the uppercase byte and put it before
      // `apple` — Dart-s Unicode-aware fold does not.
      await insertRootDeck(db, id: 'z-id');
      await insertRootDeck(db, id: 'a-id');
      await insertRootDeck(db, id: 'diacritic');
      await db.customStatement(
        "UPDATE decks SET name = 'apple' WHERE id = 'z-id'",
      );
      await db.customStatement(
        "UPDATE decks SET name = 'apple' WHERE id = 'a-id'",
      );
      await db.customStatement(
        "UPDATE decks SET name = 'Đà Nẵng' WHERE id = 'diacritic'",
      );

      final home = await read();

      expect(home.decks.map((deck) => deck.deckId), <String>[
        'a-id',
        'z-id',
        'diacritic',
      ]);
    });
  });

  group('resume (BR-182)', () {
    Future<void> seedOpenSession({
      String id = 's1',
      String deckId = 'root',
      String rootDeckId = 'root',
      String status = 'in_progress',
    }) async {
      await insertSession(
        db,
        id: id,
        deckId: deckId,
        rootDeckId: rootDeckId,
        status: status,
        endReason: status == 'in_progress' ? null : 'user_exit',
        endedAt: status == 'in_progress' ? null : testNow,
      );
      await seedQueueItem(id, 'c0');
    }

    setUp(() async {
      await insertRootDeck(db, id: 'root');
      await seedDueCard('c0', deckId: 'root', before: const Duration(hours: 2));
    });

    test(
      'an open session of today is offered, with its own kind and stage',
      () async {
        await seedOpenSession();

        final resume = (await read()).resume;

        expect(resume, isNotNull);
        expect(resume!.sessionId, 's1');
        expect(resume.deckId, 'root');
        expect(resume.deckName, 'deck root');
        expect(resume.kind, StudySessionKind.reviewing);
        expect(resume.currentMode, StudyMode.selfAssess);
      },
    );

    test('a session that has ended is not offered', () async {
      await seedOpenSession(status: 'abandoned');

      expect((await read()).resume, isNull);
    });

    test('a session from an earlier study day is not offered', () async {
      await seedOpenSession();
      // BR-103: over whether or not anything has closed it yet. Home excludes it
      // by reading; closing it belongs to `abandonStaleSessions`, which runs
      // when the user enters the flow.
      await db.customStatement(
        'UPDATE study_sessions SET started_at = ?',
        <Object?>[
          day.startOfToday
                  .subtract(const Duration(seconds: 1))
                  .millisecondsSinceEpoch ~/
              1000,
        ],
      );

      expect((await read()).resume, isNull);
    });

    test('a session whose root has moved generation is not offered', () async {
      await seedOpenSession();
      // A Reset bumped the root past the session (BR-45, BR-84): every write the
      // session makes would be refused, so offering to continue it would offer a
      // session that fails on its first answer.
      await db.customStatement(
        "UPDATE decks SET scheduler_generation = 2 WHERE id = 'root'",
      );

      expect((await read()).resume, isNull);
    });

    test('a session whose cards are all gone is not offered', () async {
      await seedOpenSession();
      // `study_queue_items.card_id` cascades, so deleting the cards empties the
      // queue and there is no turn to come back to.
      await db.customStatement("DELETE FROM cards WHERE id = 'c0'");

      expect((await read()).resume, isNull);
    });

    test('a session whose deck is gone is not offered', () async {
      await insertRootDeck(db, id: 'other');
      await insertCard(db, id: 'c-other', deckId: 'other');
      await insertReviewState(db, cardId: 'c-other', dueAt: testNow);
      await insertSession(
        db,
        id: 's-other',
        deckId: 'other',
        rootDeckId: 'other',
      );
      await seedQueueItem('s-other', 'c-other');
      await db.customStatement("DELETE FROM decks WHERE id = 'other'");

      expect((await read()).resume, isNull);
    });

    test('the newest open session wins when two are open', () async {
      await insertRootDeck(db, id: 'second');
      await insertCard(db, id: 'c-second', deckId: 'second');
      await insertReviewState(db, cardId: 'c-second', dueAt: testNow);
      await seedOpenSession();
      await insertSession(
        db,
        id: 's2',
        deckId: 'second',
        rootDeckId: 'second',
        sessionKind: 'learning',
        currentMode: 'browse',
      );
      await seedQueueItem('s2', 'c-second');
      await db.customStatement(
        "UPDATE study_sessions SET started_at = ? WHERE id = 's2'",
        <Object?>[
          testNow.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/
              1000,
        ],
      );

      final resume = (await read()).resume;

      expect(resume!.sessionId, 's2');
      expect(resume.kind, StudySessionKind.learning);
    });
  });

  group('the read is a read', () {
    test('it writes nothing — no session, no lock, no queue', () async {
      await insertRootDeck(db, id: 'root');
      await seedNewCard('c0', deckId: 'root');
      queryLog.clear();

      await read();

      // Not "no session row appeared" alone: a statement log is what catches a
      // write that happens to be idempotent. `BEGIN`/`COMMIT` are the read-only
      // transaction the snapshot runs in.
      final writes = queryLog.where(
        (sql) => RegExp(
          r'\b(INSERT|UPDATE|DELETE)\b',
          caseSensitive: false,
        ).hasMatch(sql),
      );
      expect(writes, isEmpty, reason: queryLog.join('\n'));

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
        // repository asking per deck returns exactly the same model.
        for (var i = 0; i < 12; i++) {
          await insertRootDeck(db, id: 'root-$i');
          await seedDueCard(
            'c-$i',
            deckId: 'root-$i',
            before: const Duration(hours: 1),
          );
        }
        queryLog.clear();

        final home = await read();

        expect(home.decks, hasLength(12));
        final selects = statements()
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
      final subscription = repository.watchStudyHome(day).listen(emissions.add);
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
        final subscription = repository
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
        final subscription = repository
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
      final subscription = repository.watchStudyHome(day).listen(emissions.add);
      await pumpEventQueue();
      queryLog.clear();

      await (db.update(
        db.cardStudyStates,
      )..where((s) => s.cardId.equals('c0'))).write(
        CardStudyStatesCompanion(
          dueAt: Value<DateTime>(testNow.add(const Duration(days: 1))),
        ),
      );
      await pumpEventQueue();
      await subscription.cancel();

      final run = statements();
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
      final subscription = repository
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
      final subscription = repository.watchStudyHome(day).listen(emissions.add);
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

  group('expiry', () {
    test('nextDueAt is the earliest card strictly after now', () async {
      await insertRootDeck(db, id: 'root');
      await insertCard(db, id: 'soon', deckId: 'root');
      await insertReviewState(
        db,
        cardId: 'soon',
        dueAt: testNow.add(const Duration(hours: 3)),
      );
      await insertCard(db, id: 'later', deckId: 'root');
      await insertReviewState(
        db,
        cardId: 'later',
        dueAt: testNow.add(const Duration(days: 9)),
      );

      final home = await read();

      expect(home.nextDueAt, testNow.add(const Duration(hours: 3)));
      // Nothing is due, so midnight moves nothing and no timer is asked for.
      expect(home.nextOverdueTickAt, isNull);
    });

    test('an open session arms the midnight tick even with nothing due', () async {
      // BR-182 offers a session back only while it belongs to the current study
      // day, and that window shuts at the same boundary the due split moves at.
      // A library of unlearned cards has no `due_at` at all, so `nextDueAt` is
      // null — and the tick was null too, which left a tab open across midnight
      // still offering a session BR-103 had already made stale.
      await insertRootDeck(db, id: 'root');
      await seedNewCard('c0', deckId: 'root');
      await insertSession(
        db,
        id: 's1',
        deckId: 'root',
        rootDeckId: 'root',
        sessionKind: 'learning',
        currentMode: 'browse',
      );
      await db.customInsert(
        'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
        "position, status) VALUES ('s1', 'browse', 1, 'c0', 0, 'pending')",
      );

      final home = await read();

      expect(home.resume, isNotNull);
      expect(home.nextDueAt, isNull);
      expect(home.nextOverdueTickAt, day.startOfDayAfter(1));
    });

    test(
      'the overdue tick is the next local midnight when anything is due',
      () async {
        await insertRootDeck(db, id: 'root');
        await seedDueCard(
          'c0',
          deckId: 'root',
          before: const Duration(hours: 1),
        );

        final home = await read();

        expect(home.nextOverdueTickAt, day.startOfDayAfter(1));
        // Every scheduled card is already due, so `nextDueAt` is null — which is
        // exactly the hole the tick exists to close (BR-161).
        expect(home.nextDueAt, isNull);
      },
    );
  });
}
