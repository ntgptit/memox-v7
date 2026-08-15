import '../repositories/app_settings_repository.dart';

/// Puts every app option back to its default (BR-217).
///
/// **It resets options, not learning.** This app has two actions whose English
/// name starts with "Reset", and the other one — Reset learning progress
/// (BR-42, UC-07) — increments a scheduler generation and clears every card's
/// schedule. Nothing on this path can reach that: the repository behind it
/// writes one row of `app_settings` and has no other statement.
///
/// Deck overrides are also out of reach (BR-212). A root that chose its own
/// card limit keeps it; putting *that* deck back on the defaults is
/// `Use app defaults` on the deck's own options surface.
class ResetAppSettingsUseCase {
  const ResetAppSettingsUseCase(this._repository);

  final AppSettingsRepository _repository;

  Future<void> call() => _repository.resetToDefaults();
}
