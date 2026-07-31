import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';
import 'scheduler_type_model.dart';

part 'deck_summary_model.freezed.dart';

/// One deck in a list, with the numbers shown beside it (UC-06).
///
/// A read model, not an entity. It exists because a row needs several facts at
/// once and the aggregate that produces them is a single query; putting the
/// counts on [DeckEntity] would put numbers that are only true at one instant
/// onto the type every write path also uses.
///
/// **The same type at every level.** It was `DeckSummary` while only the root
/// list had counts, and opening a deck then showed a plainer list — names with no
/// numbers — because the read underneath returned bare rows. That difference was
/// never a design decision; it was the shape of the data leaking into the UI. A
/// deck is a deck, so one summary type describes it wherever it appears.
@freezed
abstract class DeckSummary with _$DeckSummary {
  const factory DeckSummary({
    required DeckEntity deck,

    /// Cards anywhere in this deck's subtree, at any depth.
    required int totalCardCount,

    /// Of those, how many were due at the `now` used for the read (BR-22).
    required int dueCardCount,

    /// Of those, how many count as learned (BR-88).
    ///
    /// **Derived at read time, never stored.** `eight_box` counts a card at box
    /// 8; `sm2` counts one whose interval has reached 128 days — the same
    /// distance box 8 schedules, so "learned" means the same span of time under
    /// either scheduler rather than one convention under each.
    ///
    /// It arrives from the same statement as the other two counts, for the same
    /// AD-13 reason: a screen that shows "20 of 570 learned" beside "12 due"
    /// must not be able to render one of them from before a write and the other
    /// from after it.
    required int learnedCardCount,

    /// The scheduler this deck is reviewed with — **resolved**, not raw.
    ///
    /// A sub-deck's own scheduler columns are NULL by rule (BR-06); the review it
    /// takes part in uses its root's. Reading `deck.schedulerType` would show
    /// nothing for every deck below the first level, so the resolved value is a
    /// field of its own and the raw column stays where it belongs.
    required SchedulerType schedulerType,
  }) = _DeckSummary;

  const DeckSummary._();

  /// How much of this deck is learned, as a fraction from 0 to 1.
  ///
  /// Zero for an empty deck rather than a division by zero — a deck with no
  /// cards is 0% learned, which is both true and what a progress bar needs.
  double get learnedFraction =>
      totalCardCount == 0 ? 0 : learnedCardCount / totalCardCount;

  /// Whether every card in this deck is learned, and there is at least one.
  ///
  /// A predicate rather than letting each widget compare two integers: the empty
  /// case reads as "complete" to `>=` and is the opposite of it.
  bool get isFullyLearned =>
      totalCardCount > 0 && learnedCardCount == totalCardCount;

  /// Whether anything is waiting to be studied.
  ///
  /// A predicate rather than letting each widget compare against zero: BR-29 says
  /// "nothing due" is a normal state and not an error, and a screen that
  /// re-derives the comparison in three places is a screen where one of them
  /// eventually renders it as a warning.
  bool get hasDueCards => dueCardCount > 0;
}
