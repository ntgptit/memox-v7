import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// Migration foundation, built at v1 so that v2 has something to be tested
/// against.
///
/// There is no migration here yet, and that is the point. The expensive mistake
/// is writing the first migration with no snapshot of the schema it starts from;
/// `drift_schemas/drift_schema_v1.json` is committed precisely because once the
/// source moves on it cannot be regenerated.
void main() {
  test('the schema version is 1', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 1);
  });

  test('onCreate builds v1 from an empty database', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Opening runs onCreate. Reading the table list back proves it ran rather
    // than that the constructor returned.
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();

    expect(tables.map((row) => row.data['name']), <String>[
      'card_review_states',
      'cards',
      'decks',
      'review_history',
      'study_sessions',
    ]);
  });

  test('foreign keys are on immediately after creation', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();

    expect(row.data['foreign_keys'], 1);
  });

  test('the committed v1 snapshot matches what the code builds', () async {
    // The check that gives the snapshot its value. If the `.drift` files drift
    // away from the dump, the first real migration would be written against a
    // starting point that never existed.
    final verifier = SchemaVerifier(GeneratedHelper());
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection.executor);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });

  test('there is no v2', () {
    // A placeholder `onUpgrade` written against a version that does not exist
    // is a guess that reads like a decision.
    expect(GeneratedHelper.versions, <int>[1]);
  });
}
