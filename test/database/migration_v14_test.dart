import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// v13 → v14 preserves session history while widening the end-reason CHECK for
/// a promoted subtree.
void main() {
  Future<AppDatabase> upgradedFromV13() async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(13);
    schema.rawDatabase.execute(
      'INSERT INTO decks (id, name, root_deck_id, content_type, scheduler_type, '
      'scheduler_version, scheduler_generation, sibling_position, created_at, updated_at) '
      "VALUES ('root', 'Root', 'root', 'deck', 'eight_box', 1, 1, 0, 1, 1)",
    );
    schema.rawDatabase.execute(
      'INSERT INTO study_sessions (id, deck_id, root_deck_id, scheduler_generation, '
      'status, end_reason, session_kind, current_mode, cursor, card_limit, started_at, ended_at) '
      "VALUES ('old', 'root', 'root', 1, 'invalidated', 'scheduler_changed', 'learning', 'self_assess', 0, 20, 1, 2)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);
    return db;
  }

  test('preserves old rows and admits only the new promotion reason', () async {
    final db = await upgradedFromV13();
    expect(
      (await db
              .customSelect(
                "SELECT end_reason FROM study_sessions WHERE id = 'old'",
              )
              .getSingle())
          .read<String>('end_reason'),
      'scheduler_changed',
    );
    await db.customStatement(
      'INSERT INTO study_sessions (id, deck_id, root_deck_id, scheduler_generation, '
      'status, end_reason, session_kind, current_mode, cursor, card_limit, started_at, ended_at) '
      "VALUES ('new', 'root', 'root', 1, 'invalidated', 'subtree_promoted', 'learning', 'self_assess', 0, 20, 3, 4)",
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO study_sessions (id, deck_id, root_deck_id, scheduler_generation, '
        'status, end_reason, session_kind, current_mode, cursor, card_limit, started_at, ended_at) '
        "VALUES ('bad', 'root', 'root', 1, 'invalidated', 'not_a_reason', 'learning', 'self_assess', 0, 20, 5, 6)",
      ),
      throwsA(isA<Object>()),
    );
  });
}
