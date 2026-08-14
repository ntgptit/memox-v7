import '../../../../core/time/local_day_model.dart';
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
    if (_isAlreadyServed(settings.lastDeliveredAt, now, utcOffset)) {
      return ReminderDelivery.skippedAlreadyServed;
    }

    final workloads = await _workload.readWorkload(
      now: now,
      utcOffset: utcOffset,
    );
    final summary = ReminderSummaryModel.build(workloads);
    if (summary == null) return ReminderDelivery.skippedNothingDue;

    await _platform.showSummary(summary);
    // **Recorded before the reschedule that follows this call.** BR-185's day
    // skip is derived from this timestamp, and it has to outlive the isolate
    // that posted the notification — the app reconciles on every launch, and
    // without a stored trace that reconcile would put the served day back.
    await _settings.markDelivered(now);

    return ReminderDelivery.posted;
  }

  /// Whether the local day [now] falls in has already had its summary (BR-185).
  ///
  /// **The second lock on "one per day", and it is not redundant.** The first
  /// is the schedule, and a schedule can be re-run: WorkManager retries a task
  /// that reports failure, and this one reports failure if anything after the
  /// notification throws. Without this the retry finds the same settings and
  /// the same unstudied cards and alerts the user again, minutes later.
  ///
  /// A delivery from an earlier local day does not block anything — 01:00 on
  /// day D does not stop 20:00 on day D+1.
  bool _isAlreadyServed(
    DateTime? lastDeliveredAt,
    DateTime now,
    Duration utcOffset,
  ) {
    if (lastDeliveredAt == null) return false;

    final startOfToday = LocalDayModel(
      now: now,
      utcOffset: utcOffset,
    ).startOfToday;

    return !lastDeliveredAt.isBefore(startOfToday);
  }
}
