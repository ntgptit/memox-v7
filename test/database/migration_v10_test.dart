import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// The v9 → v10 upgrade: the three reminder columns (BR-218, BR-219, BR-221,
/// M99.29).
///
/// **Additive, and the defaults are the specified defaults.** An existing
/// install must upgrade into exactly the state a fresh install starts in — off,
/// at 20:00, nothing delivered — because BR-218 makes the reminder opt-in and
/// an upgrade is not an opt-in.
///
/// **One step, where the source branch had two.** It added the first two
/// columns at its v8 and the delivery stamp at its v9; both numbers belong to
/// other features here, so the columns arrive together at v10 and this file
/// asserts the single hop. Starting from v9 rather than v7 is the point: the
/// step under test is the one a released install actually takes.
///
/// The settings row is seeded through **raw SQL against the v9 schema**, not
/// through today's generated classes: the point is that a row written by the
/// old code survives, and raw SQL is the only way to write one that owes
/// nothing to the current build. The schema snapshots also do not run the v5
/// insert that creates the row, so without this there is nothing to upgrade.
void main() {
  /// A v9 database holding the one settings row, upgraded to the latest schema.
  Future<AppDatabase> upgradedFromV9() async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(9);
    // `theme_mode` and `language` arrived at v9 and are NOT NULL, so a row
    // written against that schema names them. Leaving them out fails the
    // insert, and the test would then be reporting on a database it never
    // built.
    schema.rawDatabase.execute(
      'INSERT INTO app_settings '
      '(id, card_limit, new_card_order, theme_mode, language, updated_at) '
      "VALUES (1, 20, 'created', 'system', 'system', 9)",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    return db;
  }

  test('the two columns arrive with BR-218 and BR-219 defaults', () async {
    final db = await upgradedFromV9();

    final row = await db
        .customSelect(
          'SELECT reminder_enabled, reminder_minute_of_day FROM app_settings '
          'WHERE id = 1',
        )
        .getSingle();

    expect(row.data['reminder_enabled'], 0);
    expect(row.data['reminder_minute_of_day'], 1200);
  });

  test('v10 adds the delivery stamp, and it starts empty', () async {
    // NULL is the truth for a database that predates the column: nothing has
    // been delivered. A default would make the first launch after the upgrade
    // treat a day as already served and stay silent for it (BR-221).
    final db = await upgradedFromV9();

    final row = await db
        .customSelect(
          'SELECT reminder_last_delivered_at FROM app_settings WHERE id = 1',
        )
        .getSingle();

    expect(row.data['reminder_last_delivered_at'], isNull);
  });

  test('the study columns are carried over untouched', () async {
    final db = await upgradedFromV9();

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

      // BR-219's range lives in the type *and* in the column: a value that
      // somehow bypassed `ReminderTime` must still not land.
      await expectLater(
        db.customUpdate(
          'UPDATE app_settings SET reminder_minute_of_day = ? WHERE id = 1',
          variables: const <Variable<Object>>[Variable<int>(1440)],
        ),
        throwsA(anything),
      );
    });

    test('a negative minute is refused too', () async {
      // The upper bound alone does not pin the range: a migration shipping
      // `CHECK (reminder_minute_of_day <= 1439)` — the `>= 0` half dropped, or
      // the whole range reversed — passes every other case in this file and
      // still lets a negative minute-of-day land, which BR-219's `0…1439`
      // domain forbids.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await expectLater(
        db.customUpdate(
          'UPDATE app_settings SET reminder_minute_of_day = ? WHERE id = 1',
          variables: const <Variable<Object>>[Variable<int>(-1)],
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
