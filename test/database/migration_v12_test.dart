import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// The v11 → v12 upgrade: `end_reason` learns to say `scheduler_changed`.
///
/// **One rebuild, for one label — and the label is the whole point.**
/// `scheduler_reset` was carrying two different events. Reset learning progress
/// writes it, and so does BR-12's unlocked scheduler change, which is not a
/// reset: the generation stays put. Nothing was *lost* by the overload, because
/// `study_sessions.scheduler_generation` equals the root's after a change and
/// trails it after a reset — but reading the column on its own gives the wrong
/// answer unless you know that trick, and a value that needs a footnote is a
/// value that gets misread.
///
/// SQLite cannot alter a `CHECK`, so widening one is create-copy-drop. That
/// makes the two risks worth asserting separately: **rows must survive the
/// copy**, and **the new value must actually be accepted afterwards**. A
/// migration that silently dropped every session would still leave a database
/// whose `CHECK` admits the new label.
///
/// Rows are seeded through raw SQL against the v11 schema rather than through
/// today's generated classes, for the reason `migration_v10_test` gives: the
/// claim is that a row written by the *old* code survives, and raw SQL is the
/// only way to write one that owes nothing to the current build.
void main() {
  /// A v11 database holding two closed sessions, upgraded to the latest schema.
  Future<AppDatabase> upgradedFromV11() async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(11);

    // A deck to hang them on: `deck_id` is a foreign key, and although keys are
    // off during the migration they are on afterwards, when the assertions read.
    schema.rawDatabase.execute(
      'INSERT INTO decks '
      '(id, parent_deck_id, root_deck_id, name, content_type, '
      ' scheduler_type, scheduler_version, scheduler_generation, '
      ' created_at, updated_at) '
      "VALUES ('d1', NULL, 'd1', 'Korean', 'card', 'eight_box', 1, 0, 1, 1)",
    );

    for (final (String id, String? reason) in <(String, String?)>[
      ('s1', 'scheduler_reset'),
      ('s2', 'user_exit'),
    ]) {
      schema.rawDatabase.execute(
        'INSERT INTO study_sessions '
        '(id, deck_id, root_deck_id, scheduler_generation, status, end_reason, '
        ' session_kind, current_mode, cursor, card_limit, started_at, ended_at) '
        "VALUES ('$id', 'd1', 'd1', 0, 'invalidated', "
        "${reason == null ? 'NULL' : "'$reason'"}, "
        "'reviewing', 'self_assess', 0, 20, 1, 2)",
      );
    }

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    return db;
  }

  test('every session survives the rebuild', () async {
    // The failure this rules out is the quiet one: create-copy-drop that drops
    // without copying leaves a table with the right shape and no history in it.
    final db = await upgradedFromV11();

    final rows = await db
        .customSelect('SELECT id, end_reason FROM study_sessions ORDER BY id')
        .get();

    expect(rows.map((row) => row.data['id']), <String>['s1', 's2']);
    expect(rows.map((row) => row.data['end_reason']), <String>[
      'scheduler_reset',
      'user_exit',
    ]);
  });

  test('an existing scheduler_reset row is left alone', () async {
    // Deliberate, and the migration says so: this step cannot tell which of the
    // two events an old row recorded. The comparison that separates them needs
    // the root deck's generation *at the time*, which is not stored. Rewriting
    // on a guess would put a label on history that history does not support.
    final db = await upgradedFromV11();

    final row = await db
        .customSelect("SELECT end_reason FROM study_sessions WHERE id = 's1'")
        .getSingle();

    expect(row.data['end_reason'], 'scheduler_reset');
  });

  test('the widened CHECK accepts scheduler_changed', () async {
    final db = await upgradedFromV11();

    await db.customStatement(
      'INSERT INTO study_sessions '
      '(id, deck_id, root_deck_id, scheduler_generation, status, end_reason, '
      ' session_kind, current_mode, cursor, card_limit, started_at, ended_at) '
      "VALUES ('s3', 'd1', 'd1', 0, 'invalidated', 'scheduler_changed', "
      "'reviewing', 'self_assess', 0, 20, 3, 4)",
    );

    final row = await db
        .customSelect("SELECT end_reason FROM study_sessions WHERE id = 's3'")
        .getSingle();

    expect(row.data['end_reason'], 'scheduler_changed');
  });

  test('the CHECK is still a CHECK', () async {
    // The other half. A rebuild that dropped the constraint would pass every
    // assertion above and accept anything at all, which is worse than the
    // overload this milestone set out to fix.
    final db = await upgradedFromV11();

    await expectLater(
      db.customStatement(
        'INSERT INTO study_sessions '
        '(id, deck_id, root_deck_id, scheduler_generation, status, end_reason, '
        ' session_kind, current_mode, cursor, card_limit, started_at, ended_at) '
        "VALUES ('s4', 'd1', 'd1', 0, 'invalidated', 'not_a_reason', "
        "'reviewing', 'self_assess', 0, 20, 5, 6)",
      ),
      throwsA(isA<Object>()),
    );
  });
}
