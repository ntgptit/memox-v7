import '../models/app_theme_mode_model.dart';
import '../repositories/app_settings_repository.dart';

/// Changes the app theme (BR-214).
///
/// Nothing to validate: [AppThemeMode] is closed over its three values, so
/// "invalid theme" is not a state the type can hold. The use case exists
/// anyway, because AD-12 makes uniformity the point — a feature where four of
/// five writes go through a use case and one goes straight to the repository is
/// a feature where the next reader has to check which is which.
class SaveThemeModeUseCase {
  const SaveThemeModeUseCase(this._repository);

  final AppSettingsRepository _repository;

  Future<void> call(AppThemeMode themeMode) =>
      _repository.saveThemeMode(themeMode);
}
