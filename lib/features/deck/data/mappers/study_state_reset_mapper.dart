import '../../domain/models/scheduler_type_model.dart';

/// The study state a card is born with, per scheduler (BR-09 initialisation
/// table).
///
/// **The same numbers Card writes when it creates a card**, and that is the
/// whole point of BR-42: after a reset a card sits in the state it was in
/// before it was ever studied, not in a third state that only exists after a
/// reset. `card_study_state_seed_mapper.dart` writes them at creation; this
/// writes them at reset, and the two must not drift.
const int kEightBoxInitialBox = 1;
const double kSm2InitialEaseFactor = 2.5;
const int kSm2InitialIntervalDays = 0;
const int kSm2InitialRepetitions = 0;

/// The per-scheduler columns of a freshly initialised study state.
///
/// A mapper rather than four arguments at the call site: which columns a
/// scheduler owns is a rule, and a caller assembling them by hand is a caller
/// that can pass `eight_box` with an ease factor.
({int? box, double? ease, int? interval, int? repetitions})
initialStudyColumnsFor(SchedulerType type) => switch (type) {
  SchedulerType.eightBox => (
    box: kEightBoxInitialBox,
    ease: null,
    interval: null,
    repetitions: null,
  ),
  SchedulerType.sm2 => (
    box: null,
    ease: kSm2InitialEaseFactor,
    interval: kSm2InitialIntervalDays,
    repetitions: kSm2InitialRepetitions,
  ),
  // Unreachable: every caller refuses an unknown scheduler before any write.
  SchedulerType.unknown => (
    box: null,
    ease: null,
    interval: null,
    repetitions: null,
  ),
};
