import 'reminder_time_model.dart';

/// What the user has decided about the daily reminder (BR-182, BR-183).
///
/// **The time survives being turned off.** A user who disables the reminder and
/// re-enables it a week later gets their own time back, not 20:00 again — so
/// the two fields are independent, and `isEnabled` is not encoded as a nullable
/// time. It also lets the settings screen show the time while the toggle is
/// off, which is what stops the row appearing and disappearing under the finger
/// that just moved the toggle.
final class ReminderSettingsModel {
  const ReminderSettingsModel({required this.isEnabled, required this.time});

  /// The state a database that has never been written reads as (BR-182).
  static const ReminderSettingsModel initial = ReminderSettingsModel(
    isEnabled: false,
    time: ReminderTime.suggested,
  );

  final bool isEnabled;
  final ReminderTime time;

  ReminderSettingsModel copyWith({bool? isEnabled, ReminderTime? time}) =>
      ReminderSettingsModel(
        isEnabled: isEnabled ?? this.isEnabled,
        time: time ?? this.time,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettingsModel &&
      other.isEnabled == isEnabled &&
      other.time == time;

  @override
  int get hashCode => Object.hash(isEnabled, time);
}
