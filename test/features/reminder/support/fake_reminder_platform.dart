import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminder/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminder/domain/models/reminder_capability_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_summary_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_workload_model.dart';
import 'package:memox/features/reminder/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/reminder/domain/repositories/reminder_settings_repository.dart';
import 'package:memox/features/reminder/domain/repositories/reminder_workload_repository.dart';

/// The three contracts, faked at the domain boundary.
///
/// **A fake platform, never the real plugins.** A host suite must not post a
/// notification — there is nothing to post it to, and a test that could would be
/// a test that sometimes rings a developer's phone. Faking at the contract is
/// also what lets the permission and capability branches be driven directly,
/// which is the half a device test cannot reach on demand.
class FakeReminderPlatform implements ReminderPlatformRepository {
  FakeReminderPlatform({
    this.capability = ReminderCapability.supported,
    this.permission = ReminderPermission.granted,
    this.shouldFailSchedule = false,
    this.shouldFailCancel = false,
    this.permissionGate,
  });

  ReminderCapability capability;
  ReminderPermission permission;
  bool shouldFailSchedule;
  bool shouldFailCancel;

  /// Held open, the permission request never answers — which is the only way a
  /// widget test can stop on the submitting frame and measure it.
  ///
  /// Without this every command here resolves on the same microtask as the tap,
  /// so the first `pump()` after a tap already shows the settled state and a
  /// test claiming to measure "while submitting" measures "after it finished"
  /// three times. That is how the M6 G5 height check passed against a card
  /// deliberately grown by 120dp mid-write.
  final Completer<ReminderPermission>? permissionGate;

  /// Held open, a `schedule` never answers — the only way a widget test can
  /// stop on the *submitting* frame of a time change and measure it.
  ///
  /// [permissionGate] does this for the enable path and records the reason;
  /// this is the same device for the reschedule path. Checked before
  /// [shouldFailSchedule] so one test can hold a retry open, flip the failure
  /// flag while it waits, and let it settle either way.
  Completer<void>? scheduleGate;

  /// Every schedule ever asked for, so idempotency is asserted on the count
  /// rather than on a boolean somebody has to reset.
  final List<ReminderTime> scheduled = <ReminderTime>[];

  /// The `notBefore` of the last schedule, which is the half of BR-221 a
  /// contract fake can observe: the delay itself belongs to the adapter and is
  /// asserted there.
  DateTime? lastNotBefore;
  final List<ReminderSummaryModel> shown = <ReminderSummaryModel>[];
  int cancelCount = 0;
  int permissionRequests = 0;

  @override
  Future<ReminderCapability> readCapability() async => capability;

  @override
  Future<ReminderPermission> requestPermission() async {
    permissionRequests++;
    final gate = permissionGate;
    if (gate != null) return gate.future;

    return permission;
  }

  @override
  Future<void> schedule({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
    DateTime? notBefore,
  }) async {
    lastNotBefore = notBefore;
    final gate = scheduleGate;
    if (gate != null) await gate.future;
    if (shouldFailSchedule) {
      throw const ConflictFailure(
        message: 'refused',
        reason: ReminderSetupRejection.scheduleFailed,
      );
    }
    // Replace rather than append a second pending run: this is the contract
    // BR-227 puts on a real scheduler, so the fake has to keep it or the
    // idempotency assertions would prove nothing about production.
    scheduled
      ..clear()
      ..add(time);
  }

  @override
  Future<void> cancel() async {
    if (shouldFailCancel) {
      throw const ConflictFailure(
        message: 'refused',
        reason: ReminderSetupRejection.scheduleFailed,
      );
    }
    cancelCount++;
    scheduled.clear();
  }

  @override
  Future<void> showSummary(ReminderSummaryModel summary) async =>
      shown.add(summary);
}

/// The settings row, in memory, with a stream that re-emits on write.
///
/// **A broadcast controller, not `Stream.value`.** Drift re-emits a watched row
/// after every write, and a fake that emitted once would let a screen pass its
/// test while never updating in the app — which is the exact failure the stream
/// exists to prevent.
class FakeReminderSettings implements ReminderSettingsRepository {
  FakeReminderSettings([this._current = ReminderSettingsModel.initial]);

  ReminderSettingsModel _current;

  /// Every delivery ever recorded, so BR-221's day skip is asserted on what was
  /// written rather than on a flag somebody has to reset.
  final List<DateTime> deliveries = <DateTime>[];
  final StreamController<ReminderSettingsModel> _changes =
      StreamController<ReminderSettingsModel>.broadcast();
  final List<ReminderSettingsModel> writes = <ReminderSettingsModel>[];
  bool shouldFailWrite = false;

  /// `true` makes the stream fail instead of emitting, which is the only way to
  /// reach the screen's whole-screen error face — the one that used to show the
  /// *save* copy for a failure that was a read.
  bool shouldFailRead = false;

  /// Held open, the **next** `saveSettings` never lands — which is how a widget
  /// test reaches the one frame between a command starting and its optimistic
  /// write arriving on the settings stream.
  ///
  /// One-shot on purpose: `ChangeReminderTimeUseCase` writes, reconciles, and
  /// on failure writes again to roll back. A gate that held every save would
  /// deadlock that rollback and prove nothing.
  Completer<void>? saveGate;

  ReminderSettingsModel get current => _current;

  @override
  Stream<ReminderSettingsModel> watchSettings() async* {
    if (shouldFailRead) {
      throw const DatabaseFailure(
        message: 'read refused',
        reason: ReminderSetupRejection.settingsWriteFailed,
      );
    }
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<ReminderSettingsModel> readSettings() async => _current;

  @override
  Future<void> saveSettings({
    required bool isEnabled,
    required ReminderTime time,
  }) async {
    final gate = saveGate;
    if (gate != null) {
      saveGate = null;
      await gate.future;
    }
    if (shouldFailWrite) {
      throw const DatabaseFailure(
        message: 'write refused',
        reason: ReminderSetupRejection.settingsWriteFailed,
      );
    }
    _current = ReminderSettingsModel(
      isEnabled: isEnabled,
      time: time,
      // Preserved, the way one `UPDATE` of two columns preserves the third: a
      // fake that dropped it would hide a repository that does not.
      lastDeliveredAt: _current.lastDeliveredAt,
    );
    writes.add(_current);
    _changes.add(_current);
  }

  @override
  Future<void> markDelivered(DateTime deliveredAt) async {
    // Honours the same switch as `saveSettings`: the interesting case is a
    // notification that was posted and then failed to be recorded, and a fake
    // that could not fail there would make that branch untestable.
    if (shouldFailWrite) {
      throw const DatabaseFailure(
        message: 'write refused',
        reason: ReminderSetupRejection.settingsWriteFailed,
      );
    }
    deliveries.add(deliveredAt);
    _current = _current.copyWith(lastDeliveredAt: deliveredAt);
    _changes.add(_current);
  }
}

/// The workload, as a list the test hands over.
class FakeReminderWorkload implements ReminderWorkloadRepository {
  FakeReminderWorkload([this.workloads = const <ReminderWorkloadModel>[]]);

  List<ReminderWorkloadModel> workloads;
  int reads = 0;

  @override
  Future<List<ReminderWorkloadModel>> readWorkload({
    required DateTime now,
    required Duration utcOffset,
  }) async {
    reads++;

    return workloads;
  }
}
