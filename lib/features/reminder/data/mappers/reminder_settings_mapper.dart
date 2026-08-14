import '../../../../core/database/app_database.dart';
import '../../domain/models/reminder_settings_model.dart';
import '../../domain/models/reminder_time_model.dart';

/// The `app_settings` row, as the reminder feature sees it.
///
/// **The two study columns are dropped here and that is the boundary working.**
/// One table serves two features; each maps out only what it owns, so a change
/// to `card_limit` cannot reach this feature and a Drift row never becomes a
/// domain model (AD-01).
///
/// `ReminderTime.fromStored` clamps rather than rejects: a minute outside the
/// range is not a reason to refuse to open the settings screen, and the clamp
/// shows up the moment it does open.
abstract final class ReminderSettingsMapper {
  static ReminderSettingsModel toModel(AppSetting row) => ReminderSettingsModel(
    isEnabled: row.reminderEnabled == 1,
    time: ReminderTime.fromStored(row.reminderMinuteOfDay),
  );
}
