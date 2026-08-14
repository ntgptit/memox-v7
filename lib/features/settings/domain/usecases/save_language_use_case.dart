import '../models/app_language_model.dart';
import '../repositories/app_settings_repository.dart';

/// Changes the app language (BR-187).
///
/// Closed over three values for the same reason [SaveThemeModeUseCase] is, and
/// present for the same reason.
class SaveLanguageUseCase {
  const SaveLanguageUseCase(this._repository);

  final AppSettingsRepository _repository;

  Future<void> call(AppLanguage language) => _repository.saveLanguage(language);
}
