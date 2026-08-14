import '../models/app_settings_model.dart';
import '../repositories/app_settings_repository.dart';

/// The app's global options, as a live value (BR-182).
///
/// Thin, and deliberately so: AD-12 asks for a use case per interaction so that
/// a new feature is a clone rather than a judgement call at every operation.
/// The four fields arrive together because they are one row and one read — the
/// root widget wanting two of them is not a reason to open a second stream
/// (AD-13).
class WatchAppSettingsUseCase {
  const WatchAppSettingsUseCase(this._repository);

  final AppSettingsRepository _repository;

  Stream<AppSettingsModel> call() => _repository.watch();
}
