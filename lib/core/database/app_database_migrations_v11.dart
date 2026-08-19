part of 'app_database.dart';

/// The v10 → v11 upgrade, on its own.
///
/// **Split from `app_database_migrations.dart` at the 400-line guard, on
/// the seam the file already had.** Every other step there is additive or
/// data-only; this one adds a table, two columns, three indexes *and*
/// rebuilds `study_sessions`, which is why it is the step that pushed the
/// file over. Splitting by version keeps each block readable and leaves the
/// next release somewhere obvious to add its own.
///
/// **Every literal in here describes v10 → v11, not today's schema.** The
/// generated symbols always describe the latest schema, so naming one would
/// break the day a later version renames it — the same hazard
/// `app_database_migrations.dart` documents at length, and `flutter analyze`
/// still cannot see inside a string.
extension _AppDatabaseMigrationsV11 on AppDatabase {
  /// The v10 → v11 upgrade: Trash (BR-256…BR-267, AD-22).
  ///
  /// Three things, in the order they depend on each other: the batch table
  /// first, then the two tombstone columns that reference it, then the
  /// `study_sessions` rebuild that widens `end_reason`.
  ///
  /// **Every existing row stays active and nothing is rewritten.** Both new
  /// columns are nullable with no default, so a v10 deck and a v10 card upgrade
  /// to `delete_batch_id IS NULL` — which is exactly "not deleted". A database
  /// that has never seen this feature therefore reads identically before and
  /// after, and `migration_v11_test.dart` is what asserts that rather than
  /// assuming it.
  ///
  /// **`ALTER TABLE … ADD COLUMN` cannot carry a `REFERENCES` clause SQLite
  /// will enforce retroactively**, and it does not need to: the declaration in
  /// `decks.drift`/`cards.drift` is what a fresh install builds, and drift's
  /// `migrateAndValidate` compares the two shapes. What the added column must
  /// match is the *storage* type drift would emit — `TEXT` here — which is the
  /// same trap `_upgradeToV5` hit with `learned_at INTEGER`.
  ///
  /// **The literal names below describe v10, not today.** Same hazard as every
  /// other string in this file; `flutter analyze` cannot see inside any of them.
  Future<void> _upgradeToV11() async {
    await customStatement(
      'CREATE TABLE delete_batches ('
      '  id TEXT NOT NULL PRIMARY KEY,'
      "  item_type TEXT NOT NULL CHECK (item_type IN ('card', 'deck')),"
      '  root_item_id TEXT NOT NULL,'
      '  deleted_at INTEGER NOT NULL,'
      '  owner_id TEXT NULL'
      ')',
    );
    await customStatement(
      'CREATE INDEX idx_delete_batches_deleted '
      'ON delete_batches (deleted_at, id)',
    );

    await customStatement(
      'ALTER TABLE decks ADD COLUMN delete_batch_id TEXT NULL '
      'REFERENCES delete_batches (id) ON DELETE CASCADE',
    );
    await customStatement(
      'ALTER TABLE cards ADD COLUMN delete_batch_id TEXT NULL '
      'REFERENCES delete_batches (id) ON DELETE CASCADE',
    );
    await customStatement(
      'CREATE INDEX idx_decks_delete_batch ON decks (delete_batch_id)',
    );
    await customStatement(
      'CREATE INDEX idx_cards_delete_batch ON cards (delete_batch_id)',
    );

    await _rebuildStudySessionsForV11();
  }

  /// Rebuilds `study_sessions` so `end_reason` admits `content_deleted`.
  ///
  /// Column-for-column identical to v10's shape otherwise — this step widens
  /// one CHECK and copies every row through untouched, including the
  /// `direction` column this branch's own v8 added. Foreign keys are off during
  /// a migration (`PRAGMA foreign_keys = ON` runs in `beforeOpen`, after this),
  /// which is what makes dropping a table `study_answers` references safe here
  /// and only here.
  ///
  /// The two indexes on `study_answers` are **not** touched: they belong to a
  /// table this step does not rebuild.
  Future<void> _rebuildStudySessionsForV11() async {
    await customStatement(
      'CREATE TABLE study_sessions_v11 ('
      '  id TEXT NOT NULL PRIMARY KEY,'
      '  deck_id TEXT NOT NULL REFERENCES decks (id) ON DELETE CASCADE,'
      '  root_deck_id TEXT NOT NULL,'
      '  scheduler_generation INTEGER NOT NULL,'
      "  status TEXT NOT NULL CHECK (status IN ('in_progress', 'completed', 'abandoned', 'invalidated', 'failed')),"
      '  end_reason TEXT NULL CHECK ('
      '    end_reason IS NULL OR end_reason IN ('
      "      'user_exit', 'scheduler_reset', 'stale_generation', 'persistence_error', 'interrupted', 'content_deleted'"
      '  )),'
      "  session_kind TEXT NOT NULL CHECK (session_kind IN ('learning', 'reviewing')),"
      "  current_mode TEXT NOT NULL CHECK (current_mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),"
      '  cursor INTEGER NOT NULL DEFAULT 0,'
      '  card_limit INTEGER NOT NULL,'
      '  started_at INTEGER NOT NULL,'
      '  ended_at INTEGER NULL,'
      // v10's shape includes the recall direction (this branch's own v8) —
      // the literal the source branch wrote described v7 and would have
      // dropped the column, which is exactly why the doc comment above says
      // these literals describe the *from* version, not today.
      "  direction TEXT NULL CHECK ("
      '    direction IS NULL '
      "    OR direction IN ('korean_to_meaning', 'meaning_to_korean', 'mixed'))"
      ')',
    );

    await customStatement(
      'INSERT INTO study_sessions_v11 '
      '(id, deck_id, root_deck_id, scheduler_generation, status, end_reason, '
      ' session_kind, current_mode, cursor, card_limit, started_at, ended_at, '
      ' direction) '
      'SELECT id, deck_id, root_deck_id, scheduler_generation, status, '
      '       end_reason, session_kind, current_mode, cursor, card_limit, '
      '       started_at, ended_at, direction '
      'FROM study_sessions',
    );

    await customStatement('DROP TABLE study_sessions');
    await customStatement(
      'ALTER TABLE study_sessions_v11 RENAME TO study_sessions',
    );
  }
}
