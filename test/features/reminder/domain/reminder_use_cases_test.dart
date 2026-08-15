import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminder/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminder/domain/models/reminder_capability_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_settings_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminder/domain/usecases/change_reminder_time_use_case.dart';
import 'package:memox/features/reminder/domain/usecases/disable_reminder_use_case.dart';
import 'package:memox/features/reminder/domain/usecases/enable_reminder_use_case.dart';
import 'package:memox/features/reminder/domain/usecases/reconcile_reminder_schedule_use_case.dart';
import 'package:memox/features/reminder/domain/usecases/watch_reminder_overview_use_case.dart';

import '../support/fake_reminder_platform.dart';

/// Enable, disable, change-time, reconcile and the overview read.
///
/// Delivery has its own file — `reminder_delivery_use_case_test.dart` — split
/// when this one crossed the 400-line guard, along the seam it already had:
/// what the user's commands do, and what the fire-time run does.
///
/// Fixed inputs, because a reminder is entirely about *when* and a test that
/// read the wall clock would prove something different every hour.
final DateTime now = DateTime.utc(2026, 7, 29, 3);
const Duration offset = Duration(hours: 7);
final ReminderTime nine = ReminderTime.parse(9 * 60).time!;

void main() {
  late FakeReminderSettings settings;
  late FakeReminderPlatform platform;
  late ReconcileReminderScheduleUseCase reconcile;

  setUp(() {
    settings = FakeReminderSettings();
    platform = FakeReminderPlatform();
    reconcile = ReconcileReminderScheduleUseCase(settings, platform);
  });

  EnableReminderUseCase enable() =>
      EnableReminderUseCase(settings, platform, reconcile);

  group('enable (UC-17, BR-218, BR-228)', () {
    test('asks for permission only after the user opts in', () async {
      // Constructing the use case must not touch the OS; only calling it may.
      expect(platform.permissionRequests, 0);

      await enable()(time: nine, now: now, utcOffset: offset);

      expect(platform.permissionRequests, 1);
      expect(settings.current.isEnabled, isTrue);
      expect(platform.scheduled.single, nine);
    });

    test(
      'a refused permission leaves the setting off and nothing scheduled',
      () async {
        platform.permission = ReminderPermission.denied;

        await expectLater(
          enable()(time: nine, now: now, utcOffset: offset),
          throwsA(
            isA<Failure>().having(
              (failure) => failure.reason,
              'reason',
              ReminderSetupRejection.permissionDenied,
            ),
          ),
        );

        expect(settings.current.isEnabled, isFalse);
        expect(platform.scheduled, isEmpty);
        expect(settings.writes, isEmpty);
      },
    );

    test(
      'an unsupported platform refuses before the prompt (BR-229)',
      () async {
        platform.capability = ReminderCapability.unsupported;

        await expectLater(
          enable()(time: nine, now: now, utcOffset: offset),
          throwsA(
            isA<Failure>().having(
              (failure) => failure.reason,
              'reason',
              ReminderSetupRejection.platformUnavailable,
            ),
          ),
        );

        expect(platform.permissionRequests, 0);
        expect(settings.current.isEnabled, isFalse);
      },
    );

    test('a failed schedule is undone, so the setting never lies', () async {
      platform.shouldFailSchedule = true;

      await expectLater(
        enable()(time: nine, now: now, utcOffset: offset),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.reason,
            'reason',
            ReminderSetupRejection.scheduleFailed,
          ),
        ),
      );

      // The row was written and then written back — BR-228's "the setting stays
      // off when enabling does not complete".
      expect(settings.writes.map((row) => row.isEnabled), <bool>[true, false]);
      expect(settings.current.isEnabled, isFalse);
      expect(platform.scheduled, isEmpty);
    });
  });

  group('disable (UC-17 A2)', () {
    test('turns it off, cancels, and keeps the chosen time', () async {
      await enable()(time: nine, now: now, utcOffset: offset);

      await DisableReminderUseCase(settings, reconcile)(
        now: now,
        utcOffset: offset,
      );

      expect(settings.current.isEnabled, isFalse);
      expect(settings.current.time, nine);
      expect(platform.cancelCount, 1);
      expect(platform.scheduled, isEmpty);
    });

    test(
      'a failed cancel is reported and the setting still goes off',
      () async {
        await enable()(time: nine, now: now, utcOffset: offset);
        platform.shouldFailCancel = true;

        await expectLater(
          DisableReminderUseCase(settings, reconcile)(
            now: now,
            utcOffset: offset,
          ),
          throwsA(isA<Failure>()),
        );

        // Reverting to "on" would put the toggle back under a user who just
        // turned it off; the stale run is harmless because delivery re-checks.
        expect(settings.current.isEnabled, isFalse);
      },
    );
  });

  group('changeTime (UC-17 A1, BR-219)', () {
    test('reschedules while enabled', () async {
      await enable()(time: nine, now: now, utcOffset: offset);
      final ten = ReminderTime.parse(10 * 60).time!;

      await ChangeReminderTimeUseCase(settings, reconcile)(
        time: ten,
        now: now,
        utcOffset: offset,
      );

      expect(settings.current.time, ten);
      expect(platform.scheduled.single, ten);
    });

    test('works while disabled and schedules nothing', () async {
      await ChangeReminderTimeUseCase(settings, reconcile)(
        time: nine,
        now: now,
        utcOffset: offset,
      );

      expect(settings.current.time, nine);
      expect(settings.current.isEnabled, isFalse);
      expect(platform.scheduled, isEmpty);
    });

    test('a failed reschedule restores the previous time', () async {
      await enable()(time: nine, now: now, utcOffset: offset);
      platform.shouldFailSchedule = true;
      final ten = ReminderTime.parse(10 * 60).time!;

      await expectLater(
        ChangeReminderTimeUseCase(settings, reconcile)(
          time: ten,
          now: now,
          utcOffset: offset,
        ),
        throwsA(isA<Failure>()),
      );

      expect(settings.current.time, nine);
      expect(settings.current.isEnabled, isTrue);
    });

    test(
      'picking the time already stored writes and schedules nothing',
      () async {
        await enable()(time: nine, now: now, utcOffset: offset);
        final writesBefore = settings.writes.length;

        await ChangeReminderTimeUseCase(settings, reconcile)(
          time: nine,
          now: now,
          utcOffset: offset,
        );

        expect(settings.writes.length, writesBefore);
      },
    );
  });

  group('reconcile (BR-226, BR-227)', () {
    test('repeating it leaves exactly one pending run', () async {
      await enable()(time: nine, now: now, utcOffset: offset);

      await reconcile(now: now, utcOffset: offset);
      await reconcile(now: now, utcOffset: offset);
      await reconcile(now: now, utcOffset: offset);

      expect(platform.scheduled, hasLength(1));
    });

    test('a disabled reminder cancels instead of scheduling', () async {
      await reconcile(now: now, utcOffset: offset);

      expect(platform.scheduled, isEmpty);
      expect(platform.cancelCount, 1);
    });

    test('it never writes a setting', () async {
      // The schedule is derived state; a reconcile that wrote back would make
      // launch order able to change what the user chose.
      await enable()(time: nine, now: now, utcOffset: offset);
      final writesBefore = settings.writes.length;

      await reconcile(now: now, utcOffset: offset);

      expect(settings.writes.length, writesBefore);
    });

    test('nothing delivered yet means no anchor at all', () async {
      await enable()(time: nine, now: now, utcOffset: offset);

      expect(platform.lastNotBefore, isNull);
    });

    test('a delivered day is skipped, by every caller (BR-221)', () async {
      await enable()(time: nine, now: now, utcOffset: offset);
      // 01:00 local on the 30th: a run for the 29th that Doze pushed past
      // midnight, so the 30th has had its summary.
      final deliveredAt = DateTime.utc(2026, 7, 29, 18);
      await settings.markDelivered(deliveredAt);

      // The launch reconcile, which knows nothing about that run.
      await reconcile(
        now: deliveredAt.add(const Duration(minutes: 5)),
        utcOffset: offset,
      );

      // Midnight local on the 31st — the 30th is finished. While this was a
      // parameter only the worker passed, this reconcile put the 30th back and
      // the user was alerted twice in one local day.
      expect(platform.lastNotBefore, DateTime.utc(2026, 7, 30, 17));
    });

    test('a delivery stamped in the future anchors nothing', () async {
      // Same reason the delivery guard ignores it: the anchor would otherwise
      // sit days ahead with nothing in the app able to rewrite the column.
      await enable()(time: nine, now: now, utcOffset: offset);
      await settings.markDelivered(now.add(const Duration(days: 30)));

      await reconcile(now: now, utcOffset: offset);

      expect(platform.lastNotBefore, isNull);
    });

    test('a changed offset reschedules against the new one', () async {
      await enable()(time: nine, now: now, utcOffset: offset);

      await reconcile(now: now, utcOffset: const Duration(hours: -5));

      expect(platform.scheduled, hasLength(1));
    });
  });

  group('watchOverview (AD-13, BR-229)', () {
    test('carries the capability beside the stored settings', () async {
      final overview = await WatchReminderOverviewUseCase(
        settings,
        platform,
      )().first;

      expect(overview.capability, ReminderCapability.supported);
      expect(overview.settings, ReminderSettingsModel.initial);
      expect(overview.isChangeable, isTrue);
    });

    test('a platform that will not answer reads as unsupported', () async {
      // The honest outcome of "the channel threw" is a screen saying reminders
      // are not available here — not a red error the user can do nothing with.
      final overview = await WatchReminderOverviewUseCase(
        settings,
        _ThrowingPlatform(),
      )().first;

      expect(overview.capability, ReminderCapability.unsupported);
      expect(overview.isChangeable, isFalse);
    });
  });
}

/// A platform whose capability read throws, to prove the honest fallback.
class _ThrowingPlatform extends FakeReminderPlatform {
  @override
  Future<ReminderCapability> readCapability() async =>
      throw StateError('no channel');
}
