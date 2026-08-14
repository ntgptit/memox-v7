import '../repositories/reminder_platform_repository.dart';
import '../repositories/reminder_settings_repository.dart';

/// Makes the OS agree with the database (BR-190, BR-191).
///
/// **The database is the source of truth and this is the only direction.** The
/// schedule is derived state: enabled means one pending run at the stored time,
/// disabled means none. Nothing here writes a setting, so calling it can never
/// change what the user chose — which is why bootstrap, a timezone change and
/// the tail of a fired run can all call the same thing.
///
/// **Idempotent, and that is a contract on the platform** (BR-191): the
/// scheduler replaces its own pending work rather than adding to it, so
/// reconciling on every launch leaves exactly one run rather than one per
/// launch.
class ReconcileReminderScheduleUseCase {
  const ReconcileReminderScheduleUseCase(this._settings, this._platform);

  final ReminderSettingsRepository _settings;
  final ReminderPlatformRepository _platform;

  Future<void> call({
    required DateTime now,
    required Duration utcOffset,
  }) async {
    final settings = await _settings.readSettings();
    if (!settings.isEnabled) return _platform.cancel();

    return _platform.schedule(
      time: settings.time,
      now: now,
      utcOffset: utcOffset,
    );
  }
}
