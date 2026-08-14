import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminder/data/datasources/reminder_notification_data_source.dart';
import 'package:memox/features/reminder/data/datasources/reminder_scheduler_data_source.dart';
import 'package:memox/features/reminder/data/repositories/android_reminder_platform_repository_impl.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workmanager/workmanager.dart';

/// The delay handed to the OS, which is the one number nothing above `data/`
/// can see.
///
/// **This test exists because a review found the delay measured from the wrong
/// instant.** The fire *occurrence* is chosen from `notBefore` — BR-185 pushes
/// it past `now` after a run that slipped into the next local day — while the
/// *delay* must be measured from the wall clock, because WorkManager counts
/// `initialDelay` forward from the moment it accepts the work. While the two
/// were one parameter the reminder fired four hours early, then four hours
/// earlier again the next night, until two landed in one day.
///
/// It mocks WorkManager rather than the data source: `ReminderSchedulerDataSource`
/// is a `final class`, and the seam that exists for tests is its constructor.
class _MockWorkmanager extends Mock implements Workmanager {}

void main() {
  const offset = Duration(hours: 7);
  final eightPm = ReminderTime.parse(20 * 60).time!;

  late _MockWorkmanager workmanager;
  late AndroidReminderPlatformRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(ExistingWorkPolicy.replace);
  });

  setUp(() {
    workmanager = _MockWorkmanager();
    when(
      () => workmanager.registerOneOffTask(
        any(),
        any(),
        initialDelay: any(named: 'initialDelay'),
        existingWorkPolicy: any(named: 'existingWorkPolicy'),
      ),
    ).thenAnswer((_) async {});

    repository = AndroidReminderPlatformRepositoryImpl(
      notifier: ReminderNotificationDataSource(),
      scheduler: ReminderSchedulerDataSource(workmanager: workmanager),
    );
  });

  Duration capturedDelay() =>
      verify(
            () => workmanager.registerOneOffTask(
              kReminderWorkName,
              kReminderTaskName,
              initialDelay: captureAny(named: 'initialDelay'),
              existingWorkPolicy: any(named: 'existingWorkPolicy'),
            ),
          ).captured.single
          as Duration;

  test(
    'without a notBefore the delay is the time to the next occurrence',
    () async {
      // 10:00 local; 20:00 local the same day is ten hours away.
      await repository.schedule(
        time: eightPm,
        now: DateTime.utc(2026, 7, 29, 3),
        utcOffset: offset,
      );

      expect(capturedDelay(), const Duration(hours: 10));
    },
  );

  test('a notBefore moves the occurrence without shortening the delay', () async {
    // The scenario the split exists for: the run fired at 20:00 local on day N,
    // so the next occurrence must be chosen from midnight on day N+1 — but the
    // work is being enqueued *now*, at 20:00 on day N, and the OS counts from
    // there. Twenty-four hours, not the twenty the anchor alone would give.
    final now = DateTime.utc(2026, 7, 29, 13);

    await repository.schedule(
      time: eightPm,
      now: now,
      utcOffset: offset,
      notBefore: DateTime.utc(2026, 7, 29, 17),
    );

    expect(capturedDelay(), const Duration(hours: 24));
  });

  test('a run deferred past midnight still waits a whole day', () async {
    // Doze pushed the 20:00 run to 01:00 the next morning. The day it landed in
    // has been served, so the next one is 20:00 the day after — 43 hours out,
    // and every hour of that has to be in the delay or the OS fires early.
    final now = DateTime.utc(2026, 7, 29, 18);

    await repository.schedule(
      time: eightPm,
      now: now,
      utcOffset: offset,
      notBefore: DateTime.utc(2026, 7, 30, 17),
    );

    expect(capturedDelay(), const Duration(hours: 43));
  });

  test('a notBefore already behind us falls back to the ordinary next '
      'occurrence', () async {
    // Clamping the *delay* to zero instead would turn a stale anchor into
    // "fire immediately" — an unscheduled notification, which is itself a way
    // to break BR-185. Clamping the anchor gives the ordinary answer.
    // 10:00 local, so the ordinary answer is the ten hours the first test
    // measures without an anchor at all.
    await repository.schedule(
      time: eightPm,
      now: DateTime.utc(2026, 7, 29, 3),
      utcOffset: offset,
      notBefore: DateTime.utc(2026, 7, 20),
    );

    expect(capturedDelay(), const Duration(hours: 10));
  });

  test('the work is replaced, never stacked (BR-191)', () async {
    await repository.schedule(
      time: eightPm,
      now: DateTime.utc(2026, 7, 29, 3),
      utcOffset: offset,
    );

    verify(
      () => workmanager.registerOneOffTask(
        kReminderWorkName,
        kReminderTaskName,
        initialDelay: any(named: 'initialDelay'),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      ),
    ).called(1);
  });
}
