import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_schedule_model.dart';
import 'package:memox/features/study/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/study/domain/models/study_scheduler.dart';

/// BR-15 and BR-16, box by box.
///
/// **The whole 8 × 2 matrix, not a sample.** A ladder with a table beside it
/// fails at exactly one rung or not at all, and a test that checks box 2 and box
/// 6 passes an off-by-one at box 4 and at box 8 — which are the two places the
/// arithmetic can actually be wrong.
void main() {
  const scheduler = EightBoxScheduler();

  StudyScheduleUpdateModel answer(int box, StudyAction action) =>
      scheduler.next(
        schedule: StudyScheduleModel(box: box),
        action: action,
      );

  group('what the algorithm declares', () {
    test('two actions, five stages, four review modes', () {
      expect(scheduler.type, SchedulerType.eightBox);
      expect(scheduler.supportedActions, <StudyAction>[
        StudyAction.forgotten,
        StudyAction.remembered,
      ]);
      expect(scheduler.stageSequence, <StudyMode>[
        StudyMode.browse,
        StudyMode.match,
        StudyMode.guess,
        StudyMode.recall,
        StudyMode.fill,
      ]);
      expect(scheduler.reviewModes, <StudyMode>[
        StudyMode.match,
        StudyMode.guess,
        StudyMode.recall,
        StudyMode.fill,
      ]);
    });

    test('browse is a stage but never a review mode (BR-146)', () {
      // Reviewing in `browse` would record nothing and move no schedule, so
      // offering it would be offering a session that cannot end.
      expect(scheduler.stageSequence, contains(StudyMode.browse));
      expect(scheduler.reviewModes, isNot(contains(StudyMode.browse)));
    });

    test('review modes are exactly the graded stages', () {
      expect(
        scheduler.reviewModes,
        scheduler.stageSequence.where((mode) => mode.producesAnswer).toList(),
      );
    });
  });

  group('BR-15 · box transitions, every rung', () {
    for (var box = 1; box <= 8; box++) {
      test('box $box forgotten falls to 1', () {
        expect(answer(box, StudyAction.forgotten).schedule.box, 1);
      });

      test('box $box remembered moves up, and 8 stays 8', () {
        expect(
          answer(box, StudyAction.remembered).schedule.box,
          box >= 8 ? 8 : box + 1,
        );
      });
    }

    test('box 8 remembered is not graduation — it comes back at 128 days', () {
      // The case a "mastered" flag would get wrong. Nothing leaves the deck,
      // because memory keeps fading (BR-16, BR-88).
      final result = answer(8, StudyAction.remembered);

      expect(result.schedule.box, 8);
      expect(result.intervalDays, 128);
    });
  });

  group('BR-16 · the interval of the box a card lands in', () {
    const expected = <int, int>{
      1: 1,
      2: 2,
      3: 4,
      4: 8,
      5: 16,
      6: 32,
      7: 64,
      8: 128,
    };

    expected.forEach((box, days) {
      test('landing in box $box waits $days days', () {
        // Driven from below, so the interval is read off the *target* box
        // rather than the one the card came from — the direction the bug goes.
        final from = box == 1 ? 1 : box - 1;
        final action = box == 1
            ? StudyAction.forgotten
            : StudyAction.remembered;

        expect(answer(from, action).intervalDays, days);
      });
    });

    test('a forgotten card always waits one day, from any box', () {
      for (var box = 1; box <= 8; box++) {
        expect(answer(box, StudyAction.forgotten).intervalDays, 1);
      }
    });
  });

  group('edges', () {
    test('a card with no box is treated as box 1', () {
      // One broken row must not take down a session, and box 1 is where a card
      // starts anyway (BR-144).
      final result = scheduler.next(
        schedule: const StudyScheduleModel(),
        action: StudyAction.remembered,
      );

      expect(result.schedule.box, 2);
    });

    test('an sm2 action is refused rather than scored', () {
      // Unreachable through the UI, which renders buttons from
      // `supportedActions` — but reachable from a deck that changed algorithm
      // before the lock, and scoring it quietly would be worse than stopping.
      expect(() => answer(3, StudyAction.good), throwsA(isA<ArgumentError>()));
    });

    test('a wrong grade maps to forgotten, a right one to remembered', () {
      // BR-107, and the reason it lives on the scheduler: the graded modes
      // produce a boolean, and only the algorithm knows what a boolean means.
      expect(scheduler.binaryAction(isCorrect: false), StudyAction.forgotten);
      expect(scheduler.binaryAction(isCorrect: true), StudyAction.remembered);
    });

    test('a finished card starts at box 1, due in a day (BR-144)', () {
      final initial = scheduler.initial();

      expect(initial.schedule.box, 1);
      expect(initial.intervalDays, 1);
    });
  });

  test('the resolver returns this scheduler, and none for unknown', () {
    expect(schedulerFor(SchedulerType.eightBox), isA<EightBoxScheduler>());
    // A card whose algorithm this build does not know cannot be studied; the
    // enum tolerates the value so a list still renders, and this refuses it so
    // nothing gets scheduled by guesswork.
    expect(schedulerFor(SchedulerType.unknown), isNull);
  });
}
