import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminder/domain/failures/reminder_failure.dart';
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
    this.doesReadFail = false,
  });

  ReminderSettingsModel _settings;

  /// `false` makes the read never land, so the loading face holds still.
  final bool isRead;

  /// `true` rejects every save with [ReminderSetupRejection.settingsWriteFailed].
  final bool doesWriteFail;

  /// `true` makes the read fail, which is the only way into the screen's
  /// whole-screen error face (M6 S11, UC-17 E7).
  ///
  /// **It was the one state the catalogue could not reach**, and the comment
  /// above this class says why that matters: the states nobody can see are
  /// exactly the ones nobody reviews. S11 exists *because* that face went out
  /// showing the save copy for a read failure and no one read it.
  final bool doesReadFail;

  @override
  Stream<ReminderSettingsModel> watchSettings() {
    // Not `Stream.empty()`: an empty stream closes at once, and a closed stream
    // with no value is a state Riverpod may render differently from one still
    // waiting.
    if (!isRead) return StreamController<ReminderSettingsModel>().stream;
    if (doesReadFail) {
      return Stream<ReminderSettingsModel>.error(
        const DatabaseFailure(
          message: 'catalog: read refused',
          reason: ReminderSetupRejection.settingsWriteFailed,
        ),
      );
    }

    return Stream<ReminderSettingsModel>.value(_settings);
  }

  @override
  Future<ReminderSettingsModel> readSettings() async => _settings;

  @override
  Future<void> saveSettings({
    required bool isEnabled,
    required ReminderTime time,
  }) async {
    // A typed `Failure`, not a `StateError`. The controllers catch `on
    // Failure` and nothing else, and `EnableReminderUseCase` writes the
    // settings *before* its own `try` — so a bare throw here escaped as an
    // unhandled async error, `isSubmitting` never cleared, and the scenario
    // rendered as an indefinite lock indistinguishable from `submitting`
    // rather than as the banner it is labelled for. The real repository always
    // wraps; a double that does not is not standing in for it.
    if (doesWriteFail) {
      throw const DatabaseFailure(
        message: 'catalog: settings write refused',
        reason: ReminderSetupRejection.settingsWriteFailed,
      );
    }
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
    if (doesScheduleFail) {
      throw const ConflictFailure(
        message: 'catalog: schedule refused',
        reason: ReminderSetupRejection.scheduleFailed,
      );
    }
  }

  @override
  Future<void> cancel() async {
    if (doesCancelFail) {
      throw const ConflictFailure(
        message: 'catalog: cancel refused',
        reason: ReminderSetupRejection.cancelFailed,
      );
    }
  }

  @override
  Future<void> showSummary(ReminderSummaryModel summary) async {}
}
