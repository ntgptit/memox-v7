import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'support/test_database.dart';

/// The schema, read back from SQLite rather than from the `.drift` source.
///
/// Reading the declaration would only prove the file says what the file says.
/// `PRAGMA table_info` and friends report what the database actually built,
/// which is the only version that can disagree with `data-model.md`.
void main() {
  Future<List<Map<String, Object?>>> pragma(AppDatabase db, String sql) async {
    final rows = await db.customSelect(sql).get();

    return rows.map((row) => row.data).toList();
  }

  Future<List<String>> columnsOf(AppDatabase db, String table) async {
    final rows = await pragma(db, 'PRAGMA table_info($table)');

    return rows.map((row) => row['name']! as String).toList();
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

  group('columns match data-model.md', () {
    const expected = <String, List<String>>{
      'decks': <String>[
        'id',
        'name',
        'parent_deck_id',
        'root_deck_id',
        'content_type',
        'owner_id',
        'scheduler_type',
        'scheduler_version',
        'scheduler_config',
        'scheduler_generation',
        'first_answered_at',
        'study_config',
        'source_template_id',
        'source_template_version',
        'delete_batch_id',
        'created_at',
        'updated_at',
      ],
      'cards': <String>[
        'id',
        'deck_id',
        'front',
        'back',
        'front_folded',
        'back_folded',
        'is_flagged',
        'example',
        'hint',
        'pronunciation',
        'delete_batch_id',
        'created_at',
        'updated_at',
      ],
      'tags': <String>['id', 'name', 'name_folded', 'owner_id', 'created_at'],
      'card_tags': <String>['card_id', 'tag_id'],
      'card_study_states': <String>[
        'card_id',
        'scheduler_type',
        'scheduler_version',
        'scheduler_generation',
        'learned_at',
        'due_at',
        'last_answered_at',
        'answer_count',
        'lapse_count',
        'current_box',
        'ease_factor',
        'interval_days',
        'repetitions',
      ],
      'study_answers': <String>[
        'id',
        'card_id',
        'session_id',
        'scheduler_type',
        'scheduler_generation',
        'kind',
        'mode',
        'outcome_reason',
        'comparison_version',
        'used_hint',
        'action',
        'answered_at',
        'next_due_at',
        'previous_box',
        'next_box',
        'previous_ease_factor',
        'next_ease_factor',
        'previous_interval_days',
        'next_interval_days',
      ],
      'study_sessions': <String>[
        'id',
        'deck_id',
        'root_deck_id',
        'scheduler_generation',
        'status',
        'end_reason',
        'session_kind',
        'current_mode',
        'cursor',
        'card_limit',
        'started_at',
        'ended_at',
      ],
      'study_queue_items': <String>[
        'session_id',
        'mode',
        'round',
        'card_id',
        'position',
        'status',
        'available_at',
        'answers_in_session',
        'remaining_ms',
        'is_revealed',
      ],
      'app_settings': <String>[
        'id',
        'card_limit',
        'new_card_order',
        'updated_at',
      ],
    };

    expected.forEach((table, columns) {
      test(table, () async {
        final db = openTestDatabase();

        expect(await columnsOf(db, table), columns);
      });
    });
  });

  test('cards carries no SRS column and no generation', () async {
    // BR-41: content survives every reset. An SRS column here would be wiped
    // with the schedule, and `cards` is the one table a reset must not touch.
    final db = openTestDatabase();
    final columns = await columnsOf(db, 'cards');

    expect(
      columns,
      isNot(
        anyOf(
          contains('due_at'),
          contains('current_box'),
          contains('ease_factor'),
          contains('scheduler_generation'),
        ),
      ),
    );
  });

  group('nullability and keys', () {
    test('root_deck_id and content_type are NOT NULL on decks', () async {
      final db = openTestDatabase();
      final rows = await pragma(db, 'PRAGMA table_info(decks)');
      final notNull = <String, Object?>{
        for (final row in rows) row['name']! as String: row['notnull'],
      };

      expect(notNull['root_deck_id'], 1);
      expect(notNull['content_type'], 1);
      // Scheduler columns are nullable because a sub-deck must leave them NULL
      // (BR-06); invariant 11 is what requires a root to fill them.
      expect(notNull['scheduler_type'], 0);
      expect(notNull['parent_deck_id'], 0);
    });

    test('card_study_states is keyed 1-1 by card_id', () async {
      final db = openTestDatabase();
      final rows = await pragma(db, 'PRAGMA table_info(card_study_states)');
      final primary = rows.where((row) => row['pk'] != 0).toList();

      expect(primary, hasLength(1));
      expect(primary.single['name'], 'card_id');
    });
  });

  test('foreign keys and their delete actions', () async {
    final db = openTestDatabase();

    Future<Set<String>> keysOf(String table) async {
      final rows = await pragma(db, 'PRAGMA foreign_key_list($table)');

      return rows
          .map(
            (row) =>
                '${row['from']}->${row['table']}.${row['to']}'
                ' ON DELETE ${row['on_delete']}',
          )
          .toSet();
    }

    expect(await keysOf('decks'), <String>{
      'parent_deck_id->decks.id ON DELETE CASCADE',
      // Purge is `DELETE FROM delete_batches`; this cascade is what turns that
      // one statement into the removal of every row of the batch (BR-191).
      'delete_batch_id->delete_batches.id ON DELETE CASCADE',
    });
    expect(await keysOf('cards'), <String>{
      'deck_id->decks.id ON DELETE CASCADE',
      'delete_batch_id->delete_batches.id ON DELETE CASCADE',
    });
    expect(await keysOf('card_study_states'), <String>{
      'card_id->cards.id ON DELETE CASCADE',
    });
    expect(await keysOf('study_answers'), <String>{
      'card_id->cards.id ON DELETE CASCADE',
      'session_id->study_sessions.id ON DELETE NO ACTION',
    });
    expect(await keysOf('study_sessions'), <String>{
      'deck_id->decks.id ON DELETE CASCADE',
    });
  });

  test('root_deck_id is deliberately not a foreign key', () async {
    // `data-model.md` declares the reference for `parent_deck_id` and for
    // nothing else. Adding one here would be stricter than a frozen document,
    // and invariants 6 and 7 are the enforcement it names.
    final db = openTestDatabase();
    final rows = await pragma(db, 'PRAGMA foreign_key_list(decks)');

    expect(rows.map((row) => row['from']), isNot(contains('root_deck_id')));
  });

  test('the indexes data-model.md names all exist', () async {
    final db = openTestDatabase();
    final rows = await pragma(
      db,
      "SELECT name FROM sqlite_master WHERE type = 'index' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    expect(rows.map((row) => row['name']), <String>[
      'idx_card_study_states_due',
      'idx_card_tags_tag',
      'idx_cards_deck_created',
      'idx_cards_delete_batch',
      'idx_decks_delete_batch',
      'idx_decks_parent_created',
      'idx_decks_root_created',
      'idx_delete_batches_deleted',
      'idx_study_answers_card',
      'idx_study_answers_session',
      'idx_study_queue_serving',
      'idx_tags_owner_folded',
    ]);
  });

  test('the deck and card reads need no temp B-tree to sort', () async {
    // The check that gives the composite indexes their value. An index can exist
    // and go unused: change an `ORDER BY` and SQLite silently falls back to
    // sorting every matching row before applying any `LIMIT`, which is what
    // `USE TEMP B-TREE FOR ORDER BY` in a query plan means. Asserting the index
    // *exists* would not catch that; asserting the plan does.
    //
    // These four are every deck/card read whose row count a user controls. The
    // SQL is copied from the `.drift` queries rather than called through the
    // generated API because `EXPLAIN QUERY PLAN` needs the statement text.
    final db = openTestDatabase();

    // Literals rather than `?`: `EXPLAIN QUERY PLAN` is prepared without bound
    // values, and the plan for an equality on an indexed column is the same
    // either way.
    const reads = <String, String>{
      'cardsByDeck':
          "SELECT * FROM cards WHERE deck_id = 'd' "
          'ORDER BY created_at ASC, id ASC',
      'rootDecks':
          'SELECT * FROM decks WHERE parent_deck_id IS NULL '
          'ORDER BY created_at ASC, id ASC',
      'childDecks':
          "SELECT * FROM decks WHERE parent_deck_id = 'p' "
          'ORDER BY created_at ASC, id ASC',
      'decksInTree':
          "SELECT * FROM decks WHERE root_deck_id = 'r' "
          'ORDER BY created_at ASC, id ASC',
    };

    for (final MapEntry<String, String> read in reads.entries) {
      final plan = await pragma(db, 'EXPLAIN QUERY PLAN ${read.value}');
      final detail = plan.map((row) => row['detail']).join(' | ');

      expect(
        detail,
        isNot(contains('TEMP B-TREE')),
        reason:
            '${read.key} is sorting rather than reading in index order. Either '
            'its ORDER BY no longer matches the composite index, or the index '
            'was changed. See docs/data-model.md.',
      );
      expect(
        detail,
        contains('USING'),
        reason: '${read.key} is not using any index at all.',
      );
    }
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
