import 'package:drift/drift.dart';

import '../text/search_fold.dart';
import 'connection.dart';

part 'app_database.g.dart';
part 'app_database_migrations.dart';
part 'app_database_migrations_v5.dart';
part 'app_database_migrations_v11.dart';
part 'app_database_migrations_v12.dart';

/// The app's database.
///
/// Composition only: it includes the `.drift` files and states the migration
/// policy. No repository logic, no scheduler logic, and no interval table — the
/// eight-box day table and the SM-2 factors belong to the scheduler (BR-16), and
/// putting them in SQL would make changing them a migration.
@DriftDatabase(
  include: <String>{
    'tables/trash.drift',
    'tables/decks.drift',
    'tables/cards.drift',
    'tables/tags.drift',
    'tables/study.drift',
    'tables/settings.drift',
    'queries/study.drift',
    'queries/settings.drift',
    'queries/deck.drift',
    'queries/card.drift',
    'queries/tag.drift',
    // A read-only summary of `study_answers` (UC-12). It adds a statement and
    // no table: `schemaVersion` is deliberately untouched by this file, because
    // a named query is not a schema change.
    'queries/progress.drift',
    'queries/reminder.drift',
    'queries/search.drift',
    'queries/trash.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the platform database. The executor comes from `connection.dart`,
  /// which is the only file in `lib/` allowed to open one (AD-08).
  AppDatabase.open() : super(openAppDatabaseConnection());

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      // **A fresh install never runs a migration, so it has to be seeded here
      // too.** `app_settings` holds exactly one row and the v5 migration
      // inserts it — but only for a database that already existed. Without this
      // line a brand-new install has an empty settings table, and the first
      // study session throws on a read that cannot fail by design.
      //
      // Duplicated with `_upgradeToV5` on purpose: the two paths are genuinely
      // different, and a helper shared between them would have to name a schema
      // that means different things at each call site.
      //
      // Every column is named, including the two v8 added. They carry a
      // `DEFAULT`, so omitting them would work — and would stop working the day
      // an option arrives without one, silently, on fresh installs only.
      await customStatement(
        'INSERT INTO app_settings '
        '(id, card_limit, new_card_order, theme_mode, language, updated_at) '
        "VALUES (1, 20, 'created', 'system', 'system', "
        "        CAST(strftime('%s', 'now') AS INTEGER))",
      );
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

      // v4 -> v5 (M5.0s): the whole Study schema the brainstorm settled on.
      //
      // **One migration rather than five.** Every column here is meaningless
      // without the others -- `session_kind` cannot split the two card sets
      // without `learned_at`, and `study_queue_items` cannot say which stage is
      // running without `current_mode`. Splitting it would only produce
      // intermediate versions no build ever ran, which is to say migrations
      // nobody ever really tested.
      if (from < 5) {
        await _upgradeToV5();
      }

      // v5 -> v6 (M99.15): no schema change at all — a data-only normalise.
      //
      // BR-67 used to allow a sub-deck to keep `content_type = 'card'` or
      // `'deck'` after its last child was deleted; BR-163 makes that state
      // invalid (invariant 29) and the write paths now prevent it. Existing
      // databases were written under the old rule, so the rows that are legal
      // v5 and illegal v6 have to be fixed here — future writes alone would
      // leave a user's tree permanently failing an invariant nobody could see.
      //
      // Last, so it runs on top of whatever the v1…v5 steps just produced.
      if (from < 6) {
        await _upgradeToV6();
      }

      // v6 -> v7 (M99.16): data only again — the backfill for BR-13's lock.
      //
      // Nothing before this release ever wrote `decks.first_answered_at`, so
      // every root reads as unlocked no matter how much of it has been learned.
      // Now that `completeLearning` stamps it, only *future* first completions
      // would lock a tree: a library learned last month would stay changeable
      // for good, and invariant 30 would fire on it. Both are fixed here rather
      // than lived with.
      //
      // Last, so it runs on top of whatever the v1…v6 steps just produced.
      if (from < 7) {
        await _upgradeToV7();
      }

      // v7 -> v8 (M99.27): the recall direction of BR-203.
      //
      // Three nullable columns and a backfill. Additive, so a v7 row upgrades
      // without a value being invented for it — except for the one set of rows
      // where NULL would be a lie: every `self_assess` review already served was
      // asked from the Korean term, and leaving those unmarked would make
      // "recognition" and "before the feature existed" the same stored value.
      //
      // Last, so it runs on top of whatever the v1…v7 steps just produced.
      if (from < 8) {
        await _upgradeToV8();
      }

      // v8 -> v9 (M99.28): the two appearance columns of BR-214 and BR-215.
      //
      // Two `ALTER TABLE ADD COLUMN`, and nothing else. Both are NOT NULL with
      // a `DEFAULT 'system'`, so the one existing row upgrades to exactly the
      // state a fresh install has — "follow the platform", which is what every
      // build before this one did because it had no choice.
      //
      // **v9 rather than the v8 this arrived as.** Settings and the recall
      // direction were written against the same base and both claimed v8; the
      // direction's landed first, so this one runs on top of it. The two do not
      // interact — different tables, both additive — but the order is now fixed
      // and `migration_v9_test` upgrades from a v8 database, not a v7 one.
      //
      // **The `CHECK` on each column does not survive the `ALTER`, and that is
      // accepted here rather than worked around.** SQLite applies a column
      // constraint declared in `ADD COLUMN`, and `migrateAndValidate` compares
      // the upgraded database against the declaration, so `migration_v9_test`
      // is what proves the pair actually agree — asserting against this file
      // would only agree with itself.
      if (from < 9) {
        await _upgradeToV9();
      }

      // v9 -> v10 (M99.29): the three reminder columns on `app_settings`
      // (BR-218, BR-219, BR-221).
      //
      // Additive, so a v9 row upgrades in place. The source branch spread these
      // over two versions; both of those numbers are taken here, and the
      // intermediate state they described has never existed on this line.
      //
      // Last, so it runs on top of whatever the v1…v9 steps just produced.
      if (from < 10) {
        await _upgradeToV10();
      }

      // v10 -> v11 (M99.33): Trash. The one migration in this file that both
      // adds structure and rebuilds a table.
      //
      // **The rebuild is not optional.** `study_sessions.end_reason` gains
      // `content_deleted` (BR-259) and SQLite cannot alter a CHECK, so the
      // table is created-copied-dropped-renamed exactly as v5 did for the same
      // reason. Everything else here is additive, and every existing row stays
      // active because `delete_batch_id` arrives NULL — which is what "old
      // rows are active by default" means in practice.
      //
      // **v11 rather than the v8 this arrived as.** Trash was written against
      // the same base as the recall direction (v8), Settings (v9) and the
      // reminder (v10) and claimed the first free number it saw; it landed
      // last, so it runs on top of all three. `migration_v11_test` upgrades
      // from a v10 database, not a v7 one.
      if (from < 11) {
        await _upgradeToV11();
      }

      // **v12 rebuilds `study_sessions` for one label, and that is the whole
      // step.** `end_reason = scheduler_reset` was carrying two events —
      // Reset learning progress, and BR-12's unlocked scheduler change, which
      // is not a reset because the generation does not move. Nothing was lost
      // by the overload, since `scheduler_generation` tells them apart, but a
      // column whose values need a footnote is a column that gets misread.
      if (from < 12) {
        await _upgradeToV12();
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
  /// to be there. Folding goes through [foldForSearch] — trim, then Dart's
  /// Unicode-aware `toLowerCase()`. It used to be *restated* here, because the
  /// rule lived in `CardText` and `core/` must not depend on a feature (AD-13);
  /// M99.32 moved the rule itself into `core/text/`, so the backfill and the
  /// column's writer now share one implementation instead of two copies that
  /// agreed by inspection. The pair is pinned by `migration_test.dart`, which
  /// upgrades a v2 card holding `CÔNG NGHỆ` and requires the folded column to
  /// read `công nghệ`.
  Future<void> _backfillFoldedSides() async {
    final rows = await customSelect(
      'SELECT id, front, back FROM cards',
      readsFrom: <TableInfo<Table, Object?>>{cards},
    ).get();

    for (final row in rows) {
      await customUpdate(
        'UPDATE cards SET front_folded = ?, back_folded = ? WHERE id = ?',
        variables: <Variable<Object>>[
          Variable<String>(foldForSearch(row.read<String>('front'))),
          Variable<String>(foldForSearch(row.read<String>('back'))),
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
