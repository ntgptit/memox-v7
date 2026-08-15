import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:sqlite3/common.dart';

import '../drift/generated/schema.dart';

/// The v8 → v9 upgrade: `app_settings.theme_mode` and `app_settings.language`
/// (BR-186, BR-187).
///
/// **Additive, and the tests are here to prove it stayed that way.** Two
/// `ALTER TABLE ADD COLUMN` with `DEFAULT 'system'`; no row is rewritten, and
/// the values a user already chose for the two study defaults survive
/// untouched.
///
/// Seeded through **raw SQL against the v8 schema**, because the claim is about
/// rows written by the *old* build — a row inserted through today's generated
/// companions would already have the new columns and would prove nothing.
void main() {
  /// A v8 database with [seed] applied, upgraded to the latest schema.
  ///
  /// `migrateAndValidate` is what makes this more than a smoke test: it
  /// compares the upgraded database against the current declaration, so a
  /// `CHECK` or a type that the `ALTER` spelled differently from
  /// `tables/settings.drift` fails here rather than on a user's device.
  Future<AppDatabase> upgradedFromV7(
    void Function(CommonDatabase raw) seed,
  ) async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(8);
    seed(schema.rawDatabase);

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    return db;
  }

  /// Replaces the seeded settings row with one holding [cardLimit] and
  /// [newCardOrder].
  ///
  /// A `DELETE` then an `INSERT` rather than an `UPDATE`: the v5 migration
  /// seeds the row, so a v8 database already has one and an `INSERT` alone
  /// would break the primary key.
  void seedSettings(
    CommonDatabase raw, {
    required int cardLimit,
    required String newCardOrder,
  }) {
    raw
      ..execute('DELETE FROM app_settings')
      ..execute(
        'INSERT INTO app_settings (id, card_limit, new_card_order, updated_at) '
        "VALUES (1, $cardLimit, '$newCardOrder', 7)",
      );
  }

  Future<Map<String, Object?>> settingsRow(AppDatabase db) async {
    final rows = await db.customSelect('SELECT * FROM app_settings').get();

    return rows.single.data;
  }

  group('v8 → v9', () {
    test(
      'a v8 database upgrades and validates against the v9 declaration',
      () async {
        final db = await upgradedFromV7(
          (raw) => seedSettings(raw, cardLimit: 20, newCardOrder: 'created'),
        );

        expect(await settingsRow(db), isNotNull);
      },
    );

    test('both new columns default to system, which is what v8 did', () async {
      // Not a placeholder: every build before v9 followed the platform for
      // both, because it had no stored choice to follow instead. `'system'` is
      // the truthful record of that, so no `UPDATE` is needed anywhere.
      final db = await upgradedFromV7(
        (raw) => seedSettings(raw, cardLimit: 20, newCardOrder: 'created'),
      );

      final row = await settingsRow(db);

      expect(row['theme_mode'], 'system');
      expect(row['language'], 'system');
    });

    test('the two study defaults survive the upgrade unchanged', () async {
      // The failure this catches is a migration that rebuilt the table instead
      // of altering it and re-seeded the defaults on the way — which would
      // silently reset a card limit the user chose.
      final db = await upgradedFromV7(
        (raw) => seedSettings(raw, cardLimit: 35, newCardOrder: 'random'),
      );

      final row = await settingsRow(db);

      expect(row['card_limit'], 35);
      expect(row['new_card_order'], 'random');
    });

    test('the table still holds exactly one row', () async {
      final db = await upgradedFromV7(
        (raw) => seedSettings(raw, cardLimit: 20, newCardOrder: 'created'),
      );

      final rows = await db
          .customSelect('SELECT COUNT(*) AS n FROM app_settings')
          .getSingle();

      expect(rows.data['n'], 1);
    });

    test('the CHECK on theme_mode survived the ALTER', () async {
      // SQLite applies a column constraint declared in `ADD COLUMN`, but it is
      // the kind of thing that is easy to write and easy to lose — and losing
      // it is invisible until a value nothing can read is already stored.
      final db = await upgradedFromV7(
        (raw) => seedSettings(raw, cardLimit: 20, newCardOrder: 'created'),
      );

      expect(
        db.customStatement(
          "UPDATE app_settings SET theme_mode = 'sepia' WHERE id = 1",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('the CHECK on language survived the ALTER', () async {
      final db = await upgradedFromV7(
        (raw) => seedSettings(raw, cardLimit: 20, newCardOrder: 'created'),
      );

      expect(
        db.customStatement(
          "UPDATE app_settings SET language = 'fr' WHERE id = 1",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('nothing outside app_settings is touched', () async {
      // The upgrade names one table. This is the assertion that catches a
      // future edit adding a second statement to `_upgradeToV9` without saying
      // so — decks, cards and study state are what a settings migration has no
      // business reaching.
      final db = await upgradedFromV7((raw) {
        seedSettings(raw, cardLimit: 20, newCardOrder: 'created');
        raw
          ..execute(
            'INSERT INTO decks (id, name, root_deck_id, content_type, '
            'scheduler_type, scheduler_version, scheduler_generation, '
            'study_config, created_at, updated_at) '
            "VALUES ('root', 'Korean', 'root', 'deck', 'eight_box', 1, 1, "
            "'{\"card_limit\":30,\"new_card_order\":\"random\"}', 7, 7)",
          )
          ..execute(
            'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
            'content_type, created_at, updated_at) '
            "VALUES ('words', 'Words', 'root', 'root', 'card', 7, 7)",
          )
          ..execute(
            'INSERT INTO cards (id, deck_id, front, back, front_folded, '
            'back_folded, created_at, updated_at) '
            "VALUES ('c1', 'words', '연구자', 'researcher', '연구자', "
            "'researcher', 7, 7)",
          );
      });

      final deck = await db
          .customSelect("SELECT * FROM decks WHERE id = 'root'")
          .getSingle();
      final cards = await db.customSelect('SELECT * FROM cards').get();

      // The deck override in particular: BR-184 says changing the app-wide
      // options must never touch it, and a migration is the one place that
      // could do it to every deck at once.
      expect(deck.data['study_config'], contains('"card_limit":30'));
      expect(cards, hasLength(1));
    });
  });
}
