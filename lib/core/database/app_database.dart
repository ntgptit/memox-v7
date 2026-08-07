import 'package:drift/drift.dart';

import 'connection.dart';

part 'app_database.g.dart';

/// The app's database.
///
/// Composition only: it includes the `.drift` files and states the migration
/// policy. No repository logic, no scheduler logic, and no interval table — the
/// eight-box day table and the SM-2 factors belong to the scheduler (BR-16), and
/// putting them in SQL would make changing them a migration.
@DriftDatabase(
  include: <String>{
    'tables/decks.drift',
    'tables/cards.drift',
    'tables/tags.drift',
    'tables/study.drift',
    'queries/study.drift',
    'queries/deck.drift',
    'queries/card.drift',
    'queries/tag.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the platform database. The executor comes from `connection.dart`,
  /// which is the only file in `lib/` allowed to open one (AD-08).
  AppDatabase.open() : super(openAppDatabaseConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },

    // v1 → v2 (M4.10at): the card screen needs tags, a flag and three optional
    // fields, so `cards` gains four columns and two tables arrive.
    //
    // **Every step is additive and none rewrites a row.** The four columns are
    // nullable or defaulted, so a v1 card upgrades without a value being
    // invented for it: `is_flagged` reads 0 — "not marked", which is true of
    // every card that predates the flag — and the three optional fields read
    // NULL, which is the "never filled" this schema deliberately keeps distinct
    // from empty string.
    //
    // That the first migration is this cheap is what committing
    // `drift_schema_v1.json` at M4.4 bought. The snapshot is what the migration
    // test upgrades *from*; without it, "v1 still opens" would be a claim
    // nobody could run.
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(cards, cards.isFlagged);
        await m.addColumn(cards, cards.example);
        await m.addColumn(cards, cards.hint);
        await m.addColumn(cards, cards.pronunciation);
        await m.createTable(tags);
        await m.createTable(cardTags);
        await m.createIndex(idxTagsOwnerFolded);
        await m.createIndex(idxCardTagsTag);
      }

      // v2 → v3: the two folded search columns, and the backfill that gives
      // existing cards a value for them.
      //
      // **The backfill runs in Dart, and it has to.** The whole reason these
      // columns exist is that SQLite's `lower()` folds ASCII only, so
      // `UPDATE cards SET front_folded = lower(front)` would write exactly the
      // broken values the columns were added to replace — and it would look
      // like it worked.
      if (from < 3) {
        await m.addColumn(cards, cards.frontFolded);
        await m.addColumn(cards, cards.backFolded);
        await _backfillFoldedSides();
      }

      // v3 → v4 (M5.0l): pure rename. Two tables, six columns and three
      // indexes take the names the specification has used since M5.0a. No
      // column is added, dropped or rewritten, and no row is touched.
      //
      // **`ALTER TABLE … RENAME` rather than create-copy-drop.** SQLite has
      // renamed columns since 3.25 and, with `legacy_alter_table` off, it also
      // rewrites the foreign keys and index definitions that point at a renamed
      // table. The copy approach would move every row for a change that alters
      // no data, and would need `PRAGMA foreign_keys = OFF` around it — the one
      // pragma this database refuses to turn off.
      //
      // **Raw SQL rather than `m.renameTable`.** The generated symbols always
      // describe the *latest* schema, so naming them here would break the day a
      // v5 arrives, exactly as `_backfillFoldedSides` explains above. These
      // statements name only what v3 has and what v4 wants.
      if (from < 4) {
        await _renameForV4();
      }
    },

    beforeOpen: (OpeningDetails details) async {
      // Without this, `ON DELETE CASCADE` is a comment. SQLite defaults foreign
      // key enforcement OFF per connection, so every deletion would leave
      // orphaned cards, study states and history behind — silently, because
      // every query still runs and simply returns rows nobody can reach.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

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

  /// Fills `front_folded` / `back_folded` for every card that predates them.
  ///
  /// **Raw SQL, not the generated query API.** The generated symbols always
  /// describe the *latest* schema, so a step that used them would break the day
  /// a later version renames or adds a column — the migration would then be
  /// naming something that does not exist yet at this point in the upgrade. The
  /// two statements below name only what v3 has.
  ///
  /// That day arrived at v4, which renamed `card_review_states` and five
  /// columns. This method still says `front_folded` and `back_folded` on
  /// `cards`, neither of which v4 touched, so it keeps working unchanged — which
  /// is the whole point of naming the schema of the step rather than the schema
  /// of today.
  ///
  /// A loop rather than a batch: this runs once per device, inside the
  /// migration's transaction, and `customStatement` is the API that is certain
  /// to be there. Folding is `CardText.fold`'s rule — trim, then Dart's
  /// Unicode-aware `toLowerCase()` — restated here rather than imported, because
  /// `core/` must not depend on a feature (AD-13). The pair is pinned by
  /// `migration_test.dart`, which upgrades a v2 card holding `CÔNG NGHỆ` and
  /// requires the folded column to read `công nghệ`.
  Future<void> _backfillFoldedSides() async {
    final rows = await customSelect(
      'SELECT id, front, back FROM cards',
      readsFrom: <TableInfo<Table, Object?>>{cards},
    ).get();

    for (final row in rows) {
      await customUpdate(
        'UPDATE cards SET front_folded = ?, back_folded = ? WHERE id = ?',
        variables: <Variable<Object>>[
          Variable<String>(row.read<String>('front').trim().toLowerCase()),
          Variable<String>(row.read<String>('back').trim().toLowerCase()),
          Variable<String>(row.read<String>('id')),
        ],
        // Stated even though nothing is listening mid-upgrade: `customUpdate`
        // is how a raw write tells drift which streams it invalidates, and a
        // write that does not say is the habit that breaks a live screen later.
        updates: <TableInfo<Table, Object?>>{cards},
      );
    }
  }
}
