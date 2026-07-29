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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },

    // Deliberately absent: no `onUpgrade`. There is exactly one schema version,
    // and a handler written against a version that does not exist yet would be
    // a guess that looks like a decision. `drift_schemas/drift_schema_v1.json`
    // is committed so that the first real migration has a baseline to test
    // against — that snapshot, not a placeholder, is what makes v2 safe.
    beforeOpen: (OpeningDetails details) async {
      // Without this, `ON DELETE CASCADE` is a comment. SQLite defaults foreign
      // key enforcement OFF per connection, so every deletion would leave
      // orphaned cards, review states and history behind — silently, because
      // every query still runs and simply returns rows nobody can reach.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
