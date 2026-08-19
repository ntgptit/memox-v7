import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../study/domain/models/new_card_order_model.dart';
import '../../../study/domain/models/study_card_limit_model.dart';
import '../../domain/models/app_language_model.dart';
import '../../domain/models/app_settings_model.dart';
import '../../domain/models/app_theme_mode_model.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/app_settings_dao.dart';
import '../mappers/app_settings_mapper.dart';

/// Drift-backed [AppSettingsRepository] (BR-210).
///
/// Builds its DAO from the one [AppDatabase] it is handed, like every other
/// repository here: a ready-made adapter would let a composition root hand this
/// one a second database, and "the settings" would then be whichever database
/// answered.
///
/// **`clock` is injected, and nothing in this file reads the wall clock**
/// (AD-16). Every write stamps `updated_at`, and a private `DateTime.now()`
/// fallback is exactly the un-overridable second clock CLAUDE.md names.
///
/// **Errors are mapped at this boundary and nowhere above it.** `_guard` wraps
/// every write; the stream is wrapped too, because a Drift error on a
/// `watchSingle` arrives as an error *event* rather than a thrown exception, so
/// a try/catch around the subscription would never see it.
final class AppSettingsRepositoryImpl implements AppSettingsRepository {
  AppSettingsRepositoryImpl(
    AppDatabase database, {
    required DateTime Function() clock,
  }) : _dao = AppSettingsDao(database),
       // The initializing formal the lint asks for would be
       // `required this._clock`, and Dart forbids a named parameter starting
       // with an underscore — the same trade `DeckRepositoryImpl` records.
       // ignore: prefer_initializing_formals
       _clock = clock;

  final AppSettingsDao _dao;

  /// Injected, never a private `DateTime.now()` fallback (AD-16).
  final DateTime Function() _clock;

  @override
  Stream<AppSettingsModel> watch() => _dao
      .watch()
      .map(appSettingsFromRow)
      // `handleError` rather than a `transform`: the mapping above is
      // synchronous and cannot fail, so the only errors reaching here come from
      // the database, and they must arrive at the UI as a `Failure` like every
      // other error in the app.
      .handleError(
        (Object error) => throw _asFailure(error),
        // Already-mapped failures pass straight through instead of being
        // wrapped a second time.
        test: (Object? error) => error is! Failure,
      );

  @override
  Future<void> saveStudyDefaults({
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  }) => _guard(
    () => _dao.updateStudyDefaults(
      cardLimit: cardLimit.value,
      newCardOrder: newCardOrder.dbValue,
      updatedAt: _clock(),
    ),
  );

  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) => _guard(
    () =>
        _dao.updateThemeMode(themeMode: themeMode.dbValue, updatedAt: _clock()),
  );

  @override
  Future<void> saveLanguage(AppLanguage language) => _guard(
    () => _dao.updateLanguage(language: language.dbValue, updatedAt: _clock()),
  );

  /// One statement inside one transaction (BR-217).
  ///
  /// The transaction is not redundant even for a single statement: it is the
  /// boundary the rule names, and the reset is the write most likely to grow a
  /// second statement — a future option stored elsewhere would otherwise be
  /// reset outside it without anyone noticing the change of guarantee.
  @override
  Future<void> resetToDefaults() =>
      _guard(() => _dao.runInTransaction(() => _dao.resetToDefaults(_clock())));

  /// Maps a persistence error onto the domain language (AD-01).
  ///
  /// A [Failure] thrown by anything inside passes through untouched — it is
  /// already the type the caller expects, and re-wrapping it would replace a
  /// specific reason with a generic one.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw _asFailure(error);
    }
  }

  static Failure _asFailure(Object error) =>
      error is Failure ? error : mapDatabaseError(error);
}
