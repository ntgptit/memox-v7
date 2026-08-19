import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:sqlite3/common.dart';

import '../../drift/generated/schema.dart';

/// The v7 fixtures both halves of the v8 migration review need.
///
/// **Shared rather than copied.** The migration is judged by two opposite
/// questions — what must be stamped, and what must be left alone — and each
/// needs the same tree, the same session and the same three rows. Two copies of
/// a seeder is two places one of them can quietly stop matching the schema it
/// claims to write.
Future<AppDatabase> upgradedFromV7(
  void Function(CommonDatabase raw) seed,
) async {
  final verifier = SchemaVerifier(GeneratedHelper());
  final schema = await verifier.schemaAt(7);
  seed(schema.rawDatabase);

  final db = AppDatabase(schema.newConnection());
  addTearDown(db.close);
  await verifier.migrateAndValidate(db, db.schemaVersion);

  return db;
}

/// A root deck on [scheduler], with one card and one study state.
///
/// Two levels, because the backfill resolves the algorithm through
/// `root_deck_id`: a flat fixture would let a join on `deck_id` pass by
/// accident (BR-57).
void seedTree(
  CommonDatabase raw, {
  required String root,
  required String scheduler,
}) {
  raw.execute(
    'INSERT INTO decks (id, name, root_deck_id, content_type, '
    'scheduler_type, scheduler_version, scheduler_generation, '
    'created_at, updated_at) '
    "VALUES ('$root', '$root', '$root', 'deck', '$scheduler', 1, 1, 7, 7)",
  );
  raw.execute(
    'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
    'content_type, created_at, updated_at) '
    "VALUES ('$root-words', 'Words', '$root', '$root', 'card', 7, 7)",
  );
  raw.execute(
    'INSERT INTO cards (id, deck_id, front, back, front_folded, '
    'back_folded, created_at, updated_at) '
    "VALUES ('$root-c1', '$root-words', '연구자', 'researcher', '연구자', "
    "'researcher', 7, 7)",
  );
  raw.execute(
    'INSERT INTO card_study_states (card_id, scheduler_type, '
    'scheduler_version, scheduler_generation, learned_at, due_at, '
    'answer_count, lapse_count, current_box) '
    "VALUES ('$root-c1', '$scheduler', 1, 1, 100, 200, 1, 0, 2)",
  );
}

/// One session over [root], with a queue row and a history row.
void seedSession(
  CommonDatabase raw, {
  required String root,
  required String id,
  required String kind,
  required String mode,
  required String scheduler,
}) {
  raw.execute(
    'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
    'scheduler_generation, status, end_reason, session_kind, current_mode, '
    'cursor, card_limit, started_at, ended_at) '
    "VALUES ('$id', '$root-words', '$root', 1, 'completed', NULL, '$kind', "
    "'$mode', 1, 20, 700, 900)",
  );
  raw.execute(
    'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
    'position, status, available_at, answers_in_session, remaining_ms, '
    'is_revealed) '
    "VALUES ('$id', '$mode', 1, '$root-c1', 0, 'completed', 0, 1, NULL, 0)",
  );
  raw.execute(
    'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
    'scheduler_generation, kind, mode, outcome_reason, comparison_version, '
    'used_hint, "action", answered_at, next_due_at, previous_box, next_box, '
    'previous_ease_factor, next_ease_factor, previous_interval_days, '
    'next_interval_days) '
    "VALUES ('$id-a1', '$root-c1', '$id', '$scheduler', 1, 'scheduled', "
    "'$mode', NULL, NULL, NULL, "
    "'${scheduler == 'sm2' ? 'good' : 'remembered'}', 800, 900, 1, 2, "
    '2.5, 2.5, 1, 6)',
  );
}

Future<String?> directionOf(AppDatabase db, String table, String where) async {
  final row =
      (await db.customSelect('SELECT direction FROM $table WHERE $where').get())
          .single;

  return row.data['direction'] as String?;
}
