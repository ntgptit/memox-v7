import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'support/test_database.dart';

/// The schema, read back from SQLite rather than from the `.drift` source.
///
/// Reading the declaration would only prove the file says what the file says.
/// `PRAGMA table_info` and friends report what the database actually built,
/// which is the only version that can disagree with `data-model.md`.
/// The source rules of the schema suite, split from `schema_test.dart` at
/// the 400-line guard on its own group boundary.
void main() {
  Future<List<Map<String, Object?>>> pragma(AppDatabase db, String sql) async {
    final rows = await db.customSelect(sql).get();

    return rows.map((row) => row.data).toList();
  }

  test('the database opens', () async {
    final db = openTestDatabase();

    expect(await db.customSelect('SELECT 1 AS one').getSingle(), isNotNull);
  });

  test('foreign keys are actually on', () async {
    // Not a declaration check. SQLite defaults this OFF per connection, and
    // without it every `ON DELETE CASCADE` in the schema is a comment: deletes
    // leave orphaned cards, states and history that every query still happily
    // walks past.
    final db = openTestDatabase();
    final rows = await pragma(db, 'PRAGMA foreign_keys');

    expect(rows.single['foreign_keys'], 1);
  });

  test('exactly the ten tables data-model.md specifies', () async {
    final db = openTestDatabase();
    final rows = await pragma(
      db,
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    expect(rows.map((row) => row['name']), <String>[
      'app_settings',
      'card_study_states',
      'card_tags',
      'cards',
      'decks',
      'delete_batches',
      'study_answers',
      'study_queue_items',
      'study_sessions',
      'tags',
    ]);
  });

  group('source rules', () {
    test('no Dart table class exists under core/database', () {
      // AD-02: schema lives in SQL so drift_dev type-checks every query against
      // it at build time. A Dart table class compiles fine and silently opts
      // that checking out.
      // Generated output is excluded: drift emits `class Decks extends Table`
      // into `.g.dart` itself. AD-02 is about which declaration a human writes,
      // and the generated class is the evidence that the `.drift` file was the
      // source rather than a violation of it.
      final offenders = <String>[
        for (final file in Directory(
          'lib/core/database',
        ).listSync(recursive: true))
          if (file is File && _isHandWrittenDart(file.path))
            if (RegExp(
              r'class\s+\w+\s+extends\s+Table\b',
            ).hasMatch(file.readAsStringSync()))
              file.path,
      ];

      expect(offenders, isEmpty);
    });

    test('connection.dart is the only production file that opens one', () {
      // AD-08. Scattered openers mean "where does the file live" and "is
      // encryption on" stop having a single answer.
      final opener = RegExp(r'NativeDatabase|driftDatabase\(|WasmDatabase');
      final offenders = <String>[
        for (final file in Directory('lib').listSync(recursive: true))
          if (file is File && _isHandWrittenDart(file.path))
            if (!file.path
                .replaceAll(r'\', '/')
                .endsWith('core/database/connection.dart'))
              if (opener.hasMatch(file.readAsStringSync())) file.path,
      ];

      expect(offenders, isEmpty);
    });
  });
}

/// True for Dart a person wrote, false for build output.
bool _isHandWrittenDart(String path) {
  if (!path.endsWith('.dart')) return false;

  return !path.endsWith('.g.dart') && !path.endsWith('.drift.dart');
}
