import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// The v7 → v8 upgrade: the two reminder columns (BR-182, BR-183, M99.23).
///
/// **Additive, and the defaults are the specified defaults.** An existing
/// install must upgrade into exactly the state a fresh install starts in — off,
/// at 20:00 — because BR-182 makes the reminder opt-in and an upgrade is not an
/// opt-in.
///
/// The settings row is seeded through **raw SQL against the v7 schema**, not
/// through today's generated classes: the point is that a row written by the
/// old code survives, and raw SQL is the only way to write one that owes
/// nothing to the current build. The schema snapshots also do not run the v5
/// insert that creates the row, so without this there is nothing to upgrade.
void main() {
  /// A v7 database holding the one settings row, upgraded to the latest schema.
  Future<AppDatabase> upgradedFromV7() async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(7);
    schema.rawDatabase.execute(
      'INSERT INTO app_settings (id, card_limit, new_card_order, updated_at) '
      "VALUES (1, 20, 'created', 7)",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    return db;
  }

  test('the two columns arrive with BR-182 and BR-183 defaults', () async {
    final db = await upgradedFromV7();

    final row = await db
        .customSelect(
          'SELECT reminder_enabled, reminder_minute_of_day FROM app_settings '
          'WHERE id = 1',
        )
        .getSingle();

    expect(row.data['reminder_enabled'], 0);
    expect(row.data['reminder_minute_of_day'], 1200);
  });

  test('the study columns are carried over untouched', () async {
    final db = await upgradedFromV7();

    final row = await db
        .customSelect('SELECT card_limit, new_card_order FROM app_settings')
        .getSingle();

    expect(row.data['card_limit'], 20);
    expect(row.data['new_card_order'], 'created');
  });

  test('a fresh install starts in the same state as an upgraded one', () async {
    // `onCreate` and `onUpgrade` are two paths to one schema, and the reminder
    // is the kind of default that is easy to set in one and forget in the
    // other.
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);

    final row = await fresh
        .customSelect(
          'SELECT reminder_enabled, reminder_minute_of_day FROM app_settings',
        )
        .getSingle();

    expect(row.data['reminder_enabled'], 0);
    expect(row.data['reminder_minute_of_day'], 1200);
  });

  group('the CHECKs are real, not documentation', () {
    test('an out-of-range minute is refused by the database', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // BR-183's range lives in the type *and* in the column: a value that
      // somehow bypassed `ReminderTime` must still not land.
      await expectLater(
        db.customUpdate(
          'UPDATE app_settings SET reminder_minute_of_day = ? WHERE id = 1',
          variables: const <Variable<Object>>[Variable<int>(1440)],
        ),
        throwsA(anything),
      );
    });

    test('a non-boolean enabled flag is refused', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await expectLater(
        db.customUpdate(
          'UPDATE app_settings SET reminder_enabled = ? WHERE id = 1',
          variables: const <Variable<Object>>[Variable<int>(2)],
        ),
        throwsA(anything),
      );
    });
  });
}
