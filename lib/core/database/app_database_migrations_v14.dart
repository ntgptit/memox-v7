part of 'app_database.dart';

/// v13 → v14 records the specific event that invalidated a session when a
/// sub-deck is promoted into a new root.
///
/// Promotion resets only the extracted subtree onto its newly selected
/// scheduler. Reusing `scheduler_reset` would state that its former root was
/// reset as well, which is not true. SQLite cannot alter a CHECK constraint, so
/// the table is rebuilt and every existing row is copied unchanged.
extension AppDatabaseMigrationsV14 on AppDatabase {
  Future<void> _upgradeToV14() => _rebuildStudySessionsForV14();

  Future<void> _rebuildStudySessionsForV14() async {
    await customStatement(
      'CREATE TABLE study_sessions_v14 ('
      '  id TEXT NOT NULL PRIMARY KEY,'
      '  deck_id TEXT NOT NULL REFERENCES decks (id) ON DELETE CASCADE,'
      '  root_deck_id TEXT NOT NULL,'
      '  scheduler_generation INTEGER NOT NULL,'
      "  status TEXT NOT NULL CHECK (status IN ('in_progress', 'completed', 'abandoned', 'invalidated', 'failed')),"
      '  end_reason TEXT NULL CHECK ('
      '    end_reason IS NULL OR end_reason IN ('
      "      'user_exit', 'scheduler_reset', 'scheduler_changed', 'stale_generation', 'persistence_error', 'interrupted', 'content_deleted', 'subtree_promoted'"
      '  )),'
      "  session_kind TEXT NOT NULL CHECK (session_kind IN ('learning', 'reviewing')),"
      "  current_mode TEXT NOT NULL CHECK (current_mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),"
      '  cursor INTEGER NOT NULL DEFAULT 0,'
      '  card_limit INTEGER NOT NULL,'
      '  started_at INTEGER NOT NULL,'
      '  ended_at INTEGER NULL,'
      '  direction TEXT NULL CHECK ('
      '    direction IS NULL '
      "    OR direction IN ('korean_to_meaning', 'meaning_to_korean', 'mixed'))"
      ')',
    );
    await customStatement(
      'INSERT INTO study_sessions_v14 '
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
      'ALTER TABLE study_sessions_v14 RENAME TO study_sessions',
    );
  }
}
