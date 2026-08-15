import '../../../../core/database/app_database.dart';

/// Data access for the single `app_settings` row (BR-210).
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Every statement below is a typed
/// query from `queries/settings.drift`, so `drift_dev` checks it at build time
/// (AD-02).
///
/// **The row is addressed by its literal id inside the SQL, not here.** Every
/// statement carries `WHERE id = 1`; a DAO that passed the id as a parameter
/// would let a caller name a second row that the schema's `CHECK` says cannot
/// exist.
///
/// Speaks Drift rows; they stop at the repository (AD-01).
final class AppSettingsDao {
  AppSettingsDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically.
  ///
  /// Each group is one transaction (BR-216). A single-statement update is
  /// already atomic in SQLite, so this exists for the reset — which is one
  /// statement today and is the one most likely to grow a second.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  /// The row, re-emitted on every write to `app_settings` (BR-210).
  ///
  /// `watchSingle`, not `watchSingleOrNull`: the row is seeded by `onCreate`
  /// and by the v5 migration, so its absence is a defect and must surface as
  /// one rather than as a silently invented default.
  Stream<AppSetting> watch() => _db.appSettingsRow().watchSingle();

  /// Named parameters over drift's positional ones, on purpose: the generated
  /// `updateStudyDefaults(int, String, DateTime)` takes two values a caller can
  /// swap without the compiler noticing anything at all.
  Future<void> updateStudyDefaults({
    required int cardLimit,
    required String newCardOrder,
    required DateTime updatedAt,
  }) => _db.updateStudyDefaults(cardLimit, newCardOrder, updatedAt);

  Future<void> updateThemeMode({
    required String themeMode,
    required DateTime updatedAt,
  }) => _db.updateThemeMode(themeMode, updatedAt);

  Future<void> updateLanguage({
    required String language,
    required DateTime updatedAt,
  }) => _db.updateLanguage(language, updatedAt);

  Future<void> resetToDefaults(DateTime updatedAt) =>
      _db.resetAppSettings(updatedAt);
}
