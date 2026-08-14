import 'reminder_capability_model.dart';
import 'reminder_settings_model.dart';

/// Everything the reminder screen needs to draw one frame (AD-13).
///
/// **One read, not two.** The screen needs the stored settings *and* what the
/// device can do; asked separately they are two snapshots, and the screen can
/// then draw a toggle from before a write beside a capability from after one.
/// Worse in this particular pairing: an enabled toggle rendered next to a
/// capability that has just come back `unsupported` is a control that looks
/// live and is not.
final class ReminderOverviewModel {
  const ReminderOverviewModel({
    required this.settings,
    required this.capability,
  });

  final ReminderSettingsModel settings;
  final ReminderCapability capability;

  /// Whether the user may operate the toggle at all (BR-193).
  bool get isChangeable => capability == ReminderCapability.supported;

  @override
  bool operator ==(Object other) =>
      other is ReminderOverviewModel &&
      other.settings == settings &&
      other.capability == capability;

  @override
  int get hashCode => Object.hash(settings, capability);
}
