import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminder/domain/models/reminder_delivery_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_workload_model.dart';
import 'package:memox/features/reminder/domain/usecases/deliver_daily_reminder_use_case.dart';
import 'package:memox/features/reminder/domain/usecases/disable_reminder_use_case.dart';
import 'package:memox/features/reminder/domain/usecases/enable_reminder_use_case.dart';
import 'package:memox/features/reminder/domain/usecases/reconcile_reminder_schedule_use_case.dart';

import '../support/fake_reminder_platform.dart';

/// The fire-time run: what it posts, and every reason it posts nothing.
///
/// The command half is `reminder_use_cases_test.dart`.
///
/// Fixed inputs, because a reminder is entirely about *when* and a test that
/// read the wall clock would prove something different every hour.
final DateTime now = DateTime.utc(2026, 7, 29, 3);
const Duration offset = Duration(hours: 7);
final ReminderTime nine = ReminderTime.parse(9 * 60).time!;

void main() {
  late FakeReminderSettings settings;
  late FakeReminderPlatform platform;
  late FakeReminderWorkload workload;
  late ReconcileReminderScheduleUseCase reconcile;

  setUp(() {
    settings = FakeReminderSettings();
    platform = FakeReminderPlatform();
    workload = FakeReminderWorkload();
    reconcile = ReconcileReminderScheduleUseCase(settings, platform);
  });

  EnableReminderUseCase enable() =>
      EnableReminderUseCase(settings, platform, reconcile);

  group('deliver (BR-184, BR-185, BR-186)', () {
    DeliverDailyReminderUseCase deliver() =>
        DeliverDailyReminderUseCase(settings, workload, platform);

    setUp(() async {
      await enable()(time: nine, now: now, utcOffset: offset);
    });

    test('posts one summary when something is owed', () async {
      workload.workloads = <ReminderWorkloadModel>[
        const ReminderWorkloadModel(
          deckId: 'a',
          deckName: 'Kanji',
          overdueCount: 2,
          dueTodayCount: 1,
          overdueDayCount: 4,
        ),
      ];

      final outcome = await deliver()(now: now, utcOffset: offset);

      expect(outcome, ReminderDelivery.posted);
      expect(platform.shown.single.totalDueCount, 3);
      expect(platform.shown.single.leadDeckName, 'Kanji');
      // Recorded, so the day it served survives the isolate that served it
      // (BR-185).
      expect(settings.deliveries, <DateTime>[now]);
    });

    test('an empty workload at fire time posts nothing (BR-184)', () async {
      final outcome = await deliver()(now: now, utcOffset: offset);

      expect(outcome, ReminderDelivery.skippedNothingDue);
      expect(platform.shown, isEmpty);
      // A day with nothing owed has not been served, so it must not be marked.
      expect(settings.deliveries, isEmpty);
    });

    test(
      'a day that has already had its summary posts nothing (BR-185)',
      () async {
        // The schedule is not the only thing that can post twice: a run that
        // delivered and then threw on its way out reports failure, and
        // WorkManager retries it with the same settings and the same unstudied
        // cards.
        workload.workloads = <ReminderWorkloadModel>[
          const ReminderWorkloadModel(
            deckId: 'a',
            deckName: 'Kanji',
            overdueCount: 2,
            dueTodayCount: 1,
            overdueDayCount: 4,
          ),
        ];
        expect(
          await deliver()(now: now, utcOffset: offset),
          ReminderDelivery.posted,
        );

        final retried = await deliver()(
          now: now.add(const Duration(minutes: 2)),
          utcOffset: offset,
        );

        expect(retried, ReminderDelivery.skippedAlreadyServed);
        expect(platform.shown, hasLength(1));
      },
    );

    test('a delivery on an earlier local day blocks nothing', () async {
      workload.workloads = <ReminderWorkloadModel>[
        const ReminderWorkloadModel(
          deckId: 'a',
          deckName: 'Kanji',
          overdueCount: 2,
          dueTodayCount: 1,
          overdueDayCount: 4,
        ),
      ];
      // Delivered at 01:00 local on the 30th — a run for the 29th that Doze
      // pushed past midnight. That serves the 30th, and BR-185 asks for at most
      // one per day, not one per two days: the 31st must still fire.
      await settings.markDelivered(DateTime.utc(2026, 7, 29, 18));

      final outcome = await deliver()(
        // 20:00 local on the 31st.
        now: DateTime.utc(2026, 7, 31, 13),
        utcOffset: offset,
      );

      expect(outcome, ReminderDelivery.posted);
    });

    test('a reminder turned off since scheduling posts nothing', () async {
      // A cancel that did not take is the one thing a background run cannot
      // prevent, so the run re-reads rather than trusting it.
      await DisableReminderUseCase(settings, reconcile)(
        now: now,
        utcOffset: offset,
      );
      workload.workloads = <ReminderWorkloadModel>[
        const ReminderWorkloadModel(
          deckId: 'a',
          deckName: 'Kanji',
          overdueCount: 5,
          dueTodayCount: 0,
          overdueDayCount: 1,
        ),
      ];

      final outcome = await deliver()(now: now, utcOffset: offset);

      expect(outcome, ReminderDelivery.skippedDisabled);
      expect(platform.shown, isEmpty);
      // It stops before reading the workload at all.
      expect(workload.reads, 0);
    });
  });
}
