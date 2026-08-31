import 'package:drift/drift.dart' show QueryRow;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:sqlite3/common.dart';

import '../drift/generated/schema.dart';

/// v12 → v13 gives every existing sibling its historical creation order without
/// changing any tree pointer. Future reorders use that new value, but upgrade
/// itself is intentionally invisible to a learner.
void main() {
  Future<AppDatabase> upgradedFromV12(
    void Function(CommonDatabase raw) seed,
  ) async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(12);
    seed(schema.rawDatabase);

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    return db;
  }

  void insertDeck(
    CommonDatabase raw, {
    required String id,
    String? parentId,
    required String rootId,
    required int createdAt,
  }) {
    final parent = parentId == null ? 'NULL' : "'$parentId'";
    raw.execute(
      'INSERT INTO decks '
      '(id, name, parent_deck_id, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'first_answered_at, created_at, updated_at) '
      "VALUES ('$id', '$id', $parent, '$rootId', 'deck', "
      "'eight_box', 1, 1, NULL, $createdAt, $createdAt)",
    );
  }

  Future<List<QueryRow>> rows(AppDatabase db, String sql) =>
      db.customSelect(sql).get();

  test(
    'backfills each root and child sibling group by created_at then id',
    () async {
      final db = await upgradedFromV12((raw) {
        insertDeck(raw, id: 'root-b', rootId: 'root-b', createdAt: 20);
        insertDeck(raw, id: 'root-a', rootId: 'root-a', createdAt: 10);
        insertDeck(
          raw,
          id: 'child-c',
          parentId: 'root-a',
          rootId: 'root-a',
          createdAt: 30,
        );
        insertDeck(
          raw,
          id: 'child-a',
          parentId: 'root-a',
          rootId: 'root-a',
          createdAt: 10,
        );
        insertDeck(
          raw,
          id: 'child-b',
          parentId: 'root-a',
          rootId: 'root-a',
          createdAt: 10,
        );
      });

      expect(
        (await rows(
          db,
          'SELECT id, sibling_position FROM decks '
          'WHERE parent_deck_id IS NULL ORDER BY sibling_position, id',
        )).map(
          (row) => (row.read<String>('id'), row.read<int>('sibling_position')),
        ),
        <(String, int)>[('root-a', 0), ('root-b', 1)],
      );
      expect(
        (await rows(
          db,
          "SELECT id, sibling_position FROM decks WHERE parent_deck_id = 'root-a' "
          'ORDER BY sibling_position, id',
        )).map(
          (row) => (row.read<String>('id'), row.read<int>('sibling_position')),
        ),
        <(String, int)>[('child-a', 0), ('child-b', 1), ('child-c', 2)],
      );
      expect(
        (await rows(
          db,
          'PRAGMA integrity_check',
        )).single.read<String>('integrity_check'),
        'ok',
      );
      expect(await rows(db, 'PRAGMA foreign_key_check'), isEmpty);
    },
  );
}
