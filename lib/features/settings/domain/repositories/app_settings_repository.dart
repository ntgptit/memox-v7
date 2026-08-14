import '../../../study/domain/models/new_card_order_model.dart';
import '../../../study/domain/models/study_card_limit_model.dart';
import '../models/app_language_model.dart';
import '../models/app_settings_model.dart';
import '../models/app_theme_mode_model.dart';

/// Read and write of the app's one global options row (BR-182).
///
/// **`watch` and nothing else for reading.** There is no `read()` on this
/// contract on purpose: a one-shot read is a second source of truth the moment
/// two surfaces use it, and this row is read by the root widget, the settings
/// screen and — indirectly, through Study — the session opener. One stream, one
/// answer (BR-182).
///
/// **Four write methods, not one `save(AppSettingsModel)`.** A single wide
/// write would make every save a read-modify-write of the whole row, so saving
/// a theme would also rewrite the card limit with whatever the caller was last
/// shown. Each method below is one transaction and one group (BR-188).
///
/// Pure domain: no Drift, no Flutter. Failures cross this boundary as
/// [Failure]s and never as database exceptions.
abstract interface class AppSettingsRepository {
  /// The current settings, re-emitted on every write (BR-182).
  ///
  /// The row always exists — the schema seeds it on create and the v5 migration
  /// backfills it — so this never emits null and never has an "unset" state to
  /// model.
  Stream<AppSettingsModel> watch();

  /// The two study defaults, written atomically — BR-183.
  ///
  /// Takes a [StudyCardLimit] rather than an `int` or a `String`: the bounds
  /// belong to the type, so the signature answers "has this been validated?"
  /// without anyone reading the implementation. Parsing raw text is the use
  /// case's job.
  ///
  /// MUST NOT touch `decks.study_config` (BR-183, BR-184).
  Future<void> saveStudyDefaults({
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  });

  /// The theme choice (BR-186).
  Future<void> saveThemeMode(AppThemeMode themeMode);

  /// The language choice (BR-187).
  Future<void> saveLanguage(AppLanguage language);

  /// Every value back to [AppSettingsModel.defaults], written atomically —
  /// BR-189.
  ///
  /// MUST NOT touch deck overrides, study state, history, sessions or content.
  Future<void> resetToDefaults();
}
