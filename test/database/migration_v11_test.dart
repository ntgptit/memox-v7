// `isNull` is a matcher here, and drift exports a column predicate by the same
// name. Hiding it keeps the assertions readable rather than qualifying each one.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:sqlite3/common.dart';

import '../drift/generated/schema.dart';

/// The v10 → v11 upgrade: Trash (BR-256…BR-267, AD-22).
///
/// Two properties, and the second is the one that would be expensive to get
/// wrong:
///
/// 1. **Everything that existed stays active.** `delete_batch_id` arrives NULL
///    on every deck and every card, which is precisely "not deleted". A
///    migration that defaulted it to anything else, or that dropped rows during
///    the `study_sessions` rebuild, would hide a user's whole library behind a
///    feature they have never used.
/// 2. **The `end_reason` CHECK actually widened.** SQLite cannot alter a CHECK,
///    so this is a create-copy-drop-rename; a rebuild that copied the *old*
///    constraint would compile, pass `migrateAndValidate` against a stale dump,
///    and only fail the first time a deletion tried to close a session.
///
/// Seeded through **raw SQL against the v7 schema**, so nothing here owes
/// anything to the current build.
void main() {
  /// A v7 database with [seed] applied, upgraded to the latest schema.
  Future<AppDatabase> upgradedFromV7(
    void Function(CommonDatabase raw) seed,
  ) async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(7);
    seed(schema.rawDatabase);

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    return db;
  }

  /// One root, one `card` sub-deck, one card and its study state — the smallest
  /// tree that has a row in both tables the migration touches.
  void seedTree(CommonDatabase raw) {
    raw.execute(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'first_answered_at, created_at, updated_at) '
      "VALUES ('root', 'Root', 'root', 'deck', 'eight_box', 1, 1, NULL, 7, 7)",
    );
    raw.execute(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('leaf', 'Leaf', 'root', 'root', 'card', 7, 7)",
    );
    raw.execute(
      'INSERT INTO cards (id, deck_id, front, back, front_folded, back_folded, '
      'created_at, updated_at) '
      "VALUES ('c1', 'leaf', 'F', 'B', 'f', 'b', 7, 7)",
    );
    raw.execute(
      'INSERT INTO card_study_states (card_id, scheduler_type, '
      'scheduler_version, scheduler_generation, learned_at, due_at, '
      'answer_count, lapse_count, current_box) '
      "VALUES ('c1', 'eight_box', 1, 1, NULL, NULL, 0, 0, 1)",
    );
  }

  Future<List<QueryRow>> rows(AppDatabase db, String sql) =>
      db.customSelect(sql).get();

  group('v10 → v11 · old rows stay active', () {
    test('every deck and card upgrades to delete_batch_id NULL', () async {
      final db = await upgradedFromV7(seedTree);

      final deckTombstones = await rows(
        db,
        'SELECT id FROM decks WHERE delete_batch_id IS NOT NULL',
      );
      final cardTombstones = await rows(
        db,
        'SELECT id FROM cards WHERE delete_batch_id IS NOT NULL',
      );

      expect(deckTombstones, isEmpty);
      expect(cardTombstones, isEmpty);
    });

    test('no row is lost and none is invented', () async {
      final db = await upgradedFromV7(seedTree);

      expect(
        (await rows(
          db,
          'SELECT id FROM decks ORDER BY id',
        )).map((row) => row.read<String>('id')),
        <String>['leaf', 'root'],
      );
      expect(
        (await rows(
          db,
          'SELECT id FROM cards',
        )).map((row) => row.read<String>('id')),
        <String>['c1'],
      );
      // The study state is reached through the card's foreign key, so a
      // migration that dropped and recreated `cards` would take it with it.
      expect(
        await rows(db, 'SELECT card_id FROM card_study_states'),
        hasLength(1),
      );
    });

    test('the batch table arrives empty', () async {
      final db = await upgradedFromV7(seedTree);

      expect(await rows(db, 'SELECT id FROM delete_batches'), isEmpty);
    });
  });

  group('v10 → v11 · the session rebuild', () {
    /// A v7 session in every legal ending, so the copy has something to lose.
    void seedSessions(CommonDatabase raw) {
      seedTree(raw);
      raw.execute(
        'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
        'scheduler_generation, status, end_reason, session_kind, current_mode, '
        'cursor, card_limit, started_at, ended_at) '
        "VALUES ('s1', 'root', 'root', 1, 'abandoned', 'user_exit', "
        "'reviewing', 'self_assess', 3, 20, 100, 200)",
      );
      raw.execute(
        'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
        'scheduler_generation, status, end_reason, session_kind, current_mode, '
        'cursor, card_limit, started_at, ended_at) '
        "VALUES ('s2', 'root', 'root', 1, 'in_progress', NULL, "
        "'learning', 'browse', 0, 20, 300, NULL)",
      );
    }

    test('every column of every session survives the copy', () async {
      final db = await upgradedFromV7(seedSessions);

      final all = await rows(
        db,
        'SELECT id, deck_id, root_deck_id, scheduler_generation, status, '
        'end_reason, session_kind, current_mode, cursor, card_limit '
        'FROM study_sessions ORDER BY id',
      );

      expect(all, hasLength(2));
      expect(all.first.read<String>('id'), 's1');
      expect(all.first.read<String>('status'), 'abandoned');
      expect(all.first.read<String>('end_reason'), 'user_exit');
      expect(all.first.read<String>('session_kind'), 'reviewing');
      expect(all.first.read<String>('current_mode'), 'self_assess');
      expect(all.first.read<int>('cursor'), 3);
      expect(all.first.read<int>('card_limit'), 20);
      expect(all.last.read<String>('id'), 's2');
      expect(all.last.read<String?>('end_reason'), null);
    });

    test('the widened CHECK accepts content_deleted', () async {
      final db = await upgradedFromV7(seedSessions);

      // The point of the rebuild. Under v7's constraint this INSERT throws.
      await db.customStatement(
        'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
        'scheduler_generation, status, end_reason, session_kind, current_mode, '
        'cursor, card_limit, started_at, ended_at) '
        "VALUES ('s3', 'root', 'root', 1, 'invalidated', 'content_deleted', "
        "'reviewing', 'self_assess', 0, 20, 400, 500)",
      );

      final row = await db
          .customSelect("SELECT end_reason FROM study_sessions WHERE id = 's3'")
          .getSingle();

      expect(row.read<String>('end_reason'), 'content_deleted');
    });

    test('the CHECK still refuses a reason nothing writes', () async {
      final db = await upgradedFromV7(seedSessions);

      // A rebuild that dropped the constraint instead of widening it would pass
      // every assertion above and this one is what notices.
      await expectLater(
        db.customStatement(
          'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
          'scheduler_generation, status, end_reason, session_kind, '
          'current_mode, cursor, card_limit, started_at, ended_at) '
          "VALUES ('s4', 'root', 'root', 1, 'invalidated', 'made_up', "
          "'reviewing', 'self_assess', 0, 20, 400, 500)",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('the answers pointing at a session are untouched', () async {
      final db = await upgradedFromV7((raw) {
        seedSessions(raw);
        raw.execute(
          'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
          'scheduler_generation, kind, mode, "action", answered_at) '
          "VALUES ('h1', 'c1', 's1', 'eight_box', 1, 'scheduled', "
          "'self_assess', 'remembered', 150)",
        );
      });

      // `study_answers.session_id` references the table that was dropped and
      // recreated. Foreign keys are off during a migration, which is what makes
      // that safe — and this is the assertion that it really was.
      final answer = await db
          .customSelect("SELECT session_id FROM study_answers WHERE id = 'h1'")
          .getSingle();

      expect(answer.read<String>('session_id'), 's1');
    });
  });

  group('v10 → v11 · the new structure', () {
    test('purging a batch cascades to its rows', () async {
      final db = await upgradedFromV7(seedTree);

      await db.customStatement(
        'INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) '
        "VALUES ('b1', 'card', 'c1', 900)",
      );
      await db.customStatement(
        "UPDATE cards SET delete_batch_id = 'b1' WHERE id = 'c1'",
      );

      await db.customStatement("DELETE FROM delete_batches WHERE id = 'b1'");

      // The card goes with the batch, and its study state goes with the card.
      expect(await rows(db, 'SELECT id FROM cards'), isEmpty);
      expect(await rows(db, 'SELECT card_id FROM card_study_states'), isEmpty);
    });

    test('the batch table refuses an item type nothing writes', () async {
      final db = await upgradedFromV7(seedTree);

      await expectLater(
        db.customStatement(
          'INSERT INTO delete_batches (id, item_type, root_item_id, '
          "deleted_at) VALUES ('b2', 'tag', 'c1', 900)",
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  test('a fresh database runs no migration', () async {
    // Cheap, and it catches an `if (from < N)` written as `if (from <= N)`.
    // The number moved to 13 at M100.15; what this asserts is unchanged — a
    // database created at the current version takes no upgrade step.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 13);
    expect(await rows(db, 'SELECT id FROM delete_batches'), isEmpty);
  });
}
