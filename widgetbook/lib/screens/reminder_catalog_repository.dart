import 'dart:async';

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
///
/// **They fail and they hang, on request.** The first version of this file was
/// incapable of both: every read landed, every write succeeded on the same
/// microtask, and the screen's busy state and all five of its rejections were
/// unreachable here. A screen owning three controllers and five typed
/// rejections had three states in its catalog, and the states nobody can see
/// are exactly the ones nobody reviews.
class ReminderCatalogSettings implements ReminderSettingsRepository {
  ReminderCatalogSettings(
    this._settings, {
    this.isRead = true,
    this.doesWriteFail = false,
  });

  ReminderSettingsModel _settings;

  /// `false` makes the read never land, so the loading face holds still.
  final bool isRead;

  /// `true` rejects every save with [ReminderSetupRejection.settingsWriteFailed].
  final bool doesWriteFail;

  @override
  Stream<ReminderSettingsModel> watchSettings() {
    // Not `Stream.empty()`: an empty stream closes at once, and a closed stream
    // with no value is a state Riverpod may render differently from one still
    // waiting.
    if (!isRead) return StreamController<ReminderSettingsModel>().stream;

    return Stream<ReminderSettingsModel>.value(_settings);
  }

  @override
  Future<ReminderSettingsModel> readSettings() async => _settings;

  @override
  Future<void> saveSettings({
    required bool isEnabled,
    required ReminderTime time,
  }) async {
    if (doesWriteFail) throw StateError('catalog: settings write refused');
    _settings = ReminderSettingsModel(isEnabled: isEnabled, time: time);
  }

  @override
  Future<void> markDelivered(DateTime deliveredAt) async {}
}

/// A platform that answers with one capability, and fails or stalls on request.
///
/// A write is a no-op unless the scenario asked for a failure: a catalog is
/// browsed, not driven, and a toggle that threw by default would put a red
/// screen in front of whoever was looking at the colours.
class ReminderCatalogPlatform implements ReminderPlatformRepository {
  const ReminderCatalogPlatform(
    this.capability, {
    this.permission = ReminderPermission.granted,
    this.doesScheduleFail = false,
    this.doesCancelFail = false,
    this.doesPermissionStall = false,
  });

  final ReminderCapability capability;

  /// What the OS answers when the user turns the reminder on (BR-228).
  final ReminderPermission permission;

  final bool doesScheduleFail;
  final bool doesCancelFail;

  /// `true` leaves the permission request in flight forever, which is the only
  /// way to hold the submitting face still long enough to look at it — the
  /// group locked, its label saying so, the rest of the screen still readable.
  final bool doesPermissionStall;

  @override
  Future<ReminderCapability> readCapability() async => capability;

  @override
  Future<ReminderPermission> requestPermission() async {
    if (doesPermissionStall) return Completer<ReminderPermission>().future;

    return permission;
  }

  @override
  Future<void> schedule({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
    DateTime? notBefore,
  }) async {
    if (doesScheduleFail) throw StateError('catalog: schedule refused');
  }

  @override
  Future<void> cancel() async {
    if (doesCancelFail) throw StateError('catalog: cancel refused');
  }

  @override
  Future<void> showSummary(ReminderSummaryModel summary) async {}
}
