part of 'app_database.dart';

/// v12 → v13 adds persisted, deterministic order within each sibling group.
///
/// Existing siblings begin in historical `(created_at, id)` order; later
/// reorders change only the new position column.
extension AppDatabaseMigrationsV13 on AppDatabase {
  Future<void> _upgradeToV13() async {
    await customStatement(
      'ALTER TABLE decks ADD COLUMN sibling_position INTEGER NOT NULL DEFAULT 0',
    );
    await customStatement(
      'UPDATE decks AS current SET sibling_position = ('
      ' SELECT COUNT(*) FROM decks AS earlier'
      ' WHERE earlier.parent_deck_id IS current.parent_deck_id'
      '   AND (earlier.created_at < current.created_at'
      '     OR (earlier.created_at = current.created_at AND earlier.id < current.id))'
      ')',
    );
    await customStatement('DROP INDEX idx_decks_parent_created');
    await customStatement('DROP INDEX idx_decks_root_created');
    await customStatement(
      'CREATE INDEX idx_decks_parent_position '
      'ON decks (parent_deck_id, sibling_position, id)',
    );
    await customStatement(
      'CREATE INDEX idx_decks_root_position '
      'ON decks (root_deck_id, sibling_position, id)',
    );
  }
}
