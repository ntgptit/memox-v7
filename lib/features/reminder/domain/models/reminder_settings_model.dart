import 'reminder_time_model.dart';

/// What the user has decided about the daily reminder (BR-218, BR-219).
///
/// **The time survives being turned off.** A user who disables the reminder and
/// re-enables it a week later gets their own time back, not 20:00 again — so
/// the two fields are independent, and `isEnabled` is not encoded as a nullable
/// time. It also lets the settings screen show the time while the toggle is
/// off, which is what stops the row appearing and disappearing under the finger
/// that just moved the toggle.
final class ReminderSettingsModel {
  const ReminderSettingsModel({
    required this.isEnabled,
    required this.time,
    this.lastDeliveredAt,
  });

  /// The state a database that has never been written reads as (BR-218).
  static const ReminderSettingsModel initial = ReminderSettingsModel(
    isEnabled: false,
    time: ReminderTime.suggested,
  );

  final bool isEnabled;
  final ReminderTime time;

  /// When a summary was last posted, or `null` if none ever has been (BR-221).
  ///
  /// **Not a preference, and it lives here anyway.** It is a column of the same
  /// one-row table, and the reconcile needs it together with the time and the
  /// flag — asking for it separately would be a second snapshot of one row, and
  /// the schedule would then be derived from two moments (AD-13).
  final DateTime? lastDeliveredAt;

  ReminderSettingsModel copyWith({
    bool? isEnabled,
    ReminderTime? time,
    DateTime? lastDeliveredAt,
  }) => ReminderSettingsModel(
    isEnabled: isEnabled ?? this.isEnabled,
    time: time ?? this.time,
    lastDeliveredAt: lastDeliveredAt ?? this.lastDeliveredAt,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettingsModel &&
      other.isEnabled == isEnabled &&
      other.time == time &&
      other.lastDeliveredAt == lastDeliveredAt;

  @override
  int get hashCode => Object.hash(isEnabled, time, lastDeliveredAt);
}
