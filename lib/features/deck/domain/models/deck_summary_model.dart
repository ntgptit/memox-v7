import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';
import 'deck_schedule_status_model.dart';
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

    /// Of those, how many have not finished the learning chain (BR-90).
    ///
    /// `learned_at IS NULL` — the same predicate a `learning` session selects
    /// with (BR-142), so the number on the row and the session it opens count
    /// the same set. Disjoint from [dueCardCount] by construction: one side of
    /// `learned_at`, never both.
    required int newCardCount,

    /// Of those, how many were due at the `now` used for the read (BR-22):
    /// `learned_at IS NOT NULL AND due_at <= now`, the `reviewing` set.
    required int dueCardCount,

    /// Of the due cards, how many came due **before today began** (BR-162):
    /// `due_at < startOfToday`, the local-day boundary of BR-105.
    ///
    /// A partition of [dueCardCount], never a second set: the query counts it
    /// inside the same grouped pass, so `dueCardCount == overdueCardCount +
    /// dueTodayCardCount` holds by construction and crossing local midnight
    /// moves cards between the halves with no write anywhere.
    required int overdueCardCount,

    /// Completed local-day boundaries between the subtree's **oldest** due
    /// card and today (BR-161). Zero when nothing is due, and zero when the
    /// oldest due card came due today.
    ///
    /// **Normalised by the mapper, not carried as an instant.** The read layer
    /// owns `now` and the UTC offset, so it is the one place the calendar
    /// arithmetic can run once and be tested once; a widget handed a raw
    /// `oldestDueAt` would have to read a clock, which `lib/features/` may
    /// not do (AD-16).
    required int overdueDayCount,

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

    /// How many decks sit **directly** inside this one.
    ///
    /// Direct children, not the subtree, because the row says "3 sub-decks" and
    /// a reader counts what they will see after tapping it. The card counts
    /// above are the opposite — those are the whole subtree, because a card
    /// buried three levels down is still a card this deck is responsible for.
    required int subDeckCount,

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

  /// Whether any card is still on the learning chain (BR-90).
  bool get hasNewCards => newCardCount > 0;

  /// The other half of the due partition (BR-162): due cards whose `due_at`
  /// still belongs to today's local calendar day.
  ///
  /// Derived, not stored — the query carries the total and the overdue half,
  /// and the third number is arithmetic, so the three can never disagree.
  int get dueTodayCardCount => dueCardCount - overdueCardCount;

  /// Cards resting until a future review (BR-162): learned, and not due yet
  /// (`learned_at IS NOT NULL AND due_at > now`).
  ///
  /// The fourth disjoint set, closing the partition: every card is New, due
  /// (overdue or today), or scheduled ahead — so this is `total − New − Due`,
  /// arithmetic over counts that already ride one statement. The "nothing to
  /// do here" set: the hero states it so the other three have a denominator,
  /// and it never carries the headline.
  int get scheduledCardCount => totalCardCount - newCardCount - dueCardCount;

  /// Whether any learned card has come due (BR-142's `reviewing` set).
  ///
  /// A predicate rather than letting each widget compare against zero: BR-29 says
  /// "nothing due" is a normal state and not an error, and a screen that
  /// re-derives the comparison in three places is a screen where one of them
  /// eventually renders it as a warning.
  bool get hasDueCards => dueCardCount > 0;

  /// Where this deck stands against today's local calendar (BR-161).
  ///
  /// Delegates to [deckScheduleStatusOf] — the one statement of the
  /// classification — so this deck and the level summary folded over many
  /// decks cannot disagree about where the boundaries sit.
  DeckScheduleStatus get scheduleStatus => deckScheduleStatusOf(
    dueCardCount: dueCardCount,
    overdueDayCount: overdueDayCount,
  );

  /// Whether a study session has anything at all to serve (BR-150).
  ///
  /// **The two sets are named separately because they cost differently** — a
  /// new card is a learning chain, a due card is one review — and this exists
  /// so nothing collapses them by accident: the Study button asks this, the
  /// badge shows both, and `hasDueCards` alone was hiding the button on a deck
  /// of twenty unlearned cards.
  bool get hasStudyableCards => hasNewCards || hasDueCards;
}
