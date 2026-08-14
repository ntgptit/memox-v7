import '../models/reminder_delivery_model.dart';
import '../models/reminder_summary_model.dart';
import '../repositories/reminder_platform_repository.dart';
import '../repositories/reminder_settings_repository.dart';
import '../repositories/reminder_workload_repository.dart';

/// One fire-time evaluation (BR-184, BR-185, BR-186).
///
/// **This is what AD-21 bought.** Every number in the notification is read
/// *now*, at the moment the reminder is about to be shown, rather than baked
/// into a payload when the run was scheduled. A user who cleared their queue
/// this evening gets nothing; a user who has since fallen further behind gets
/// the real figure.
///
/// **The settings row is re-read even though a cancel should have removed this
/// run.** A cancel can fail, and a background run is the one thing the app
/// cannot reach afterwards to correct — so "the user turned it off" is checked
/// here rather than assumed, which is [ReminderDelivery.skippedDisabled].
///
/// Returns an outcome rather than logging one: BR-186 keeps counts and deck
/// names out of every log, so the only honest way to observe this in a test is
/// the returned value.
class DeliverDailyReminderUseCase {
  const DeliverDailyReminderUseCase(
    this._settings,
    this._workload,
    this._platform,
  );

  final ReminderSettingsRepository _settings;
  final ReminderWorkloadRepository _workload;
  final ReminderPlatformRepository _platform;

  Future<ReminderDelivery> call({
    required DateTime now,
    required Duration utcOffset,
  }) async {
    final settings = await _settings.readSettings();
    if (!settings.isEnabled) return ReminderDelivery.skippedDisabled;

    final workloads = await _workload.readWorkload(
      now: now,
      utcOffset: utcOffset,
    );
    final summary = ReminderSummaryModel.build(workloads);
    if (summary == null) return ReminderDelivery.skippedNothingDue;

    await _platform.showSummary(summary);

    return ReminderDelivery.posted;
  }
}
