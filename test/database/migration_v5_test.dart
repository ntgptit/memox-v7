import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// The v4 → v5 upgrade: the whole Study schema, and the two tables it rebuilds.
///
/// **Rebuilding is not an implementation detail here, it is the risk.**
/// `study_sessions` and `study_answers` are dropped and recreated because
/// SQLite cannot widen a `CHECK` constraint. That is the one migration shape
/// that can silently lose every row, and `migrateAndValidate` would not notice:
/// it compares the schema, and an empty table has the right schema. So every
/// test below seeds rows first and reads them back after.
///
/// The other half is the backfill. From v5, `learned_at` and `due_at` travel
/// together (BR-149): a card either finished the learning chain and has both,
/// or has neither. A migration that added the column and left it NULL would
/// turn invariant 28 red on the first launch after the update, on real user
/// data, with no way back.
void main() {
  /// A v4 database holding one scheduled card, one never-scheduled card, one
  /// session and one answer — then upgraded to v5.
  Future<AppDatabase> upgradedFromSeededV4() async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(4);

    schema.rawDatabase.execute(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'first_answered_at, created_at, updated_at) '
      "VALUES ('d1', 'Korean', 'd1', 'card', 'eight_box', 1, 1, 1700, 0, 0)",
    );
    for (final id in <String>['c1', 'c2']) {
      schema.rawDatabase.execute(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, created_at, updated_at) '
        "VALUES ('$id', 'd1', 'kimchi', 'kim chi', 'kimchi', 'kim chi', 0, 0)",
      );
    }

    // c1 has been reviewed: a due date and a last-answered stamp.
    schema.rawDatabase.execute(
      'INSERT INTO card_study_states (card_id, scheduler_type, '
      'scheduler_version, scheduler_generation, due_at, last_answered_at, '
      'answer_count, lapse_count, current_box) '
      "VALUES ('c1', 'eight_box', 1, 1, 2400, 1800, 3, 1, 4)",
    );

    // c2 is untouched. Under v4 that is `due_at IS NULL`, which meant "due
    // immediately"; under v5 it means "has not finished the chain".
    schema.rawDatabase.execute(
      'INSERT INTO card_study_states (card_id, scheduler_type, '
      'scheduler_version, scheduler_generation, due_at, last_answered_at, '
      'answer_count, lapse_count, current_box) '
      "VALUES ('c2', 'eight_box', 1, 1, NULL, NULL, 0, 0, 1)",
    );

    schema.rawDatabase.execute(
      'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
      'scheduler_generation, status, end_reason, started_at, ended_at) '
      "VALUES ('s1', 'd1', 'd1', 1, 'abandoned', 'user_exit', 1700, 1900)",
    );
    schema.rawDatabase.execute(
      'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
      'scheduler_generation, kind, "action", answered_at, next_due_at, '
      'previous_box, next_box) '
      "VALUES ('h1', 'c1', 's1', 'eight_box', 1, 'scheduled', "
      "'remembered', 1800, 2400, 3, 4)",
    );

    final db = AppDatabase(schema.newConnection());

    // **`db.schemaVersion`, not a literal 5, and the literal was a fiction.**
    // `onUpgrade` branches on `from` alone — deliberately, because in production
    // `to` is always the newest version and a `to >= n` guard would add a branch
    // no device ever takes (see `migration_test.dart`). A v4 database therefore
    // cannot be stopped at v5: it runs every step. Naming 5 here worked only for
    // as long as every later step happened to be data-only, and v8's three
    // columns are what ended that, with v9's two and v10's three right
    // behind them, and v11 rebuilds `study_sessions` outright. What these tests assert is unchanged — that a v4 row
    // survives the rebuild — and the path it survives is the whole one a
    // real device takes.
    await verifier.migrateAndValidate(db, db.schemaVersion);
    return db;
  }

  Future<List<QueryRow>> rows(AppDatabase db, String sql) =>
      db.customSelect(sql).get();

  group('v4 → v5 · the backfill', () {
    test(
      'a card with a schedule gets learned_at from last_answered_at',
      () async {
        final db = await upgradedFromSeededV4();
        addTearDown(db.close);

        final row = (await rows(
          db,
          "SELECT learned_at, due_at FROM card_study_states WHERE card_id = 'c1'",
        )).single;

        // Not `due_at`: the honest moment a card finished learning is the last
        // time it was answered, and `due_at` is a date in the future.
        expect(row.read<int>('learned_at'), 1800);
        expect(row.read<int>('due_at'), 2400);
      },
    );

    test('a card without a schedule stays NULL on both', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      final row = (await rows(
        db,
        "SELECT learned_at, due_at FROM card_study_states WHERE card_id = 'c2'",
      )).single;

      expect(row.read<int?>('learned_at'), isNull);
      expect(row.read<int?>('due_at'), isNull);
    });

    test('invariants 24 and 28 are both empty after the upgrade', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      // The pair BR-149 requires, checked as the two queries `data-model.md`
      // names — one for each direction, because between them they are what
      // stops a card from having a schedule it never earned.
      expect(
        await rows(
          db,
          'SELECT card_id FROM card_study_states '
          'WHERE learned_at IS NOT NULL AND due_at IS NULL',
        ),
        isEmpty,
      );
      expect(
        await rows(
          db,
          'SELECT card_id FROM card_study_states '
          'WHERE learned_at IS NULL AND due_at IS NOT NULL',
        ),
        isEmpty,
      );
    });
  });

  group('v4 → v5 · the two rebuilt tables keep their rows', () {
    test('the session survives, with values for the new columns', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      final row = (await rows(db, 'SELECT * FROM study_sessions')).single;

      expect(row.read<String>('id'), 's1');
      expect(row.read<String>('status'), 'abandoned');
      expect(row.read<String>('end_reason'), 'user_exit');
      expect(row.read<int>('started_at'), 1700);
      expect(row.read<int>('ended_at'), 1900);

      // What a v4 session actually was: one kind, one mode, no queue, the
      // default ceiling.
      expect(row.read<String>('session_kind'), 'reviewing');
      expect(row.read<String>('current_mode'), 'self_assess');
      expect(row.read<int>('cursor'), 0);
      expect(row.read<int>('card_limit'), 20);
    });

    test('the answer survives, and its mode is the only one v4 had', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      final row = (await rows(db, 'SELECT * FROM study_answers')).single;

      expect(row.read<String>('id'), 'h1');
      expect(row.read<String>('kind'), 'scheduled');
      expect(row.read<String>('action'), 'remembered');
      expect(row.read<int>('answered_at'), 1800);
      expect(row.read<int>('previous_box'), 3);
      expect(row.read<int>('next_box'), 4);

      // Guessing any other mode would put a turn into history that the app of
      // that version could not have produced.
      expect(row.read<String>('mode'), 'self_assess');
      expect(row.read<int?>('outcome_reason'), isNull);
      expect(row.read<int?>('comparison_version'), isNull);
      expect(row.read<int?>('used_hint'), isNull);
    });

    test('the foreign key from answer to session still holds', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      // Both tables were dropped and recreated. If the rebuild had left the
      // reference pointing at the temporary name, this insert would succeed.
      await expectLater(
        db.customStatement(
          'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
          'scheduler_generation, kind, mode, "action", answered_at) '
          "VALUES ('h2', 'c1', 'no-such-session', 'eight_box', 1, 'scheduled', "
          "'self_assess', 'remembered', 1900)",
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('v4 → v5 · what the new schema now refuses', () {
    test('kind accepts learning, and end_reason accepts interrupted', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      // The two values that forced the rebuild in the first place: SQLite
      // cannot widen a CHECK, so if these fail the migration silently kept the
      // v4 constraint and the learning chain could never write a turn.
      await db.customStatement(
        'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
        'scheduler_generation, kind, mode, "action", answered_at) '
        "VALUES ('h3', 'c1', 's1', 'eight_box', 1, 'learning', "
        "'match', 'remembered', 1900)",
      );
      await db.customStatement(
        "UPDATE study_sessions SET end_reason = 'interrupted' WHERE id = 's1'",
      );

      expect(
        (await rows(
          db,
          "SELECT kind FROM study_answers WHERE id = 'h3'",
        )).single.read<String>('kind'),
        'learning',
      );
    });

    test('browse can never be written as an answer mode', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      // BR-111: `browse` produces no action and writes no history row. The
      // CHECK is what makes that structural rather than a convention.
      await expectLater(
        db.customStatement(
          'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
          'scheduler_generation, kind, mode, "action", answered_at) '
          "VALUES ('h4', 'c1', 's1', 'eight_box', 1, 'learning', "
          "'browse', 'remembered', 1900)",
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('app_settings holds exactly one row and refuses a second', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      final row = (await rows(db, 'SELECT * FROM app_settings')).single;
      expect(row.read<int>('id'), 1);
      expect(row.read<int>('card_limit'), 20);
      expect(row.read<String>('new_card_order'), 'created');

      // Without the CHECK, "the settings" would mean "whichever row the query
      // read first".
      await expectLater(
        db.customStatement(
          'INSERT INTO app_settings (id, card_limit, new_card_order, '
          "updated_at) VALUES (2, 50, 'random', 0)",
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('a queue row cannot repeat a card inside one round', () async {
      final db = await upgradedFromSeededV4();
      addTearDown(db.close);

      Future<void> insert(int round, int position) => db.customStatement(
        'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
        'position, status) '
        "VALUES ('s1', 'match', $round, 'c1', $position, 'pending')",
      );

      await insert(1, 0);

      // A different round is a different turn, so the same card belongs there.
      await insert(2, 0);

      // The same round is not.
      await expectLater(insert(1, 5), throwsA(isA<Exception>()));
    });
  });

  group('every upgrade path reaches v5', () {
    // v1 and v2 predate `front_folded`, so they exercise the Dart backfill of
    // v3 on the way through; v3 and v4 do not. All four have to arrive at the
    // same schema, which is the property `migrateAndValidate` checks.
    for (final from in <int>[1, 2, 3, 4]) {
      test('v$from → v5', () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(from);
        final db = AppDatabase(schema.newConnection());
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, db.schemaVersion);
      });
    }
  });
}
