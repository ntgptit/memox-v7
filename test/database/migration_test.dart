import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// The v1 → v2 migration, and the snapshots that make it testable.
///
/// v1 was dumped at M4.4 with no migration to write yet, on the argument that
/// the expensive mistake is writing the first migration with no snapshot of the
/// schema it starts from. This is that argument being cashed: every upgrade test
/// below starts from `drift_schemas/drift_schema_v1.json`, which could not have
/// been regenerated once the `.drift` files moved on.
void main() {
  test('the schema version is 2', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 2);
  });

  test('onCreate builds the whole of v2 from an empty database', () async {
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
      'card_review_states',
      'card_tags',
      'cards',
      'decks',
      'review_history',
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

  test('v1 and v2 are the versions that exist', () {
    expect(GeneratedHelper.versions, <int>[1, 2]);
  });

  group('v1 → v2', () {
    /// A v1 database holding one deck and one card, then upgraded to v2.
    ///
    /// Seeded through raw SQL rather than the generated v1 classes: the point
    /// is that rows written by the *old* schema survive, and raw SQL is the
    /// only way to write a row that owes nothing to today's code.
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
      await verifier.migrateAndValidate(db, 2);

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
}
