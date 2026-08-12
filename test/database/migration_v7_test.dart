// `isNull` is a matcher here, and drift exports a column predicate by the same
// name. Hiding it keeps the assertions readable rather than qualifying each one.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:sqlite3/common.dart';

import '../drift/generated/schema.dart';

/// The v6 → v7 upgrade: the backfill that gives BR-13's lock a stored value.
///
/// **Why data has to move at all.** `decks.first_answered_at` has existed since
/// v1 and no build ever wrote it, so BR-13 had no implementation and every root
/// reads as unlocked. Now that `completeLearning` stamps it, only trees learned
/// *after* this release would lock — a library learned last month would stay
/// changeable for good, and invariant 30 would fire on it forever.
///
/// Seeded through **raw SQL against the v6 schema**: the point is that rows
/// written by the old code are repaired, and raw SQL is the only way to write a
/// row that owes nothing to the current build.
void main() {
  /// A v6 database with [seed] applied, upgraded to the latest schema.
  Future<AppDatabase> upgradedFromV6(
    void Function(CommonDatabase raw) seed,
  ) async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(6);
    seed(schema.rawDatabase);

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, db.schemaVersion);

    return db;
  }

  /// One root, one `card` sub-deck under it. Two levels, because the backfill
  /// resolves the root through `root_deck_id` and a flat fixture would let a
  /// join on `deck_id` pass by accident (BR-57).
  void seedTree(CommonDatabase raw, {String root = 'root'}) {
    raw.execute(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('$root', '$root', '$root', 'deck', 'eight_box', 1, 1, 7, 7)",
    );
    raw.execute(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('$root-words', 'Words', '$root', '$root', 'card', 7, 7)",
    );
  }

  void seedCard(CommonDatabase raw, String id, {String deck = 'root-words'}) {
    raw.execute(
      'INSERT INTO cards (id, deck_id, front, back, front_folded, '
      'back_folded, created_at, updated_at) '
      "VALUES ('$id', '$deck', '연구자', 'researcher', '연구자', "
      "'researcher', 7, 7)",
    );
  }

  /// A study state for [cardId]. `learnedAt` null is a card still in the chain.
  void seedState(CommonDatabase raw, String cardId, {int? learnedAt}) {
    final learned = learnedAt?.toString() ?? 'NULL';
    final due = learnedAt == null ? 'NULL' : '${learnedAt + 100}';
    raw.execute(
      'INSERT INTO card_study_states (card_id, scheduler_type, '
      'scheduler_version, scheduler_generation, learned_at, due_at, '
      'answer_count, lapse_count, current_box) '
      "VALUES ('$cardId', 'eight_box', 1, 1, $learned, $due, 1, 0, 2)",
    );
  }

  Future<int?> firstAnsweredAtOf(AppDatabase db, String deckId) async {
    final row = await db
        .customSelect(
          'SELECT first_answered_at FROM decks WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(deckId)],
        )
        .getSingle();

    return row.data['first_answered_at'] as int?;
  }

  test('a root with a learned card is locked', () async {
    final db = await upgradedFromV6((raw) {
      seedTree(raw);
      seedCard(raw, 'c1');
      seedState(raw, 'c1', learnedAt: 500);
    });

    expect(await firstAnsweredAtOf(db, 'root'), 500);
  });

  test('the stamp is the earliest learned_at in the tree', () async {
    // Not the moment of the upgrade. The column records *when* the tree was
    // first answered, and every legacy root carrying the same migration
    // timestamp would be a fact this database could never tell apart from a
    // real one.
    final db = await upgradedFromV6((raw) {
      seedTree(raw);
      seedCard(raw, 'c1');
      seedCard(raw, 'c2');
      seedCard(raw, 'c3');
      seedState(raw, 'c1', learnedAt: 900);
      seedState(raw, 'c2', learnedAt: 300);
      seedState(raw, 'c3', learnedAt: 600);
    });

    expect(await firstAnsweredAtOf(db, 'root'), 300);
  });

  test('a card still in the learning chain does not lock the root', () async {
    // BR-12: nothing has finished, so the choice is still free. Locking here
    // would take away a change the rule allows.
    final db = await upgradedFromV6((raw) {
      seedTree(raw);
      seedCard(raw, 'c1');
      seedState(raw, 'c1');
    });

    expect(await firstAnsweredAtOf(db, 'root'), isNull);
  });

  test('a root with no cards at all stays unlocked', () async {
    final db = await upgradedFromV6(seedTree);

    expect(await firstAnsweredAtOf(db, 'root'), isNull);
  });

  test('a root that already carries a stamp keeps it', () async {
    // `WHERE first_answered_at IS NULL`. Overwriting would move a real lock
    // moment to whatever the tree's earliest completion happens to be — and
    // after a Reset those are two different instants (BR-44).
    final db = await upgradedFromV6((raw) {
      seedTree(raw);
      raw.execute("UPDATE decks SET first_answered_at = 42 WHERE id = 'root'");
      seedCard(raw, 'c1');
      seedState(raw, 'c1', learnedAt: 500);
    });

    expect(await firstAnsweredAtOf(db, 'root'), 42);
  });

  test('one tree learning does not lock a sibling tree', () async {
    // The correlated subquery is scoped by `root_deck_id`. A backfill that
    // dropped that predicate would lock every root in the library the moment
    // one card anywhere finished.
    final db = await upgradedFromV6((raw) {
      seedTree(raw);
      seedTree(raw, root: 'other');
      seedCard(raw, 'c1');
      seedState(raw, 'c1', learnedAt: 500);
    });

    expect(await firstAnsweredAtOf(db, 'root'), 500);
    expect(await firstAnsweredAtOf(db, 'other'), isNull);
  });

  test('sub-decks are never stamped', () async {
    // `WHERE parent_deck_id IS NULL`. The lock belongs to the root (BR-05), and
    // a sub-deck carrying one would be a column nothing reads and no rule
    // describes.
    final db = await upgradedFromV6((raw) {
      seedTree(raw);
      seedCard(raw, 'c1');
      seedState(raw, 'c1', learnedAt: 500);
    });

    expect(await firstAnsweredAtOf(db, 'root-words'), isNull);
  });

  test('the backfill leaves updated_at alone', () async {
    // A migration is not a user edit — the same reason the v6 step gives.
    final db = await upgradedFromV6((raw) {
      seedTree(raw);
      seedCard(raw, 'c1');
      seedState(raw, 'c1', learnedAt: 500);
    });

    final row = await db
        .customSelect(
          'SELECT updated_at FROM decks WHERE id = ?',
          variables: const <Variable<Object>>[Variable<String>('root')],
        )
        .getSingle();

    expect(row.data['updated_at'], 7);
  });

  test('nothing else is touched: cards and states survive', () async {
    final db = await upgradedFromV6((raw) {
      seedTree(raw);
      seedCard(raw, 'c1');
      seedState(raw, 'c1', learnedAt: 500);
    });

    Future<int> countOf(String table) async {
      final row = await db
          .customSelect('SELECT COUNT(*) AS n FROM $table')
          .getSingle();

      return row.data['n']! as int;
    }

    expect(await countOf('cards'), 1);
    expect(await countOf('card_study_states'), 1);
    expect(await countOf('decks'), 2);
  });

  test(
    'every committed snapshot still upgrades to the latest schema',
    () async {
      // v1…v7, each started from its own dump. This is what proves the new step
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

  test('a fresh install needs no backfill', () async {
    // `onCreate` never runs `onUpgrade`, so invariant 30 has to hold from the
    // first row rather than from the first migration. It does, vacuously: a new
    // library has learned nothing.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final offenders = await db
        .customSelect(
          'SELECT root.id FROM decks root WHERE root.parent_deck_id IS NULL '
          'AND root.first_answered_at IS NULL '
          'AND EXISTS (SELECT 1 FROM card_study_states s '
          'JOIN cards c ON c.id = s.card_id '
          'JOIN decks d ON d.id = c.deck_id '
          'WHERE d.root_deck_id = root.id AND s.learned_at IS NOT NULL)',
        )
        .get();

    expect(offenders, isEmpty);
  });
}
