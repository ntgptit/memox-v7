import 'package:memox/features/reminder/domain/models/reminder_capability_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_summary_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminder/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/reminder/domain/repositories/reminder_settings_repository.dart';

/// The reminder screen's two contracts, satisfied by the catalog itself.
///
/// **The catalog needs its own doubles, for the reason `StudyCatalogRepository`
/// states**: the app's fakes live under `test/`, and a second package cannot
/// import them. These are deliberately the thinnest thing that renders a state
/// — no scheduling, no permission prompt, and nothing that could reach a
/// notification plugin from a catalog someone is browsing.
class ReminderCatalogSettings implements ReminderSettingsRepository {
  ReminderCatalogSettings(this._settings);

  ReminderSettingsModel _settings;

  @override
  Stream<ReminderSettingsModel> watchSettings() =>
      Stream<ReminderSettingsModel>.value(_settings);

  @override
  Future<ReminderSettingsModel> readSettings() async => _settings;

  @override
  Future<void> saveSettings({
    required bool isEnabled,
    required ReminderTime time,
  }) async {
    _settings = ReminderSettingsModel(isEnabled: isEnabled, time: time);
  }
}

/// A platform that answers with one capability and does nothing else.
///
/// Every write is a no-op rather than a throw: a catalog is browsed, not
/// driven, and a toggle that threw would put a red screen in front of whoever
/// was looking at the colours.
class ReminderCatalogPlatform implements ReminderPlatformRepository {
  const ReminderCatalogPlatform(this.capability);

  final ReminderCapability capability;

  @override
  Future<ReminderCapability> readCapability() async => capability;

  @override
  Future<ReminderPermission> requestPermission() async =>
      ReminderPermission.granted;

  @override
  Future<void> schedule({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
  }) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> showSummary(ReminderSummaryModel summary) async {}
}
