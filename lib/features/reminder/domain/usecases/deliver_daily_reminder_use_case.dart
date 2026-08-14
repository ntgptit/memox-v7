import 'dart:developer' as developer;

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
    await _record(now);

    return ReminderDelivery.posted;
  }

  /// Records the delivery, and **never lets that failure escape**.
  ///
  /// **The notification has already been posted by the time this runs**, so the
  /// run succeeded from the user's point of view. Letting a failed write
  /// propagate makes the worker report failure, which makes WorkManager retry,
  /// which posts a *second* notification for the same day — the write failing
  /// would cause exactly the harm it was added to prevent.
  ///
  /// What is lost is the trace: the next reconcile derives its anchor from the
  /// previous delivery instead. That is safe rather than merely tolerable —
  /// the anchor is clamped to `now`, so the next run lands tomorrow either way;
  /// only the extra day-skip of a run that slipped past midnight is forfeited.
  ///
  /// `on Object` because any thrown type has the same answer here, and the log
  /// carries no count, no deck name and no copy (BR-186).
  Future<void> _record(DateTime now) async {
    try {
      await _settings.markDelivered(now);
    } on Object catch (error, stackTrace) {
      developer.log(
        'reminder delivery was not recorded',
        name: 'memox.reminder',
        error: error,
        stackTrace: stackTrace,
        level: 900,
      );
    }
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
    // **A stamp in the future is not a fact about today.** A clock that ran
    // fast when the delivery was recorded and was then corrected would
    // otherwise make every day read as already served, with no way back: no
    // screen shows this column and no command rewrites it.
    if (lastDeliveredAt.isAfter(now)) return false;

    final startOfToday = LocalDayModel(
      now: now,
      utcOffset: utcOffset,
    ).startOfToday;

    return !lastDeliveredAt.isBefore(startOfToday);
  }
}
