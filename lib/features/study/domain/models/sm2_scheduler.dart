import '../../../deck/domain/models/scheduler_type_model.dart';
import 'study_action_model.dart';
import 'study_mode.dart';
import 'study_schedule_model.dart';
import 'study_scheduler.dart';

/// The ease factor a card starts on, and the floor it may never go below
/// (BR-19).
///
/// **The floor is not a safety net, it is the rule.** Without it a card that
/// keeps being forgotten drives its ease factor towards zero, and its interval
/// sticks at one day for good — the card is then in the deck forever, arriving
/// every single session, and no amount of remembering it later digs it out.
const double kInitialEaseFactor = 2.5;
const double kMinEaseFactor = 1.3;

/// The interval, in days, of the first two successful repetitions (BR-18).
const int kFirstIntervalDays = 1;
const int kSecondIntervalDays = 6;

/// The quality below which an answer counts as a failure (BR-17, BR-18).
const int kFailingQuality = 3;

/// SM-2, with the four-action quality scale.
///
/// **It runs only two stages** (BR-110): `browse`, then `self_assess`. The four
/// graded modes belong to `eight_box`, which is why [reviewModes] here holds one
/// entry and [binaryAction] returns null — this algorithm never grades anything
/// itself, it asks (BR-106).
final class Sm2Scheduler implements StudyScheduler {
  const Sm2Scheduler();

  @override
  SchedulerType get type => SchedulerType.sm2;

  @override
  List<StudyAction> get supportedActions => const <StudyAction>[
    StudyAction.again,
    StudyAction.hard,
    StudyAction.good,
    StudyAction.easy,
  ];

  @override
  List<StudyMode> get stageSequence => const <StudyMode>[
    StudyMode.browse,
    StudyMode.selfAssess,
  ];

  @override
  List<StudyMode> get reviewModes => const <StudyMode>[StudyMode.selfAssess];

  @override
  StudyAction? binaryAction({required bool isCorrect}) => null;

  @override
  StudyScheduleUpdateModel initial() => const StudyScheduleUpdateModel(
    intervalDays: kFirstIntervalDays,
    schedule: StudyScheduleModel(
      easeFactor: kInitialEaseFactor,
      intervalDays: kFirstIntervalDays,
      repetitions: 0,
    ),
  );

  @override
  StudyScheduleUpdateModel next({
    required StudyScheduleModel schedule,
    required StudyAction action,
  }) {
    final quality = _qualityOf(action);
    final easeFactor = schedule.easeFactor ?? kInitialEaseFactor;
    final repetitions = schedule.repetitions ?? 0;
    final intervalDays = schedule.intervalDays ?? kFirstIntervalDays;

    // **The interval is computed from the ease factor the card arrived with,
    // and the ease factor is updated separately** (BR-18 then BR-19). The
    // documents state them as two rules, and BR-18's `ease_factor` is the
    // card's stored value — the one it had going into this turn. Folding the
    // new factor in first would make every interval a little longer than the
    // rule as written, and the drift compounds over a card's life.
    final (int nextInterval, int nextRepetitions) = quality < kFailingQuality
        ? (kFirstIntervalDays, 0)
        : switch (repetitions) {
            0 => (kFirstIntervalDays, 1),
            1 => (kSecondIntervalDays, 2),
            _ => ((intervalDays * easeFactor).round(), repetitions + 1),
          };

    return StudyScheduleUpdateModel(
      intervalDays: nextInterval,
      schedule: StudyScheduleModel(
        easeFactor: _nextEaseFactor(easeFactor, quality),
        intervalDays: nextInterval,
        repetitions: nextRepetitions,
      ),
    );
  }

  /// BR-17's quality scale.
  int _qualityOf(StudyAction action) => switch (action) {
    StudyAction.again => 0,
    StudyAction.hard => 3,
    StudyAction.good => 4,
    StudyAction.easy => 5,

    // The `eight_box` actions, refused for the reason its scheduler refuses
    // these: a history row from a deck that changed algorithm before the lock
    // can carry one, and quietly scoring it would be worse than stopping.
    StudyAction.forgotten ||
    StudyAction.remembered => throw ArgumentError.value(
      action,
      'action',
      'sm2 understands only again, hard, good and easy (BR-30)',
    ),
  };

  /// BR-19, applied on **every** `scheduled` turn, including the failing ones.
  double _nextEaseFactor(double current, int quality) {
    final delta = 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    final next = current + delta;

    return next < kMinEaseFactor ? kMinEaseFactor : next;
  }
}
