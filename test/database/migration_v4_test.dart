import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../drift/generated/schema.dart';

/// The v3 → v4 rename, and the rows it must not lose.
///
/// **Split from `migration_test.dart` rather than appended to it.** That file
/// reached the 400-line guard, and the split falls on a natural seam: every
/// group there tests a migration that *adds* something, while this one tests
/// one that adds nothing and must still leave every value where it was.
///
/// The distinction matters for what the tests look like. An additive migration
/// is proved by reading the new column; a rename is proved by reading the old
/// values back under new names — and by the schema comparison, which would pass
/// just as happily on an empty database.
void main() {
  group('v3 → v4 · the rename', () {
    /// A v3 database holding one card with a schedule and one recorded answer,
    /// then upgraded.
    ///
    /// **The point of seeding rows is that a rename must not lose any.** The
    /// schema comparison `migrateAndValidate` runs would pass on an empty
    /// database, and would also pass if the migration had dropped and recreated
    /// the two tables — which is exactly the implementation this one avoids.
    /// Reading the values back afterwards is what tells those two apart.
    Future<AppDatabase> upgradedFromSeededV3() async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(3);

      schema.rawDatabase.execute(
        'INSERT INTO decks (id, name, root_deck_id, content_type, '
        'scheduler_type, scheduler_version, scheduler_generation, '
        'first_review_at, created_at, updated_at) '
        "VALUES ('d1', 'Korean', 'd1', 'card', 'eight_box', 1, 1, 1700, 0, 0)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, created_at, updated_at) '
        "VALUES ('c1', 'd1', 'kimchi', 'kim chi', 'kimchi', 'kim chi', 0, 0)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO card_review_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, due_at, last_reviewed_at, '
        'review_count, lapse_count, current_box) '
        "VALUES ('c1', 'eight_box', 1, 1, 2400, 1800, 3, 1, 4)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
        'scheduler_generation, status, started_at) '
        "VALUES ('s1', 'd1', 'd1', 1, 'completed', 1700)",
      );
      schema.rawDatabase.execute(
        'INSERT INTO review_history (id, card_id, session_id, scheduler_type, '
        'scheduler_generation, review_kind, action, reviewed_at, next_box) '
        "VALUES ('h1', 'c1', 's1', 'eight_box', 1, 'scheduled', "
        "'remembered', 1800, 4)",
      );

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, db.schemaVersion);

      return db;
    }

    test('the schedule survives the rename, values intact', () async {
      final db = await upgradedFromSeededV3();

      final row = await db
          .customSelect(
            'SELECT answer_count, lapse_count, last_answered_at, current_box '
            "FROM card_study_states WHERE card_id = 'c1'",
          )
          .getSingle();

      expect(row.data['answer_count'], 3);
      expect(row.data['lapse_count'], 1);
      expect(row.data['last_answered_at'], 1800);
      expect(row.data['current_box'], 4);
    });

    test('the recorded answer survives, including its kind', () async {
      final db = await upgradedFromSeededV3();

      final row = await db
          .customSelect(
            "SELECT kind, action, answered_at, next_box "
            "FROM study_answers WHERE id = 'h1'",
          )
          .getSingle();

      // `kind` is the column BR-76 refuses to let anyone infer. A rename that
      // lost it would leave every historical answer unattributable, and no
      // later code could recompute it.
      expect(row.data['kind'], 'scheduled');
      expect(row.data['action'], 'remembered');
      expect(row.data['answered_at'], 1800);
      expect(row.data['next_box'], 4);
    });

    test('the deck keeps its first-answer timestamp', () async {
      final db = await upgradedFromSeededV3();

      final row = await db
          .customSelect("SELECT first_answered_at FROM decks WHERE id = 'd1'")
          .getSingle();

      // NULL here would mean the scheduler silently unlocked (BR-13).
      expect(row.data['first_answered_at'], 1700);
    });

    test('the foreign key from answer to card still bites', () async {
      final db = await upgradedFromSeededV3();

      // A rename done by create-copy-drop is the one that loses this: the new
      // table is created without the constraint and nothing complains until a
      // delete leaves an unreachable row behind.
      await db.customStatement("DELETE FROM cards WHERE id = 'c1'");

      final remaining = await db
          .customSelect('SELECT COUNT(*) AS c FROM study_answers')
          .getSingle();
      expect(remaining.read<int>('c'), 0);
    });
  });
}
