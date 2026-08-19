import '../models/reminder_capability_model.dart';
import '../models/reminder_overview_model.dart';
import '../repositories/reminder_platform_repository.dart';
import '../repositories/reminder_settings_repository.dart';

/// The one read the reminder screen makes (AD-13).
///
/// **The capability is resolved once and then carried.** It is a property of the
/// build and the device, not of a row: re-asking it on every settings emission
/// would put a platform call on the path of every toggle, and the answer cannot
/// change while the app is running.
///
/// **A failing capability read is `unsupported`, not an error.** The honest
/// outcome of "the platform would not answer" is a screen that says reminders
/// are not available here, which is a state the user can read — not a red error
/// they can do nothing about. `on Object` because any thrown type from a
/// platform channel must be absorbed at this boundary.
class WatchReminderOverviewUseCase {
  const WatchReminderOverviewUseCase(this._settings, this._platform);

  final ReminderSettingsRepository _settings;
  final ReminderPlatformRepository _platform;

  Stream<ReminderOverviewModel> call() async* {
    final capability = await _readCapability();

    yield* _settings.watchSettings().map(
      (settings) =>
          ReminderOverviewModel(settings: settings, capability: capability),
    );
  }

  Future<ReminderCapability> _readCapability() async {
    try {
      return await _platform.readCapability();
    } on Object {
      return ReminderCapability.unsupported;
    }
  }
}
