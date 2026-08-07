import '../../../deck/domain/models/scheduler_type_model.dart';
import 'study_action_model.dart';
import 'study_mode.dart';
import 'study_schedule_model.dart';
import 'study_scheduler.dart';

/// Days a card waits in each box (BR-16). Index 0 is box 1.
///
/// A constant in Dart rather than a table in SQL: putting it in the database
/// would make tuning the algorithm a migration, and the interval is the thing
/// most likely to be tuned.
const List<int> kEightBoxIntervalDays = <int>[1, 2, 4, 8, 16, 32, 64, 128];

/// The lowest and highest box (BR-15, BR-16).
const int kMinBox = 1;
const int kMaxBox = 8;

/// Leitner in eight boxes: forget and fall to the bottom, remember and move up
/// one.
///
/// **Box 8 is the last box, not graduation.** A card answered `remembered` there
/// stays at 8 and comes back in 128 days. There is no state that makes a card
/// disappear, because memory keeps fading — "mastered" is a value derived for
/// display (BR-88), never a column.
final class EightBoxScheduler implements StudyScheduler {
  const EightBoxScheduler();

  @override
  SchedulerType get type => SchedulerType.eightBox;

  @override
  List<StudyAction> get supportedActions => const <StudyAction>[
    StudyAction.forgotten,
    StudyAction.remembered,
  ];

  @override
  List<StudyMode> get stageSequence => const <StudyMode>[
    StudyMode.browse,
    StudyMode.match,
    StudyMode.guess,
    StudyMode.recall,
    StudyMode.fill,
  ];

  @override
  List<StudyMode> get reviewModes => const <StudyMode>[
    StudyMode.match,
    StudyMode.guess,
    StudyMode.recall,
    StudyMode.fill,
  ];

  @override
  StudyAction? binaryAction({required bool isCorrect}) =>
      isCorrect ? StudyAction.remembered : StudyAction.forgotten;

  @override
  StudyScheduleUpdateModel initial() => const StudyScheduleUpdateModel(
    intervalDays: 1,
    schedule: StudyScheduleModel(box: kMinBox),
  );

  @override
  StudyScheduleUpdateModel next({
    required StudyScheduleModel schedule,
    required StudyAction action,
  }) {
    // A card with no box is one this algorithm has never scheduled. Treating it
    // as box 1 rather than throwing keeps a single broken row from taking down a
    // session, and box 1 is where a card starts anyway (BR-144).
    final current = schedule.box ?? kMinBox;

    final target = switch (action) {
      StudyAction.forgotten => kMinBox,
      StudyAction.remembered => current >= kMaxBox ? kMaxBox : current + 1,

      // The `sm2` actions. Unreachable through the UI, which renders buttons
      // from `supportedActions` — but reachable from a history row written by a
      // deck that changed algorithm before the lock, so it fails loudly rather
      // than quietly scheduling something.
      StudyAction.again ||
      StudyAction.hard ||
      StudyAction.good ||
      StudyAction.easy => throw ArgumentError.value(
        action,
        'action',
        'eight_box understands only forgotten and remembered (BR-30)',
      ),
    };

    return StudyScheduleUpdateModel(
      intervalDays: kEightBoxIntervalDays[target - 1],
      schedule: StudyScheduleModel(box: target),
    );
  }
}
