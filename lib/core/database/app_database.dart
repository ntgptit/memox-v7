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
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the platform database. The executor comes from `connection.dart`,
  /// which is the only file in `lib/` allowed to open one (AD-08).
  AppDatabase.open() : super(openAppDatabaseConnection());

  @override
  int get schemaVersion => 2;

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
    },

    beforeOpen: (OpeningDetails details) async {
      // Without this, `ON DELETE CASCADE` is a comment. SQLite defaults foreign
      // key enforcement OFF per connection, so every deletion would leave
      // orphaned cards, review states and history behind — silently, because
      // every query still runs and simply returns rows nobody can reach.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
