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
  });

  ReminderCapability capability;
  ReminderPermission permission;
  bool shouldFailSchedule;
  bool shouldFailCancel;

  /// Every schedule ever asked for, so idempotency is asserted on the count
  /// rather than on a boolean somebody has to reset.
  final List<ReminderTime> scheduled = <ReminderTime>[];
  final List<ReminderSummaryModel> shown = <ReminderSummaryModel>[];
  int cancelCount = 0;
  int permissionRequests = 0;

  @override
  Future<ReminderCapability> readCapability() async => capability;

  @override
  Future<ReminderPermission> requestPermission() async {
    permissionRequests++;

    return permission;
  }

  @override
  Future<void> schedule({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
  }) async {
    if (shouldFailSchedule) {
      throw const ConflictFailure(
        message: 'refused',
        reason: ReminderSetupRejection.scheduleFailed,
      );
    }
    // Replace rather than append a second pending run: this is the contract
    // BR-191 puts on a real scheduler, so the fake has to keep it or the
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
  final StreamController<ReminderSettingsModel> _changes =
      StreamController<ReminderSettingsModel>.broadcast();
  final List<ReminderSettingsModel> writes = <ReminderSettingsModel>[];
  bool shouldFailWrite = false;

  ReminderSettingsModel get current => _current;

  @override
  Stream<ReminderSettingsModel> watchSettings() async* {
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
    if (shouldFailWrite) {
      throw const DatabaseFailure(
        message: 'write refused',
        reason: ReminderSetupRejection.settingsWriteFailed,
      );
    }
    _current = ReminderSettingsModel(isEnabled: isEnabled, time: time);
    writes.add(_current);
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
