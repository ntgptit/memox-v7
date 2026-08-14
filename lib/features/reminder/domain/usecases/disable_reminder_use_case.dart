import '../../../../core/error/failure.dart';
import '../failures/reminder_failure.dart';
import '../repositories/reminder_settings_repository.dart';
import 'reconcile_reminder_schedule_use_case.dart';

/// Turns the daily reminder off (UC-12 A2, BR-190).
///
/// **The time is kept.** A user who turns the reminder off and back on a week
/// later gets their own time, not 20:00 again — so this writes `isEnabled:
/// false` against the stored time rather than resetting the row.
///
/// **No permission, no confirmation.** Turning something off is not a decision
/// the app gets to question, and asking the OS for anything here would be
/// asking on a path the user is walking away from.
///
/// A failed cancel is **not** rolled back into "still on". The pending run is
/// harmless: BR-184's fire-time evaluation re-reads the settings row and skips
/// when the reminder is off, so the worst outcome of a lost cancel is one
/// wasted wake-up. Reverting the row would be worse — it would put the toggle
/// back on under a user who just turned it off.
class DisableReminderUseCase {
  const DisableReminderUseCase(this._settings, this._reconcile);

  final ReminderSettingsRepository _settings;
  final ReconcileReminderScheduleUseCase _reconcile;

  Future<void> call({
    required DateTime now,
    required Duration utcOffset,
  }) async {
    final current = await _settings.readSettings();
    await _settings.saveSettings(isEnabled: false, time: current.time);

    try {
      await _reconcile(now: now, utcOffset: utcOffset);
    } on Object catch (error) {
      throw ConflictFailure(
        message: 'The pending reminder could not be cancelled',
        cause: error,
        reason: ReminderSetupRejection.cancelFailed,
      );
    }
  }
}
