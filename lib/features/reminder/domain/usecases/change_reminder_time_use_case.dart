import '../../../../core/error/failure.dart';
import '../failures/reminder_failure.dart';
import '../models/reminder_time_model.dart';
import '../repositories/reminder_settings_repository.dart';
import 'reconcile_reminder_schedule_use_case.dart';

/// Moves the daily reminder to another time of day (UC-12 A1, BR-183).
///
/// **The range check ran before this was called, and the type proves it.** The
/// parameter is a [ReminderTime], which cannot exist without having passed
/// [ReminderTime.parse] — so no caller can hand over a minute of 5000, and the
/// screen never re-derives which bound was broken in order to decide what to
/// mark.
///
/// **It works while the reminder is off.** The stored time is what the screen
/// shows next to a disabled toggle, and the reconcile below turns that into a
/// no-op cancel rather than a schedule — so "set the time first, turn it on
/// later" costs nothing extra and needs no branch here.
///
/// A failed reschedule restores the previous time, for the reason
/// [EnableReminderUseCase] states: the schedule is derived from the row, so the
/// row is the thing that must not be left describing something the OS does not
/// have.
class ChangeReminderTimeUseCase {
  const ChangeReminderTimeUseCase(this._settings, this._reconcile);

  final ReminderSettingsRepository _settings;
  final ReconcileReminderScheduleUseCase _reconcile;

  Future<void> call({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
  }) async {
    final current = await _settings.readSettings();
    if (current.time == time) return;

    await _settings.saveSettings(isEnabled: current.isEnabled, time: time);

    try {
      await _reconcile(now: now, utcOffset: utcOffset);
    } on Object catch (error) {
      await _settings.saveSettings(
        isEnabled: current.isEnabled,
        time: current.time,
      );

      throw ConflictFailure(
        message: 'The reminder could not be rescheduled',
        cause: error,
        reason: ReminderSetupRejection.scheduleFailed,
      );
    }
  }
}
