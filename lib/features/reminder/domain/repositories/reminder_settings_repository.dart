import '../models/reminder_settings_model.dart';
import '../models/reminder_time_model.dart';

/// The stored half of the reminder: what the user chose (BR-182, BR-183).
///
/// **A stream and a read, and both exist.** The screen watches, because the
/// settings row is the source of truth and a toggle that shows a value the
/// database rejected is a lie. The background worker reads once, because it has
/// no widget tree to keep a subscription alive in and needs one answer.
abstract interface class ReminderSettingsRepository {
  /// The stored choice, re-emitted whenever the settings row changes.
  Stream<ReminderSettingsModel> watchSettings();

  /// The stored choice, once.
  Future<ReminderSettingsModel> readSettings();

  /// Writes both fields together.
  ///
  /// **One write, not two.** "Enabled" and "at this time" are one decision, and
  /// splitting them lets a failure land between the halves — a reminder that is
  /// on at a time the user did not pick. [ReminderTime] rather than an `int`,
  /// so the range check cannot be skipped by a caller.
  Future<void> saveSettings({
    required bool isEnabled,
    required ReminderTime time,
  });

  /// Records that a summary was posted at [deliveredAt] (BR-185).
  ///
  /// **Separate from [saveSettings] because it is a different author.** That
  /// one writes what the user chose; this one writes what the system did, from
  /// a background isolate, possibly while the user is changing a setting in the
  /// foreground. One statement each, one column each, so neither can overwrite
  /// the other's work.
  Future<void> markDelivered(DateTime deliveredAt);
}
