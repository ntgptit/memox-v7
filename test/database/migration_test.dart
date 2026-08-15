import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// The upgrade path, and the snapshots that make it testable.
///
/// v1 was dumped at M4.4 with no migration to write yet, on the argument that
/// the expensive mistake is writing the first migration with no snapshot of the
/// schema it starts from. This is that argument being cashed: every upgrade test
/// below starts from `drift_schemas/drift_schema_v1.json`, which could not have
/// been regenerated once the `.drift` files moved on.
void main() {
  test('the schema version is 10', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 10);
  });

  test('onCreate builds the whole of v9 from an empty database', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Reading the table list back proves onCreate ran rather than that the
    // constructor returned.
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();

    expect(tables.map((row) => row.data['name']), <String>[
      'app_settings',
      'card_study_states',
      'card_tags',
      'cards',
      'decks',
      'study_answers',
      'study_queue_items',
      'study_sessions',
      'tags',
    ]);
  });

  test('foreign keys are on immediately after creation', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();

    expect(row.data['foreign_keys'], 1);
  });

  test('both committed snapshots match what the code builds', () async {
    // If the `.drift` files drift away from a dump, a migration is written
    // against a starting point that never existed.
    for (final version in GeneratedHelper.versions) {
      final verifier = SchemaVerifier(GeneratedHelper());
      final connection = await verifier.startAt(version);
      final db = AppDatabase(connection.executor);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, version);
    }
  });

  test('v1 through v10 are the versions that exist', () {
    expect(GeneratedHelper.versions, <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  });

  group('what v2 added, seen from a v1 database', () {
    /// A v1 database holding one deck and one card, then upgraded to the latest
    /// schema.
    ///
    /// Seeded through raw SQL rather than the generated v1 classes: the point
    /// is that rows written by the *old* schema survive, and raw SQL is the
    /// only way to write a row that owes nothing to today's code.
    ///
    /// **The target is `db.schemaVersion`, not a literal 2.** `onUpgrade`
    /// branches on `from` alone, which is the right shape — in production `to`
    /// is always the newest version, so a `to >= n` guard would add a branch no
    /// device ever takes. The consequence is that a v1 database cannot be
    /// stopped at v2: it runs every step. Naming the latest version here also
    /// keeps these tests from breaking on the day a v4 arrives; what they assert
    /// is that a v1 row survives the whole path, not that it survives one step.
    Future<AppDatabase> upgradedFromSeededV1() async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(1);

      schema.rawDatabase.execute(
        'INSERT INTO decks (id, name, root_deck_id, content_type, '
        'created_at, updated_at) '
        "VALUES ('d1', 'Korean', 'd1', 'card', 0, 0)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO cards (id, deck_id, front, back, created_at, updated_at) '
        "VALUES ('c1', 'd1', '연구자', 'researcher', 0, 0)",
      );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);

      return db;
    }

    test('the row written under v1 is still there, unchanged', () async {
      final db = await upgradedFromSeededV1();

      final card = await db
          .customSelect(
            'SELECT front, back FROM cards WHERE id = ?',
            variables: const <Variable<Object>>[Variable<String>('c1')],
          )
          .getSingle();

      expect(card.data['front'], '연구자');
      expect(card.data['back'], 'researcher');
    });

    test('a card that predates the flag reads as not flagged', () async {
      // `DEFAULT 0` rather than a backfill. A card written before the column
      // existed genuinely is unmarked, so the default is the truth rather than
      // a value invented to fill a hole.
      final db = await upgradedFromSeededV1();

      final card = await db
          .customSelect('SELECT is_flagged FROM cards')
          .getSingle();

      expect(card.data['is_flagged'], 0);
    });

    test('the three optional fields arrive NULL, not empty string', () async {
      // The distinction the schema keeps: NULL is "never filled", `''` would be
      // "filled then cleared". A migration that wrote `''` would erase it.
      final db = await upgradedFromSeededV1();

      final card = await db
          .customSelect('SELECT example, hint, pronunciation FROM cards')
          .getSingle();

      expect(card.data['example'], isNull);
      expect(card.data['hint'], isNull);
      expect(card.data['pronunciation'], isNull);
    });

    test('the two tag tables arrive empty and usable', () async {
      final db = await upgradedFromSeededV1();

      await db.customStatement(
        'INSERT INTO tags (id, name, name_folded, created_at) '
        "VALUES ('t1', 'Noun', 'noun', 0)",
      );
      await db.customStatement(
        "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1')",
      );

      final joined = await db
          .customSelect(
            'SELECT t.name FROM card_tags ct '
            'JOIN tags t ON t.id = ct.tag_id WHERE ct.card_id = ?',
            variables: const <Variable<Object>>[Variable<String>('c1')],
          )
          .getSingle();

      expect(joined.data['name'], 'Noun');
    });

    test('deleting the card takes its tag links with it', () async {
      // Both foreign keys cascade, so neither side leaves an orphan. Checked
      // after a migration rather than on a fresh v2 database, because
      // `addColumn`/`createTable` running inside a migration is exactly where a
      // missing `PRAGMA foreign_keys` would show up.
      final db = await upgradedFromSeededV1();

      await db.customStatement(
        'INSERT INTO tags (id, name, name_folded, created_at) '
        "VALUES ('t1', 'Noun', 'noun', 0)",
      );
      await db.customStatement(
        "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1')",
      );
      await db.customStatement("DELETE FROM cards WHERE id = 'c1'");

      final links = await db.customSelect('SELECT * FROM card_tags').get();
      final tags = await db.customSelect('SELECT * FROM tags').get();

      expect(links, isEmpty, reason: 'the link outlived the card');
      expect(tags, hasLength(1), reason: 'the tag itself is not the card');
    });
  });

  group('v2 → v3 · folded search columns', () {
    /// A v2 database holding two cards — one uppercase Vietnamese, one plain
    /// ASCII — then upgraded to v3.
    ///
    /// Raw SQL again, for the reason the v1 seeder gives: the claim is that rows
    /// written by the *old* schema get correct folded values, and only a row
    /// that owes nothing to today's code can test that.
    Future<AppDatabase> upgradedFromSeededV2() async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(2);

      schema.rawDatabase.execute(
        'INSERT INTO decks (id, name, root_deck_id, content_type, '
        'created_at, updated_at) '
        "VALUES ('d1', 'Korean', 'd1', 'card', 0, 0)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO cards (id, deck_id, front, back, created_at, updated_at) '
        "VALUES ('c1', 'd1', 'CÔNG NGHỆ', 'TECHNOLOGY', 0, 0)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO cards (id, deck_id, front, back, created_at, updated_at) '
        "VALUES ('c2', 'd1', 'Ephemeral', 'short-lived', 0, 0)",
      );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);

      return db;
    }

    Future<QueryRow> foldedRow(AppDatabase db, String id) => db
        .customSelect(
          'SELECT front, back, front_folded, back_folded FROM cards '
          'WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingle();

    test(
      'the backfill folds non-ASCII text, which lower() would not',
      () async {
        // The whole point of the column pair. `UPDATE … SET front_folded =
        // lower(front)` would have written 'cÔng nghệ' here and looked like it
        // worked.
        final row = await foldedRow(await upgradedFromSeededV2(), 'c1');

        expect(row.data['front_folded'], 'công nghệ');
        expect(row.data['back_folded'], 'technology');
      },
    );

    test('the displayed text is untouched by the backfill', () async {
      final row = await foldedRow(await upgradedFromSeededV2(), 'c1');

      expect(row.data['front'], 'CÔNG NGHỆ');
      expect(row.data['back'], 'TECHNOLOGY');
    });

    test('ASCII rows fold too, and are not left on the default', () async {
      final row = await foldedRow(await upgradedFromSeededV2(), 'c2');

      expect(row.data['front_folded'], 'ephemeral');
    });

    test('no card is left holding the empty default', () async {
      final db = await upgradedFromSeededV2();

      final unfolded = await db
          .customSelect(
            "SELECT id FROM cards WHERE front <> '' AND front_folded = ''",
          )
          .get();

      expect(unfolded, isEmpty, reason: 'the backfill skipped a row');
    });

    test('a v1 database reaches v3 in one launch', () async {
      // The skipped-version path: a user who has not opened the app since v1
      // runs both steps back to back, and the v3 backfill has to cope with the
      // rows v2 created rather than with a fresh table.
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(1);

      schema.rawDatabase.execute(
        'INSERT INTO decks (id, name, root_deck_id, content_type, '
        'created_at, updated_at) '
        "VALUES ('d1', 'Korean', 'd1', 'card', 0, 0)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO cards (id, deck_id, front, back, created_at, updated_at) '
        "VALUES ('c1', 'd1', 'ĐỘNG TỪ', 'verb', 0, 0)",
      );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);

      final row = await foldedRow(db, 'c1');
      expect(row.data['front_folded'], 'động từ');
    });
  });
}
