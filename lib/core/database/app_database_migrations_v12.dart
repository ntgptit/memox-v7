part of 'app_database.dart';

/// The v11 → v12 upgrade, on its own.
///
/// **One table rebuild, for one label.** SQLite cannot alter a `CHECK`, so
/// widening `end_reason` to admit `scheduler_changed` means create-copy-drop —
/// the same shape v8 and v11 took, for the same reason.
///
/// **Why the label is worth a rebuild.** `end_reason = scheduler_reset` was
/// carrying two different events. Reset learning progress writes it, and so
/// does BR-12's unlocked scheduler change, which is not a reset: the generation
/// stays where it is. Nothing is *lost* by the overload —
/// `study_sessions.scheduler_generation` equals the root's after a change and
/// is one behind after a reset — but reading the column on its own gives the
/// wrong answer, and the reader has to know that trick to get the right one. A
/// column whose values require a footnote is a column that will be misread.
///
/// **Every literal here describes v11, not today's schema.** The generated
/// symbols always describe the latest version, so naming one would break the
/// day a later version renames it; `app_database_migrations.dart` documents
/// that hazard at length and this file follows it.
extension AppDatabaseMigrationsV12 on AppDatabase {
  Future<void> _upgradeToV12() async {
    await _rebuildStudySessionsForV12();
  }

  /// Rebuilds `study_sessions` so `end_reason` admits `scheduler_changed`.
  ///
  /// Column-for-column identical to v11's shape otherwise: this widens one
  /// `CHECK` and copies every row through untouched. Foreign keys are off
  /// during a migration — `PRAGMA foreign_keys = ON` runs in `beforeOpen`,
  /// after this — which is what makes dropping a table `study_answers`
  /// references safe here and only here.
  ///
  /// **Existing rows are not rewritten, and that is deliberate.** A row already
  /// carrying `scheduler_reset` was written before the two events had separate
  /// names, and this migration cannot tell which one it was: the generation
  /// comparison that disambiguates them needs the root deck's generation *at
  /// the time*, which is not recorded. Guessing would put a label on history
  /// that history does not support. So old rows keep the value they were
  /// written with, and only sessions closed from v12 onward carry the new one.
  ///
  /// The two indexes on `study_answers` are **not** touched: they belong to a
  /// table this step does not rebuild.
  Future<void> _rebuildStudySessionsForV12() async {
    await customStatement(
      'CREATE TABLE study_sessions_v12 ('
      '  id TEXT NOT NULL PRIMARY KEY,'
      '  deck_id TEXT NOT NULL REFERENCES decks (id) ON DELETE CASCADE,'
      '  root_deck_id TEXT NOT NULL,'
      '  scheduler_generation INTEGER NOT NULL,'
      "  status TEXT NOT NULL CHECK (status IN ('in_progress', 'completed', 'abandoned', 'invalidated', 'failed')),"
      '  end_reason TEXT NULL CHECK ('
      '    end_reason IS NULL OR end_reason IN ('
      "      'user_exit', 'scheduler_reset', 'scheduler_changed', 'stale_generation', 'persistence_error', 'interrupted', 'content_deleted'"
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
      'INSERT INTO study_sessions_v12 '
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
      'ALTER TABLE study_sessions_v12 RENAME TO study_sessions',
    );
  }
}
