import '../../../../core/time/local_day_model.dart';
import '../repositories/reminder_platform_repository.dart';
import '../repositories/reminder_settings_repository.dart';

/// Makes the OS agree with the database (BR-226, BR-227).
///
/// **The database is the source of truth and this is the only direction.** The
/// schedule is derived state: enabled means one pending run at the stored time,
/// disabled means none. Nothing here writes a setting, so calling it can never
/// change what the user chose — which is why bootstrap, a timezone change and
/// the tail of a fired run can all call the same thing.
///
/// **Idempotent, and that is a contract on the platform** (BR-227): the
/// scheduler replaces its own pending work rather than adding to it, so
/// reconciling on every launch leaves exactly one run rather than one per
/// launch.
class ReconcileReminderScheduleUseCase {
  const ReconcileReminderScheduleUseCase(this._settings, this._platform);

  final ReminderSettingsRepository _settings;
  final ReminderPlatformRepository _platform;

  /// **The day already served is read from the row, not passed in** (BR-221).
  ///
  /// It used to be an argument, and only the fire-time worker supplied it — so
  /// the skip lived exactly as long as that one background run. The next time
  /// the app launched, its own reconcile recomputed from `now`, put the skipped
  /// day back, and `ExistingWorkPolicy.replace` made that the schedule: two
  /// summaries in one local day, which is the rule the anchor exists to keep.
  ///
  /// Deriving it here instead means all four callers — launch, enable, time
  /// change, worker — reach the same answer without any of them having to know.
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
      notBefore: _notBefore(settings.lastDeliveredAt, now, utcOffset),
    );
  }

  /// The earliest instant the next occurrence may be chosen from.
  ///
  /// A local day that has had its summary is finished: the next one belongs to
  /// the day after it. `null` — nothing delivered yet — means the ordinary next
  /// occurrence.
  ///
  /// **Measured against the delivery, not against `now`.** The two differ
  /// exactly when it matters: a run deferred past local midnight delivered on a
  /// day the clock has since left.
  ///
  /// **A stamp in the future is ignored**, for the reason
  /// `DeliverDailyReminderUseCase` gives: a clock that ran fast and was then
  /// corrected would push the anchor days ahead, and nothing in the app can
  /// rewrite the column to undo it — not even turning the reminder off and on.
  DateTime? _notBefore(
    DateTime? lastDeliveredAt,
    DateTime now,
    Duration utcOffset,
  ) => lastDeliveredAt == null || lastDeliveredAt.isAfter(now)
      ? null
      : LocalDayModel(
          now: lastDeliveredAt,
          utcOffset: utcOffset,
        ).startOfTomorrow;
}
