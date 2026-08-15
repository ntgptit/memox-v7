// The v4 → v5 upgrade, which is the one migration in this app that **rebuilds
// tables**: `study_sessions` and `study_answers` are dropped and recreated
// because SQLite cannot widen a `CHECK`. A second `part of 'app_database.dart'`
// so it keeps the extension's access to `customStatement` — the split exists to
// satisfy the file-size guard, and the seam is real: every other step is
// additive or data-only, and this one moves every row.
part of 'app_database.dart';

extension _AppDatabaseV5Migration on AppDatabase {
  /// The v4 → v5 upgrade.
  ///
  /// Two of these steps CANNOT be an `ALTER TABLE`: SQLite has no way to change
  /// a `CHECK` constraint, and both `study_answers.kind` (gains `learning`) and
  /// `study_sessions.end_reason` (gains `interrupted`) do exactly that. So both
  /// tables are rebuilt — create, copy, drop, rename — which is also what lets
  /// the new NOT NULL columns arrive without a `DEFAULT` that the declaration
  /// would then have to carry forever.
  ///
  /// Foreign keys are off during a migration — `PRAGMA foreign_keys = ON` runs
  /// in `beforeOpen`, which is after this — so dropping a table that
  /// `study_answers` references is safe here, and only here.
  ///
  /// **The literal names below describe v4, not today.** A project-wide rename
  /// pass already flattened the v3 → v4 statements into no-ops once; the same
  /// hazard applies to every string in this file, and `flutter analyze` cannot
  /// see inside any of them.
  Future<void> _upgradeToV5() async {
    await customStatement(
      'ALTER TABLE decks ADD COLUMN study_config TEXT NULL',
    );
    // `INTEGER`, not `DATETIME`: drift translates the `.drift` declaration
    // into the storage type, and hand-written SQL has to say what drift would
    // have said. `migrateAndValidate` compares the two and rejects the pair.
    await customStatement(
      'ALTER TABLE card_study_states ADD COLUMN learned_at INTEGER NULL',
    );

    // The backfill that keeps invariants 24 and 28 both green.
    //
    // Under v4, `due_at IS NULL` meant "due immediately", which is how a card
    // that had never been reviewed looked. From v5 the two columns travel
    // together: a card either finished the chain and has both, or has neither
    // (BR-149). Anything already carrying a `due_at` has been reviewed, so
    // `last_answered_at` is the honest moment it finished — and `due_at` is the
    // fallback for a row that somehow lacks one.
    await customStatement(
      'UPDATE card_study_states '
      'SET learned_at = COALESCE(last_answered_at, due_at) '
      'WHERE due_at IS NOT NULL',
    );

    await _rebuildStudySessionsForV5();
    await _rebuildStudyAnswersForV5();

    await customStatement(
      'CREATE TABLE study_queue_items ('
      '  session_id TEXT NOT NULL REFERENCES study_sessions (id) ON DELETE CASCADE,'
      "  mode TEXT NOT NULL CHECK (mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),"
      '  round INTEGER NOT NULL DEFAULT 1,'
      '  card_id TEXT NOT NULL REFERENCES cards (id) ON DELETE CASCADE,'
      '  position INTEGER NOT NULL,'
      "  status TEXT NOT NULL CHECK (status IN ('pending', 'completed')),"
      '  available_at INTEGER NOT NULL DEFAULT 0,'
      '  answers_in_session INTEGER NOT NULL DEFAULT 0,'
      '  remaining_ms INTEGER NULL,'
      '  is_revealed INTEGER NOT NULL DEFAULT 0,'
      '  PRIMARY KEY (session_id, mode, round, card_id)'
      ')',
    );

    await customStatement(
      'CREATE INDEX idx_study_queue_serving ON study_queue_items '
      '(session_id, mode, round, status, available_at, position)',
    );

    await customStatement(
      'CREATE TABLE app_settings ('
      '  id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),'
      '  card_limit INTEGER NOT NULL DEFAULT 20,'
      "  new_card_order TEXT NOT NULL DEFAULT 'created'"
      "    CHECK (new_card_order IN ('created', 'random')),"
      '  updated_at INTEGER NOT NULL'
      ')',
    );

    // Seeded here rather than lazily on first read, because "exactly one row"
    // is the property the CHECK above buys, and a table that starts empty makes
    // it depend on whoever remembers to insert. `strftime` rather than
    // `DateTime.now()`: drift stores DATETIME as unix seconds, and reaching for
    // the wall clock in Dart is the habit AD-06 exists to stop.
    await customStatement(
      'INSERT INTO app_settings (id, card_limit, new_card_order, updated_at) '
      "VALUES (1, 20, 'created', CAST(strftime('%s', 'now') AS INTEGER))",
    );
  }

