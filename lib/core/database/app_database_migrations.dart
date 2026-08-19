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

  /// The v8 → v9 upgrade: the two appearance columns (BR-214, BR-215).
  ///
  /// **v9 rather than the v8 it was written as.** Settings and the recall
  /// direction were built against the same base and both claimed v8; the
  /// direction's landed first. The two are independent — different tables, both
  /// additive — so this one simply runs after it.
  ///
  /// **Additive, and it has to be.** Widening a `CHECK` means rebuilding a
  /// table in SQLite (see [_upgradeToV5]); adding a column with its own `CHECK`
  /// does not, because the constraint arrives with the column rather than
  /// replacing one. Nothing here rewrites a row.
  ///
  /// **`DEFAULT 'system'` is what makes the existing row correct without an
  /// `UPDATE`.** Every build before v9 followed the platform for both theme and
  /// language because it had no stored choice, so `'system'` is not a
  /// placeholder — it is the truthful record of what the app was already doing.
  ///
  /// The literals describe v9's schema, not today's, for the reason every other
  /// method in this file states.
  Future<void> _upgradeToV9() async {
    const List<String> statements = <String>[
      "ALTER TABLE app_settings ADD COLUMN theme_mode TEXT NOT NULL "
          "DEFAULT 'system' CHECK (theme_mode IN ('system', 'light', 'dark'))",
      "ALTER TABLE app_settings ADD COLUMN language TEXT NOT NULL "
          "DEFAULT 'system' CHECK (language IN ('system', 'en', 'vi'))",
    ];

    for (final statement in statements) {
      await customStatement(statement);
    }
  }

  /// The v7 → v8 upgrade: three nullable columns and one backfill (BR-203).
  ///
  /// **`ALTER TABLE … ADD COLUMN`, not a rebuild.** The three tables gain a
  /// constraint rather than change one, and SQLite allows a `CHECK` on an added
  /// column — the create-copy-drop of `_upgradeToV5` was forced by `CHECK`s that
  /// *widened*, which `ALTER TABLE` genuinely cannot do. Rebuilding `study_answers`
  /// again would move every history row this app has ever written for a change
  /// that alters none of them.
  ///
  /// **The backfill says `korean_to_meaning`, and it is a truth rather than a
  /// default.** Every `self_assess` review this app has ever served showed the
  /// front and revealed the back; that is what those rows recorded, and leaving
  /// them NULL would make "asked from the Korean term" and "the feature did not
  /// exist yet" the same stored value.
  ///
  /// **One predicate, decided once on the session, then derived twice.** The
  /// first draft asked the same question three different ways — the answer row
  /// from its own `scheduler_type` (BR-21), the session and the queue row from
  /// the deck's *current* algorithm — and the two disagree on exactly the tree
  /// BR-21 exists for: one that ran `sm2`, was reviewed, and was then Reset onto
  /// `eight_box`. Reset rewrites `decks.scheduler_type` and invalidates open
  /// sessions; it deletes no history and no queue row. So the answer got a
  /// direction and its own queue row did not, which is invariant 32's violation
  /// written by the migration itself.
  ///
  /// The session is therefore stamped first, from **either** source of truth —
  /// the deck as it stands, or an answer that says what it stood as — and the
  /// other two tables then key off the stamp rather than re-deriving it. Three
  /// statements that cannot disagree, because only one of them decides anything.
  ///
  /// A `learning` session is deliberately left NULL everywhere: its stages are
  /// not the user's to choose (BR-109), so it never had a direction to record.
  /// The root is resolved through `root_deck_id`, never by folding the parent
  /// column onto the id — BR-57 bans that because it returns the level-2 deck
  /// from the third level down.
  ///
  /// `updated_at` is untouched, for the same reason [_upgradeToV6] gives: a
  /// migration is not a user edit.
  Future<void> _upgradeToV8() async {
    const String turnDirections =
        "direction IS NULL OR direction IN ('korean_to_meaning', "
        "'meaning_to_korean')";

    await customStatement(
      'ALTER TABLE study_sessions ADD COLUMN direction TEXT NULL CHECK ('
      'direction IS NULL '
      "OR direction IN ('korean_to_meaning', 'meaning_to_korean', 'mixed'))",
    );
    await customStatement(
      'ALTER TABLE study_queue_items ADD COLUMN direction TEXT NULL '
      'CHECK ($turnDirections)',
    );
    await customStatement(
      'ALTER TABLE study_answers ADD COLUMN direction TEXT NULL '
      'CHECK ($turnDirections)',
    );

    // The one decision. `sm2` is read from the deck when the deck still says so,
    // and from the session's own history when a Reset has moved it since.
    await customStatement(
      "UPDATE study_sessions SET direction = 'korean_to_meaning' "
      "WHERE session_kind = 'reviewing' AND current_mode = 'self_assess' "
      '  AND direction IS NULL '
      '  AND ('
      '    EXISTS ('
      '      SELECT 1 FROM decks d'
      "      WHERE d.id = study_sessions.root_deck_id AND d.scheduler_type = 'sm2'"
      '    )'
      '    OR EXISTS ('
      '      SELECT 1 FROM study_answers a'
      '      WHERE a.session_id = study_sessions.id'
      "        AND a.scheduler_type = 'sm2'"
      '    )'
      '  )',
    );

    // Derived, not re-decided: a row belongs to a stamped session or it does not.
    await customStatement(
      "UPDATE study_queue_items SET direction = 'korean_to_meaning' "
      "WHERE mode = 'self_assess' "
      '  AND EXISTS ('
      '    SELECT 1 FROM study_sessions s'
      '    WHERE s.id = study_queue_items.session_id AND s.direction IS NOT NULL'
      '  )',
    );

    await customStatement(
      "UPDATE study_answers SET direction = 'korean_to_meaning' "
      "WHERE mode = 'self_assess' "
      '  AND EXISTS ('
      '    SELECT 1 FROM study_sessions s'
      '    WHERE s.id = study_answers.session_id AND s.direction IS NOT NULL'
      '  )',
    );
  }

  /// The v9 → v10 upgrade: the three reminder columns on `app_settings`
  /// (BR-218, BR-219, BR-221).
  ///
  /// **One step, not the two the source branch had.** That branch added the
  /// first two columns at its own v8 and the third at its v9, because its
  /// review found the delivery timestamp a round later. Both of those version
  /// numbers are taken here by other features, and replaying the split would
  /// also declare an intermediate schema — reminder configured, delivery never
  /// recorded — that no database on this line has ever held. A migration step
  /// describes a state some install is actually in; inventing one gives the
  /// verifier a version to check that nothing can produce.
  ///
  /// **The defaults are the specified defaults, not filler.** `0` is BR-218's
  /// "off until the user asks" and `1200` is BR-219's 20:00 local, so an
  /// upgraded install lands in exactly the state a fresh install starts in:
  /// the upgrade asks for no permission and schedules nothing.
  ///
  /// **The delivery column is nullable and undefaulted**, which is the truth
  /// for every database that predates it — nothing has been delivered yet. A
  /// default of `now` would make the first launch after the upgrade treat
  /// today as already served and stay silent for a day.
  ///
  /// The `CHECK`s ride along on the column definitions. SQLite accepts a
  /// column constraint in `ADD COLUMN` as long as the default is constant,
  /// and both are; enforcing the ranges in Dart only would leave the database
  /// able to hold a minute-of-day of 5000.
  ///
  /// Raw SQL with literal names, for the reason the whole file states: the
  /// generated symbols describe the *latest* schema, so naming them here
  /// breaks the day a later version renames one.
  Future<void> _upgradeToV10() async {
    const List<String> statements = <String>[
      'ALTER TABLE app_settings ADD COLUMN reminder_enabled INTEGER NOT NULL '
          'DEFAULT 0 CHECK (reminder_enabled IN (0, 1))',
      'ALTER TABLE app_settings ADD COLUMN reminder_minute_of_day INTEGER '
          'NOT NULL DEFAULT 1200 '
          'CHECK (reminder_minute_of_day BETWEEN 0 AND 1439)',
      // `INTEGER`, not `DATETIME`: drift stores a DATETIME as unix seconds, so
      // that is the type `createAll()` gives a fresh install — and a migration
      // declaring `DATETIME` produces a column the schema verifier reports as
      // a different type from the one the same schema builds from scratch.
      'ALTER TABLE app_settings ADD COLUMN reminder_last_delivered_at '
          'INTEGER NULL',
    ];

    for (final statement in statements) {
      await customStatement(statement);
    }
  }
}
