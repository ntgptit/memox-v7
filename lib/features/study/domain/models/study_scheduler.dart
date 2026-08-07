import '../../../deck/domain/models/scheduler_type_model.dart';
import 'study_action_model.dart';
import 'study_mode.dart';
import 'study_schedule_model.dart';
import 'eight_box_scheduler.dart';
import 'sm2_scheduler.dart';

/// An SRS algorithm: which stages it runs, which actions it understands, and
/// what one answer does to a card's schedule.
///
/// **The stage list belongs here, not to the deck and not to the screen**
/// (BR-97). `eight_box` walks five stages, `sm2` walks two; a UI holding its own
/// list is wrong for half the decks, and a deck holding one would let two decks
/// on the same algorithm disagree.
///
/// Pure Dart, and pure functions: no clock (AD-06), no repository, no randomness.
/// [next] returns a number of days rather than a moment, because the moment
/// needs a timezone and `domain/` may not have one (AD-16).
abstract interface class StudyScheduler {
  SchedulerType get type;

  /// The actions this algorithm understands (BR-30).
  ///
  /// The two sets are disjoint, which is why a screen must render its buttons
  /// from here instead of from a list of its own.
  List<StudyAction> get supportedActions;

  /// The stages a **learning** session walks, in order (BR-110).
  List<StudyMode> get stageSequence;

  /// The modes a **review** session may be run in (BR-146).
  ///
  /// The graded stages of [stageSequence], minus `browse`: browsing produces no
  /// action, so reviewing in it would record nothing and move no schedule
  /// (BR-111).
  List<StudyMode> get reviewModes;

  /// Maps a graded stage's right/wrong outcome to an action (BR-107).
  ///
  /// **Null when the algorithm has no graded stage at all.** `sm2` runs only
  /// `self_assess`, which takes its action straight from the user (BR-106), so
  /// there is nothing to map — and inventing a mapping for it would be inventing
  /// business nobody decided. A caller that reaches null has asked the wrong
  /// algorithm for a grade, and the type is what makes that visible instead of
  /// silently writing the wrong answer.
  StudyAction? binaryAction({required bool isCorrect});

  /// The schedule a card starts on once it finishes the learning chain (BR-144).
  StudyScheduleUpdateModel initial();

  /// Applies one `scheduled` answer.
  ///
  /// Only a `scheduled` turn ever reaches here: `learning` and `relearning`
  /// turns move no schedule (BR-78, BR-141), so calling this for them would be
  /// asking a question that has no answer.
  StudyScheduleUpdateModel next({
    required StudyScheduleModel schedule,
    required StudyAction action,
  });
}

/// The one place an algorithm is resolved from its stored value.
///
/// Exhaustive over the enum, so a third algorithm is a compile error at every
/// site that has not handled it — which is the check a runtime registry cannot
/// make (AD-18, applied to schedulers rather than modes).
///
/// [SchedulerType.unknown] has no scheduler by construction: it exists so a row
/// written by a newer build can be *read* without crashing a list, and a card
/// whose algorithm this build does not know cannot be studied at all.
StudyScheduler? schedulerFor(SchedulerType type) => switch (type) {
  SchedulerType.eightBox => const EightBoxScheduler(),
  SchedulerType.sm2 => const Sm2Scheduler(),
  SchedulerType.unknown => null,
};
