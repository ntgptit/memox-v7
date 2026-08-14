import '../../../../core/database/app_database.dart';

/// Data access for the daily reminder.
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Reads and the one write delegate to
/// the typed statements in `queries/reminder.drift`, plus `appSettingsRow` from
/// `queries/study.drift`: `app_settings` holds one row and both features read
/// it, so a second copy of that `SELECT` would be a second spelling of the same
/// predicate (AD-02).
///
/// **No transaction wrapper.** Every write here is one statement against one
/// row and reads nothing first; a transaction around it would buy nothing and
/// would suggest to the next reader that something multi-step is happening.
///
/// This class speaks Drift rows. They stop here: the repository maps them to
/// domain models and never lets one across (AD-01).
final class ReminderDao {
  ReminderDao(this._db);

  final AppDatabase _db;

  /// The settings row, re-emitted whenever `app_settings` changes.
  Stream<AppSetting> watchSettingsRow() => _db.appSettingsRow().watchSingle();

  /// The settings row, once.
  Future<AppSetting> readSettingsRow() => _db.appSettingsRow().getSingle();

  /// Writes the reminder choice, both columns together (BR-182, BR-183).
  Future<void> writeSettings({
    required bool isEnabled,
    required int minuteOfDay,
    required DateTime updatedAt,
  }) => _db.saveReminderSettings(isEnabled ? 1 : 0, minuteOfDay, updatedAt);

  /// Records when the last summary was posted (BR-185).
  Future<void> writeDelivered(DateTime deliveredAt) =>
      _db.markReminderDelivered(deliveredAt);

  /// The due workload per root deck, between [dayStart] and [now] (BR-188).
  Future<List<ReminderWorkloadPerRootDeckResult>> readWorkloadRows({
    required DateTime dayStart,
    required DateTime now,
  }) => _db.reminderWorkloadPerRootDeck(dayStart, now).get();
}
