import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import '../../../database/support/test_database.dart';
import 'support/study_home_db_harness.dart';

/// Which session Study Home may offer back, and the ways one stops qualifying
/// (UC-12, BR-182, BR-103, BR-84).
///
/// **Every disqualification is a read.** Home renders; it does not repair.
/// Closing a session an earlier study day left open still belongs to
/// `abandonStaleSessions`, which runs when the user enters the flow — a screen
/// that repaired sessions would write to the database for being looked at.
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

  Future<void> seedQueueItem(String sessionId, String cardId) =>
      harness.seedQueueItem(sessionId, cardId);

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
}
