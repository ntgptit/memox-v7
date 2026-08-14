import '../../../../core/error/failure.dart';
import '../failures/reminder_failure.dart';
import '../models/reminder_capability_model.dart';
import '../models/reminder_time_model.dart';
import '../repositories/reminder_platform_repository.dart';
import '../repositories/reminder_settings_repository.dart';
import 'reconcile_reminder_schedule_use_case.dart';

/// Turns the daily reminder on (UC-12, BR-182, BR-192).
///
/// **Four steps, and the order is the rule.** Capability first, because an
/// unsupported device must never see a permission prompt. Permission second,
/// and only here — BR-182's whole point is that nothing asks before the user
/// does. The write third. The schedule last.
///
/// **The write comes before the schedule, and a failed schedule undoes it.**
/// BR-192 says the setting stays off when enabling does not complete, and there
/// are only two ways to guarantee that: never write until the schedule is
/// confirmed, or write and compensate. The second is what the whole feature
/// already needs — [ReconcileReminderScheduleUseCase] derives the schedule from
/// the stored row, so writing first means the reconcile is the only code that
/// ever talks to the scheduler, and a crash between the two steps is repaired
/// on the next launch rather than leaving a run nobody can find.
///
/// The compensating write is deliberately not wrapped in its own try: if
/// restoring the row also fails, that failure is the one worth surfacing —
/// the database is unreachable, and reporting `scheduleFailed` instead would
/// send the user to retry a schedule that was never the problem.
class EnableReminderUseCase {
  const EnableReminderUseCase(this._settings, this._platform, this._reconcile);

  final ReminderSettingsRepository _settings;
  final ReminderPlatformRepository _platform;
  final ReconcileReminderScheduleUseCase _reconcile;

  Future<void> call({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
  }) async {
    final capability = await _platform.readCapability();
    if (capability != ReminderCapability.supported) {
      throw const ConflictFailure(
        message: 'Reminders are not available on this platform',
        reason: ReminderSetupRejection.platformUnavailable,
      );
    }

    final permission = await _platform.requestPermission();
    if (permission != ReminderPermission.granted) {
      throw const ForbiddenFailure(
        message: 'Notification permission was not granted',
        reason: ReminderSetupRejection.permissionDenied,
      );
    }

    await _settings.saveSettings(isEnabled: true, time: time);

    try {
      await _reconcile(now: now, utcOffset: utcOffset);
    } on Object catch (error) {
      await _settings.saveSettings(isEnabled: false, time: time);

      throw ConflictFailure(
        message: 'The reminder could not be scheduled',
        cause: error,
        reason: ReminderSetupRejection.scheduleFailed,
      );
    }
  }
}