  /// Rebuilds `study_sessions` with the four new columns and the wider
  /// `end_reason` enumeration.
  ///
  /// The four values supplied for existing rows — `reviewing`, `self_assess`,
  /// cursor 0, limit 20 — describe what a v4 session actually was: one kind,
  /// one mode, no queue, the default ceiling. No build ever created one, but a
  /// migration that would corrupt a row if it existed is not one worth
  /// shipping.
  Future<void> _rebuildStudySessionsForV5() async {
    await customStatement(
      'CREATE TABLE study_sessions_v5 ('
      '  id TEXT NOT NULL PRIMARY KEY,'
      '  deck_id TEXT NOT NULL REFERENCES decks (id) ON DELETE CASCADE,'
      '  root_deck_id TEXT NOT NULL,'
      '  scheduler_generation INTEGER NOT NULL,'
      "  status TEXT NOT NULL CHECK (status IN ('in_progress', 'completed', 'abandoned', 'invalidated', 'failed')),"
      '  end_reason TEXT NULL CHECK ('
      '    end_reason IS NULL OR end_reason IN ('
      "      'user_exit', 'scheduler_reset', 'stale_generation', 'persistence_error', 'interrupted'"
      '  )),'
      "  session_kind TEXT NOT NULL CHECK (session_kind IN ('learning', 'reviewing')),"
      "  current_mode TEXT NOT NULL CHECK (current_mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),"
      '  cursor INTEGER NOT NULL DEFAULT 0,'
      '  card_limit INTEGER NOT NULL,'
      '  started_at INTEGER NOT NULL,'
      '  ended_at INTEGER NULL'
      ')',
    );

    await customStatement(
      'INSERT INTO study_sessions_v5 '
      '(id, deck_id, root_deck_id, scheduler_generation, status, end_reason, '
      ' session_kind, current_mode, cursor, card_limit, started_at, ended_at) '
      'SELECT id, deck_id, root_deck_id, scheduler_generation, status, '
      "       end_reason, 'reviewing', 'self_assess', 0, 20, started_at, ended_at "
      'FROM study_sessions',
    );

    await customStatement('DROP TABLE study_sessions');
    await customStatement(
      'ALTER TABLE study_sessions_v5 RENAME TO study_sessions',
    );
  }

  /// Rebuilds `study_answers` with `learning` in `kind` and the four columns the
  /// graded modes need.
  ///
  /// Existing rows get `mode = 'self_assess'`, which is what every v4 review
  /// was: the only mode that existed. Guessing anything else would put a mode
  /// into history that the app could not have produced.
  Future<void> _rebuildStudyAnswersForV5() async {
    await customStatement(
      'CREATE TABLE study_answers_v5 ('
      '  id TEXT NOT NULL PRIMARY KEY,'
      '  card_id TEXT NOT NULL REFERENCES cards (id) ON DELETE CASCADE,'
      '  session_id TEXT NOT NULL REFERENCES study_sessions (id),'
      "  scheduler_type TEXT NOT NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),"
      '  scheduler_generation INTEGER NOT NULL,'
      "  kind TEXT NOT NULL CHECK (kind IN ('learning', 'scheduled', 'relearning')),"
      "  mode TEXT NOT NULL CHECK (mode IN ('self_assess', 'match', 'guess', 'recall', 'fill')),"
      "  outcome_reason TEXT NULL CHECK (outcome_reason IS NULL OR outcome_reason IN ('timeout')),"
      '  comparison_version INTEGER NULL,'
      '  used_hint INTEGER NULL CHECK (used_hint IS NULL OR used_hint IN (0, 1)),'
      '  "action" TEXT NOT NULL CHECK ('
      '    "action" IN '
      "      ('forgotten', 'remembered', 'again', 'hard', 'good', 'easy')"
      '  ),'
      '  answered_at INTEGER NOT NULL,'
      '  next_due_at INTEGER NULL,'
      '  previous_box INTEGER NULL,'
      '  next_box INTEGER NULL,'
      '  previous_ease_factor REAL NULL,'
      '  next_ease_factor REAL NULL,'
      '  previous_interval_days INTEGER NULL,'
      '  next_interval_days INTEGER NULL'
      ')',
    );

    await customStatement(
      'INSERT INTO study_answers_v5 '
      '(id, card_id, session_id, scheduler_type, scheduler_generation, kind, '
      ' mode, outcome_reason, comparison_version, used_hint, "action", '
      ' answered_at, next_due_at, previous_box, next_box, previous_ease_factor, '
      ' next_ease_factor, previous_interval_days, next_interval_days) '
      'SELECT id, card_id, session_id, scheduler_type, scheduler_generation, '
      "       kind, 'self_assess', NULL, NULL, NULL, \"action\", "
      '       answered_at, next_due_at, previous_box, next_box, '
      '       previous_ease_factor, next_ease_factor, previous_interval_days, '
      '       next_interval_days '
      'FROM study_answers',
    );

    await customStatement('DROP TABLE study_answers');
    await customStatement(
      'ALTER TABLE study_answers_v5 RENAME TO study_answers',
    );
    await customStatement(
      'CREATE INDEX idx_study_answers_card ON study_answers (card_id, answered_at)',
    );
    await customStatement(
      'CREATE INDEX idx_study_answers_session ON study_answers (session_id)',
    );
  }
}
