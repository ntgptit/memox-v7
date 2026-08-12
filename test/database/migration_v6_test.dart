import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:sqlite3/common.dart';

import '../drift/generated/schema.dart';

/// The v5 → v6 upgrade: a data-only normalise, and what it must leave alone.
///
/// **Why data has to move at all.** BR-67 allowed a sub-deck to keep
/// `content_type = 'card'` or `'deck'` after its last child was deleted;
/// BR-163 makes that state invalid and invariant 29 reports it. Fixing only
/// future writes would leave every existing user with rows that fail an
/// invariant they cannot see and cannot repair — the migration is the repair.
///
/// Everything here is seeded through **raw SQL against the v5 schema**, not
/// through today's generated classes: the point is that rows written by the old
/// code survive the upgrade, and raw SQL is the only way to write a row that
/// owes nothing to the current build.
void main() {
  /// A v5 database with [seed] applied, upgraded to the latest schema.
  Future<AppDatabase> upgradedFromV5(
    void Function(CommonDatabase raw) seed,
  ) async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(5);
    seed(schema.rawDatabase);

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    return db;
  }

  /// Statements that build one root and the sub-decks each case needs.
  void seedDecks(CommonDatabase raw, List<String> statements) {
    raw.execute(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('root', 'Korean', 'root', 'deck', 'eight_box', 1, 1, 7, 7)",
    );
    for (final statement in statements) {
      raw.execute(statement);
    }
  }

  String subDeck(String id, String contentType, {String parent = 'root'}) =>
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('$id', '$id', '$parent', 'root', '$contentType', 7, 7)";

  Future<String?> contentTypeOf(AppDatabase db, String deckId) async {
    final row = await db
        .customSelect(
          'SELECT content_type FROM decks WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(deckId)],
        )
        .getSingle();

    return row.data['content_type'] as String?;
  }

  test('an empty card sub-deck is normalised to unset', () async {
    final db = await upgradedFromV5(
      (raw) => seedDecks(raw, <String>[subDeck('emptied', 'card')]),
    );

    expect(await contentTypeOf(db, 'emptied'), 'unset');
  });

  test('an empty deck sub-deck is normalised to unset', () async {
    final db = await upgradedFromV5(
      (raw) => seedDecks(raw, <String>[subDeck('branch', 'deck')]),
    );

    expect(await contentTypeOf(db, 'branch'), 'unset');
  });

  test('an empty root keeps deck — it is invariant (BR-58)', () async {
    // The case a blunter `UPDATE decks SET content_type = 'unset'` would get
    // wrong, and it would get it wrong on every fresh library.
    final db = await upgradedFromV5((raw) => seedDecks(raw, const <String>[]));

    expect(await contentTypeOf(db, 'root'), 'deck');
  });

  test('a sub-deck that still holds a child keeps its type', () async {
    final db = await upgradedFromV5(
      (raw) => seedDecks(raw, <String>[
        subDeck('branch', 'deck'),
        subDeck('leaf', 'unset', parent: 'branch'),
      ]),
    );

    expect(await contentTypeOf(db, 'branch'), 'deck');
    expect(await contentTypeOf(db, 'leaf'), 'unset');
  });

  test('a sub-deck that still holds a card keeps its type', () async {
    final db = await upgradedFromV5((raw) {
      seedDecks(raw, <String>[subDeck('words', 'card')]);
      raw.execute(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, created_at, updated_at) '
        "VALUES ('c1', 'words', '연구자', 'researcher', '연구자', "
        "'researcher', 7, 7)",
      );
    });

    expect(await contentTypeOf(db, 'words'), 'card');
  });

  test('nothing else is touched: card, state, history and session '
      'survive', () async {
    // A data migration that quietly dropped a row would still pass every
    // content-type assertion above.
    final db = await upgradedFromV5((raw) {
      seedDecks(raw, <String>[
        subDeck('words', 'card'),
        subDeck('gone', 'deck'),
      ]);
      raw.execute(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, created_at, updated_at) '
        "VALUES ('c1', 'words', 'front', 'back', 'front', 'back', 7, 7)",
      );
      raw.execute(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, learned_at, due_at, '
        'last_answered_at, answer_count, lapse_count, current_box) '
        "VALUES ('c1', 'eight_box', 1, 1, 5, 9, 5, 3, 0, 4)",
      );
      raw.execute(
        'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
        'scheduler_generation, session_kind, current_mode, status, '
        'card_limit, started_at, ended_at) '
        "VALUES ('s1', 'words', 'root', 1, 'reviewing', 'match', "
        "'completed', 20, 7, 9)",
      );
      raw.execute(
        'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
        'scheduler_generation, kind, mode, action, answered_at, '
        'previous_box, next_box) '
        "VALUES ('h1', 'c1', 's1', 'eight_box', 1, 'scheduled', 'match', "
        "'remembered', 7, 3, 4)",
      );
    });

    Future<int> countOf(String table) async {
      final row = await db
          .customSelect('SELECT COUNT(*) AS n FROM $table')
          .getSingle();

      return row.data['n']! as int;
    }

    expect(await countOf('cards'), 1);
    expect(await countOf('card_study_states'), 1);
    expect(await countOf('study_answers'), 1);
    expect(await countOf('study_sessions'), 1);
    // And the deck that had to change did change.
    expect(await contentTypeOf(db, 'gone'), 'unset');
  });

  test('the backfill leaves updated_at alone', () async {
    // A migration is not a user edit. Stamping `updated_at` would reshuffle
    // every affected deck to the top of the Recent sort on the first launch
    // after the upgrade — data the user does not remember changing.
    final db = await upgradedFromV5(
      (raw) => seedDecks(raw, <String>[subDeck('emptied', 'card')]),
    );

    final row = await db
        .customSelect(
          'SELECT updated_at FROM decks WHERE id = ?',
          variables: const <Variable<Object>>[Variable<String>('emptied')],
        )
        .getSingle();

    expect(row.data['updated_at'], 7);
  });

  test(
    'every committed snapshot still upgrades to the latest schema',
    () async {
      // v1…v6, each started from its own dump. This is what proves the new step
      // runs *after* the older ones rather than instead of them.
      for (final version in GeneratedHelper.versions) {
        final verifier = SchemaVerifier(GeneratedHelper());
        final connection = await verifier.startAt(version);
        final db = AppDatabase(connection.executor);
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, db.schemaVersion);
      }
    },
  );

  test('a v1 database upgraded end to end still gets the v6 step', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'created_at, updated_at) '
      "VALUES ('legacy', 'Legacy', 'legacy', 'deck', 0, 0)",
    );
    schema.rawDatabase.execute(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('legacy-child', 'Child', 'legacy', 'legacy', 'card', 0, 0)",
    );

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    // Not pinned to a number: this test is about the content-type normalise
    // surviving every later step, and asserting the head version here would
    // make the next migration fail in a file that has nothing to do with it.
    expect(db.schemaVersion, GeneratedHelper.versions.last);
    expect(await contentTypeOf(db, 'legacy'), 'deck');
    expect(
      await contentTypeOf(db, 'legacy-child'),
      'unset',
      reason: 'the v6 step runs on top of v1…v5, not instead of them',
    );
  });

  test('a fresh install needs no normalising', () async {
    // `onCreate` never runs `onUpgrade`, so the invariant has to hold from the
    // first row rather than from the first migration.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final offenders = await db
        .customSelect(
          "SELECT id FROM decks WHERE parent_deck_id IS NOT NULL "
          "AND content_type IN ('card', 'deck') "
          'AND NOT EXISTS (SELECT 1 FROM cards c WHERE c.deck_id = decks.id) '
          'AND NOT EXISTS '
          '(SELECT 1 FROM decks child WHERE child.parent_deck_id = decks.id)',
        )
        .get();

    expect(offenders, isEmpty);
  });
}
