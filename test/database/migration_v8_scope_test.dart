// The other half of the v7 → v8 review: what the backfill must **not** touch,
// and what the new column refuses to hold (BR-182, BR-184).
//
// What it must stamp is in `migration_v8_test.dart`; the fixtures both use are
// in `support/migration_v8_fixture.dart`.

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';
import 'support/migration_v8_fixture.dart';

void main() {
  group('what the backfill must leave alone', () {
    test('an eight_box review is untouched on all three tables', () async {
      // It never ran `self_assess` in a review (BR-110), so there is no
      // direction it could have been asked in. `match` is what such a session
      // actually ran.
      final db = await upgradedFromV7((raw) {
        seedTree(raw, root: 'boxroot', scheduler: 'eight_box');
        seedSession(
          raw,
          root: 'boxroot',
          id: 's-box',
          kind: 'reviewing',
          mode: 'match',
          scheduler: 'eight_box',
        );
      });

      expect(await directionOf(db, 'study_sessions', "id = 's-box'"), isNull);
      expect(
        await directionOf(db, 'study_queue_items', "session_id = 's-box'"),
        isNull,
      );
      expect(await directionOf(db, 'study_answers', "id = 's-box-a1'"), isNull);
    });

    test('an sm2 learning chain is untouched', () async {
      // Its stages are not the user's to choose (BR-109). A stamp here would be
      // a choice the learner never made.
      final db = await upgradedFromV7((raw) {
        seedTree(raw, root: 'learnroot', scheduler: 'sm2');
        seedSession(
          raw,
          root: 'learnroot',
          id: 's-learn',
          kind: 'learning',
          mode: 'self_assess',
          scheduler: 'sm2',
        );
      });

      expect(await directionOf(db, 'study_sessions', "id = 's-learn'"), isNull);
      expect(
        await directionOf(db, 'study_queue_items', "session_id = 's-learn'"),
        isNull,
      );
      expect(
        await directionOf(db, 'study_answers', "id = 's-learn-a1'"),
        isNull,
      );
    });

    test('an eight_box tree beside an sm2 one is not caught by it', () async {
      // The scoping predicate resolves the algorithm per root. Dropping it would
      // stamp every library the moment one deck qualified.
      final db = await upgradedFromV7((raw) {
        seedTree(raw, root: 'sm2root', scheduler: 'sm2');
        seedTree(raw, root: 'boxroot', scheduler: 'eight_box');
        seedSession(
          raw,
          root: 'sm2root',
          id: 's-sm2',
          kind: 'reviewing',
          mode: 'self_assess',
          scheduler: 'sm2',
        );
        seedSession(
          raw,
          root: 'boxroot',
          id: 's-box',
          kind: 'reviewing',
          mode: 'self_assess',
          scheduler: 'eight_box',
        );
      });

      expect(
        await directionOf(db, 'study_sessions', "id = 's-sm2'"),
        'korean_to_meaning',
      );
      expect(await directionOf(db, 'study_sessions', "id = 's-box'"), isNull);
      expect(await directionOf(db, 'study_answers', "id = 's-box-a1'"), isNull);
    });

    test('a tree Reset onto another algorithm stays consistent', () async {
      // **The case the first draft got wrong, and it is not exotic.** Reset
      // rewrites `decks.scheduler_type` and deletes no history (BR-41, BR-43),
      // so a tree that was reviewed under `sm2` and then Reset onto `eight_box`
      // has an answer row saying `sm2` under a deck saying `eight_box`. Asking
      // the two tables two different questions stamped the answer and not its
      // queue row — invariant 32's violation, written by the migration itself.
      final db = await upgradedFromV7((raw) {
        seedTree(raw, root: 'resetroot', scheduler: 'sm2');
        seedSession(
          raw,
          root: 'resetroot',
          id: 's-reset',
          kind: 'reviewing',
          mode: 'self_assess',
          scheduler: 'sm2',
        );
        // The Reset itself: the deck moves on, the history does not.
        raw.execute(
          "UPDATE decks SET scheduler_type = 'eight_box' WHERE id = 'resetroot'",
        );
      });

      expect(
        await directionOf(db, 'study_sessions', "id = 's-reset'"),
        'korean_to_meaning',
      );
      expect(
        await directionOf(db, 'study_queue_items', "session_id = 's-reset'"),
        'korean_to_meaning',
      );
      expect(
        await directionOf(db, 'study_answers', "id = 's-reset-a1'"),
        'korean_to_meaning',
      );
    });

    test('a session with no direction leaves its rows alone', () async {
      // The other half of "derived, not re-decided": an `eight_box` session is
      // not stamped, so nothing under it may be either — however its rows look.
      final db = await upgradedFromV7((raw) {
        seedTree(raw, root: 'boxroot', scheduler: 'eight_box');
        seedSession(
          raw,
          root: 'boxroot',
          id: 's-box',
          kind: 'reviewing',
          mode: 'self_assess',
          scheduler: 'eight_box',
        );
      });

      expect(await directionOf(db, 'study_sessions', "id = 's-box'"), isNull);
      expect(
        await directionOf(db, 'study_queue_items', "session_id = 's-box'"),
        isNull,
      );
      expect(await directionOf(db, 'study_answers', "id = 's-box-a1'"), isNull);
    });

    test('nothing else on the row moves', () async {
      // Additive plus one column: the migration must not rewrite a schedule, a
      // cursor or a timestamp on its way past.
      final db = await upgradedFromV7((raw) {
        seedTree(raw, root: 'sm2root', scheduler: 'sm2');
        seedSession(
          raw,
          root: 'sm2root',
          id: 's-sm2',
          kind: 'reviewing',
          mode: 'self_assess',
          scheduler: 'sm2',
        );
      });

      final session =
          (await db
                  .customSelect(
                    "SELECT cursor, card_limit, started_at, ended_at, status "
                    "FROM study_sessions WHERE id = 's-sm2'",
                  )
                  .get())
              .single;

      expect(session.data['cursor'], 1);
      expect(session.data['card_limit'], 20);
      expect(session.data['started_at'], 700);
      expect(session.data['ended_at'], 900);
      expect(session.data['status'], 'completed');

      final state =
          (await db
                  .customSelect(
                    "SELECT learned_at, due_at, current_box FROM card_study_states "
                    "WHERE card_id = 'sm2root-c1'",
                  )
                  .get())
              .single;

      expect(state.data['learned_at'], 100);
      expect(state.data['due_at'], 200);
      expect(state.data['current_box'], 2);

      final deck =
          (await db
                  .customSelect(
                    "SELECT updated_at FROM decks WHERE id = 'sm2root'",
                  )
                  .get())
              .single;

      expect(deck.data['updated_at'], 7, reason: 'a migration is not an edit');
    });
  });

  test('the column refuses a value outside the enumeration', () async {
    // A turn is asked one way or the other; `mixed` is a session's choice and
    // must be unrepresentable on a row (BR-184).
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('d1', 'Korean', 'd1', 'deck', 'sm2', 1, 1, 0, 0)",
    );
    await db.customStatement(
      'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
      'scheduler_generation, status, session_kind, current_mode, cursor, '
      'card_limit, started_at, direction) '
      "VALUES ('s1', 'd1', 'd1', 1, 'in_progress', 'reviewing', 'self_assess', "
      "0, 20, 0, 'mixed')",
    );

    await expectLater(
      db.customStatement(
        'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
        'position, status, direction) '
        "VALUES ('s1', 'self_assess', 1, 'c1', 0, 'pending', 'mixed')",
      ),
      throwsA(anything),
    );
  });

  test(
    'every committed snapshot still upgrades to the latest schema',
    () async {
      // v1…v8, each started from its own dump. This is what proves the new step
      // runs *after* the older ones rather than instead of them.
      for (final version in GeneratedHelper.versions) {
        final verifier = SchemaVerifier(GeneratedHelper());
        final connection = await verifier.startAt(version);
        final db = AppDatabase(connection.executor);
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, db.schemaVersion);
      }
    },
  );

  test('a fresh install needs no backfill', () async {
    // `onCreate` never runs `onUpgrade`, so the column has to be right from the
    // first row rather than from the first migration. It is, vacuously: a new
    // library has no session to have chosen a direction for.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final rows = await db
        .customSelect('SELECT direction FROM study_sessions')
        .get();

    expect(rows, isEmpty);
  });
}
