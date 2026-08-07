import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_schedule_model.dart';
import 'package:memox/features/study/domain/models/sm2_scheduler.dart';
import 'package:memox/features/study/domain/models/study_scheduler.dart';

/// BR-17, BR-18 and BR-19 — the quality scale, the interval, and the floor.
void main() {
  const scheduler = Sm2Scheduler();

  StudyScheduleUpdateModel answer({
    required StudyAction action,
    double easeFactor = kInitialEaseFactor,
    int intervalDays = kFirstIntervalDays,
    int repetitions = 0,
  }) => scheduler.next(
    schedule: StudyScheduleModel(
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      repetitions: repetitions,
    ),
    action: action,
  );

  group('what the algorithm declares', () {
    test('four actions, two stages, one review mode', () {
      expect(scheduler.type, SchedulerType.sm2);
      expect(scheduler.supportedActions, <StudyAction>[
        StudyAction.again,
        StudyAction.hard,
        StudyAction.good,
        StudyAction.easy,
      ]);
      expect(scheduler.stageSequence, <StudyMode>[
        StudyMode.browse,
        StudyMode.selfAssess,
      ]);
      expect(scheduler.reviewModes, <StudyMode>[StudyMode.selfAssess]);
    });

    test('it grades nothing, so it maps no boolean (BR-106)', () {
      // `self_assess` takes the action straight from the user. Inventing a
      // right/wrong mapping here would be inventing business nobody decided,
      // and null is what makes a caller's mistake visible.
      expect(scheduler.binaryAction(isCorrect: true), isNull);
      expect(scheduler.binaryAction(isCorrect: false), isNull);
    });

    test('its actions do not overlap eight_box (BR-30)', () {
      expect(
        scheduler.supportedActions.toSet().intersection(const <StudyAction>{
          StudyAction.forgotten,
          StudyAction.remembered,
        }),
        isEmpty,
      );
    });
  });

  group('BR-18 · interval and repetitions', () {
    test('repetitions 0 gives one day, and moves to 1', () {
      final result = answer(action: StudyAction.good);

      expect(result.intervalDays, 1);
      expect(result.schedule.repetitions, 1);
    });

    test('repetitions 1 gives six days, and moves to 2', () {
      final result = answer(action: StudyAction.good, repetitions: 1);

      expect(result.intervalDays, 6);
      expect(result.schedule.repetitions, 2);
    });

    test('from repetitions 2 the interval multiplies by the ease factor', () {
      final result = answer(
        action: StudyAction.good,
        repetitions: 2,
        intervalDays: 6,
      );

      expect(result.intervalDays, 15);
      expect(result.schedule.repetitions, 3);
    });

    test('the multiplication uses the factor BR-19 just produced', () {
      // The order is part of BR-18: the ease factor updates first, then the
      // interval multiplies by the new value.
      //
      // `good` leaves the factor at 2.5, so it cannot tell the two readings
      // apart. `hard` can: it takes 2.5 to 2.36, and a card at ten days lands
      // on 24 rather than 25. This test is the whole difference between the
      // readings, which is why it names both numbers.
      final result = answer(
        action: StudyAction.hard,
        repetitions: 2,
        intervalDays: 10,
      );

      // 10 × 2.36 = 23.6 → 24, not 10 × 2.5 = 25.
      expect(result.intervalDays, 24);
      expect(result.schedule.easeFactor, closeTo(2.36, 0.0001));
    });

    test('a failing answer resets to one day and zero repetitions', () {
      final result = answer(
        action: StudyAction.again,
        repetitions: 7,
        intervalDays: 200,
      );

      expect(result.intervalDays, 1);
      expect(result.schedule.repetitions, 0);
    });

    test('the rounding is to the nearest day, not truncation', () {
      // 3 × 1.5 is 4.5. Truncating would lose half a day on every repetition,
      // which over a long-interval card is weeks.
      final result = answer(
        action: StudyAction.good,
        repetitions: 4,
        intervalDays: 3,
        easeFactor: 1.5,
      );

      expect(result.intervalDays, 5);
    });
  });

  group('BR-19 · the ease factor', () {
    const expected = <StudyAction, double>{
      // q = 0: 2.5 + (0.1 − 5 × (0.08 + 5 × 0.02)) = 2.5 − 0.8
      StudyAction.again: 1.7,
      // q = 3: 2.5 + (0.1 − 2 × (0.08 + 2 × 0.02)) = 2.5 − 0.14
      StudyAction.hard: 2.36,
      // q = 4: 2.5 + (0.1 − 1 × (0.08 + 1 × 0.02)) = 2.5 + 0.0
      StudyAction.good: 2.5,
      // q = 5: 2.5 + 0.1
      StudyAction.easy: 2.6,
    };

    expected.forEach((action, factor) {
      test('${action.dbValue} moves 2.5 to $factor', () {
        expect(
          answer(action: action).schedule.easeFactor,
          closeTo(factor, 0.0001),
        );
      });
    });

    test('it updates on a failing turn too, not only a passing one', () {
      // BR-19 says every `scheduled` turn. Skipping the failures is the natural
      // shortcut and it makes a card that is always forgotten keep its starting
      // ease forever.
      expect(
        answer(action: StudyAction.again).schedule.easeFactor,
        lessThan(kInitialEaseFactor),
      );
    });

    test('fifty consecutive failures never breach the floor', () {
      // Without the floor the factor walks towards zero and the interval sticks
      // at one day for good — the card then arrives every single session and no
      // amount of later success digs it out.
      var schedule = const StudyScheduleModel(
        easeFactor: kInitialEaseFactor,
        intervalDays: kFirstIntervalDays,
        repetitions: 0,
      );

      for (var turn = 0; turn < 50; turn++) {
        schedule = scheduler
            .next(schedule: schedule, action: StudyAction.again)
            .schedule;

        expect(schedule.easeFactor, greaterThanOrEqualTo(kMinEaseFactor));
      }

      expect(schedule.easeFactor, kMinEaseFactor);
    });

    test('a card at the floor still lengthens when it is remembered', () {
      // The floor holds the factor down; it must not hold the interval down.
      final result = answer(
        action: StudyAction.good,
        repetitions: 3,
        intervalDays: 10,
        easeFactor: kMinEaseFactor,
      );

      expect(result.intervalDays, 13);
    });
  });

  group('edges', () {
    test('a card with nothing recorded is treated as a fresh one', () {
      final result = scheduler.next(
        schedule: const StudyScheduleModel(),
        action: StudyAction.good,
      );

      expect(result.intervalDays, 1);
      expect(result.schedule.repetitions, 1);
    });

    test('an eight_box action is refused rather than scored', () {
      expect(
        () => answer(action: StudyAction.remembered),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a finished card starts at one day (BR-144)', () {
      final initial = scheduler.initial();

      expect(initial.intervalDays, 1);
      expect(initial.schedule.repetitions, 0);
      expect(initial.schedule.easeFactor, kInitialEaseFactor);
      // No box: that column belongs to the other algorithm.
      expect(initial.schedule.box, isNull);
    });

    test('the resolver returns this scheduler', () {
      expect(schedulerFor(SchedulerType.sm2), isA<Sm2Scheduler>());
    });
  });
}
