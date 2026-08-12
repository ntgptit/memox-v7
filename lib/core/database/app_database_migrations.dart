part of 'app_database.dart';

/// The upgrade steps, one method per version.
///
/// **Split from `app_database.dart` at the 400-line guard, on the seam the file
/// already had.** What stays behind composes the database and states the policy;
/// what moved here is the SQL that carries one version to the next, and it grows
/// by one block per release while the other half does not.
///
/// **Every literal in here describes the schema of its own step, not today's.**
/// The generated symbols always describe the latest schema, so naming one would
/// break the day a later version renames it — which is why these are strings.
/// A project-wide rename pass has already flattened one of them into a no-op
/// once; `flutter analyze` cannot see inside a string, and only the migration
/// tests caught it.
extension _AppDatabaseMigrations on AppDatabase {
  /// The v3 → v4 rename, statement by statement.
  ///
  /// Order matters in one place: a column rename names the table it belongs to,
  /// so tables move first and every column statement below uses the **new**
  /// table name. Getting that backwards fails loudly rather than silently,
  /// which is the one mercy of doing this in SQL.
  ///
  /// Indexes are dropped and recreated rather than renamed. SQLite has no
  /// `ALTER INDEX`, and recreating is cheap: an index holds no data of its own.
  ///
  /// **Every old name below is load-bearing and must not be "fixed".** A
  /// project-wide rename pass flattened these to `RENAME card_study_states TO
  /// card_study_states` — statements that read tidy, compile fine, and turn the
  /// migration into a no-op that then fails on a real v3 database because the
  /// new table does not exist yet. `flutter analyze` cannot see inside a string;
  /// `migration_test.dart`'s v3 → v4 group is what caught it.
  Future<void> _renameForV4() async {
    const List<String> statements = <String>[
      // Tables.
      'ALTER TABLE card_review_states RENAME TO card_study_states',
      'ALTER TABLE review_history RENAME TO study_answers',

      // Columns, on the tables under their new names.
      'ALTER TABLE card_study_states RENAME COLUMN review_count TO answer_count',
      'ALTER TABLE card_study_states RENAME COLUMN last_reviewed_at TO last_answered_at',
      'ALTER TABLE study_answers RENAME COLUMN review_kind TO kind',
      'ALTER TABLE study_answers RENAME COLUMN reviewed_at TO answered_at',
      'ALTER TABLE decks RENAME COLUMN first_review_at TO first_answered_at',

      // Indexes: drop, then recreate against the new names.
      'DROP INDEX IF EXISTS idx_review_states_due',
      'DROP INDEX IF EXISTS idx_history_card',
      'DROP INDEX IF EXISTS idx_history_session',
      'CREATE INDEX idx_card_study_states_due ON card_study_states (due_at)',
      'CREATE INDEX idx_study_answers_card ON study_answers (card_id, answered_at)',
      'CREATE INDEX idx_study_answers_session ON study_answers (session_id)',
    ];

    for (final statement in statements) {
      await customStatement(statement);
    }
  }

  /// The v5 → v6 upgrade: data only, no DDL (BR-163).
  ///
  /// Every non-root deck still carrying a content type while holding neither a
  /// direct card nor a direct child deck goes back to `'unset'`. That set is
  /// exactly invariant 29, so this statement is the invariant's own predicate
  /// used as an `UPDATE`.
  ///
  /// **Root decks are left alone** — a root is `'deck'` forever (BR-58) and an
  /// empty root is an ordinary state, not a violation.
  ///
  /// **`updated_at` is deliberately not touched.** A migration is not a user
  /// edit; stamping it would reshuffle every affected deck to the top of the
  /// Recent sort on first launch after the upgrade, which reads as data the
  /// user does not remember changing.
  ///
  /// Nothing is deleted: cards, study states, history and sessions are
  /// untouched by construction — this statement writes one column of `decks`.
  Future<void> _upgradeToV6() async {
    await customStatement(
      "UPDATE decks SET content_type = 'unset' "
      'WHERE parent_deck_id IS NOT NULL '
      "  AND content_type IN ('card', 'deck') "
      '  AND NOT EXISTS (SELECT 1 FROM cards c WHERE c.deck_id = decks.id) '
      '  AND NOT EXISTS ('
      '    SELECT 1 FROM decks child WHERE child.parent_deck_id = decks.id'
      '  )',
    );
  }

  /// The v6 → v7 upgrade: data only, no DDL (BR-13).
  ///
  /// `decks.first_answered_at` has existed since v1 and nothing ever wrote it,
  /// so the lock BR-13 describes had no stored form. Roots whose cards finished
  /// the learning chain long before this release therefore read as unlocked,
  /// which both offers a scheduler change the rule forbids and makes invariant
  /// 30 fire on a database the user cannot repair.
  ///
  /// **The earliest `learned_at` in the tree, not the moment of the upgrade.**
  /// The column records *when* the tree was first answered, and it is read by
  /// nothing but the null check today — but a truthful value costs one
  /// aggregate, and stamping every legacy root with the same migration
  /// timestamp would be a fact this database cannot later tell apart from a
  /// real one.
  ///
  /// **Only roots with nothing stamped and something learned.** A root already
  /// carrying a value keeps it, and a root whose tree has never completed a card
  /// stays unlocked — which is the state BR-12 says is still changeable.
  ///
  /// `updated_at` is left alone for the same reason as [_upgradeToV6]: a
  /// migration is not a user edit.
  Future<void> _upgradeToV7() async {
    await customStatement(
      'UPDATE decks SET first_answered_at = ('
      '  SELECT MIN(s.learned_at) FROM card_study_states s'
      '  JOIN cards c ON c.id = s.card_id'
      '  JOIN decks d ON d.id = c.deck_id'
      '  WHERE d.root_deck_id = decks.id AND s.learned_at IS NOT NULL'
      ') '
      'WHERE parent_deck_id IS NULL '
      '  AND first_answered_at IS NULL '
      '  AND EXISTS ('
      '    SELECT 1 FROM card_study_states s'
      '    JOIN cards c ON c.id = s.card_id'
      '    JOIN decks d ON d.id = c.deck_id'
      '    WHERE d.root_deck_id = decks.id AND s.learned_at IS NOT NULL'
      '  )',
    );
  }

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
