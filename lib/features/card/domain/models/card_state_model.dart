import '../../../deck/domain/models/scheduler_type_model.dart';
import '../entities/card_review_state_entity.dart';

/// How far along a card is, as a screen shows it (BR-89).
///
/// **Derived on read, never stored** (BR-89). A status column would be a second
/// copy of what `current_box` and `interval_days` already say, and two copies
/// disagree the first time someone updates one of them. It also turns a change
/// of threshold into a migration instead of a line of code.
///
/// **These are display labels, not a state machine.** No transition between them
/// is defined and nothing persists them; a card sliding from [reviewing] back to
/// [beginning] after a lapse is ordinary, not a violation.
enum CardState {
  /// No `scheduled` review yet (BR-90).
  isNew,

  /// Reviewed, and still on an interval under 8 days (BR-91).
  beginning,

  /// Reviewed, interval 8 days or more, and not yet mastered (BR-91).
  reviewing,

  /// Box 8, or an SM-2 interval of 128 days or more (BR-88).
  mastered,
}

/// The interval, in days, at which a card stops being [CardState.beginning]
/// and becomes [CardState.reviewing] (BR-91).
///
/// **Not a new number.** It is box 4 in BR-16's ladder — 1, 2, 4, **8**, 16, 32,
/// 64, 128 — so boxes 1–3 are the whole sub-week range and box 4 is the first
/// rung out of it. Reusing it for `sm2` is what makes `beginning` mean the same
/// distance in time on both schedulers, which is the argument BR-88 already used
/// when it chose 128 over Anki's 21.
const int kReviewingIntervalDays = 8;

/// The SM-2 interval at which a card counts as mastered (BR-88).
///
/// Matches box 8's interval, so "mastered" is the same distance in time on both
/// schedulers rather than two unrelated thresholds that happen to share a name.
const int kMasteredIntervalDays = 128;

/// The eight-box box at which a card counts as mastered (BR-88, BR-16).
const int kMasteredBox = 8;

/// Projects [state] onto the four display states.
///
/// **Two functions behind one entry point, and the split is AD-06's.** The two
/// schedulers hold different columns — `eight_box` counts boxes, `sm2` counts
/// days — so a single expression would have to read the other one's NULLs. The
/// dispatch is here; the arithmetic is in the two private functions, each
/// reading only the columns its own scheduler owns.
///
/// [SchedulerType.unknown] is a value written by a newer build. It resolves to
/// [CardState.isNew] rather than throwing, for the same reason the enum tolerates
/// it at all: one unrecognised row must not take down every screen that lists
/// cards.
CardState cardStateOf(CardReviewStateEntity state) {
  // BR-90, and it is checked before either scheduler: a card with no scheduled
  // review is `new` regardless of what its columns hold. `eight_box` seeds
  // `current_box = 1` at creation (BR-09), so reading the box first would call
  // every untouched card `beginning`.
  if (state.reviewCount == 0) return CardState.isNew;

  return switch (state.schedulerType) {
    SchedulerType.eightBox => _eightBoxState(state.currentBox),
    SchedulerType.sm2 => _sm2State(state.intervalDays),
    SchedulerType.unknown => CardState.isNew,
  };
}

/// Box 1–3 → beginning · 4–7 → reviewing · 8 → mastered (BR-91, BR-88).
///
/// A NULL box on an `eight_box` card is data that should not exist — the column
/// is seeded at creation — so it reads as [CardState.isNew] rather than being
/// guessed at. That is the same choice [SchedulerType.unknown] gets: a broken
/// row renders as the least-committed value instead of throwing.
CardState _eightBoxState(int? box) {
  if (box == null) return CardState.isNew;
  if (box >= kMasteredBox) return CardState.mastered;
  if (box >= kReviewingBox) return CardState.reviewing;

  return CardState.beginning;
}

/// Box 4 — the first rung whose interval reaches [kReviewingIntervalDays].
const int kReviewingBox = 4;

/// interval < 8 → beginning · 8–127 → reviewing · ≥ 128 → mastered.
CardState _sm2State(int? intervalDays) {
  if (intervalDays == null) return CardState.isNew;
  if (intervalDays >= kMasteredIntervalDays) return CardState.mastered;
  if (intervalDays >= kReviewingIntervalDays) return CardState.reviewing;

  return CardState.beginning;
}
