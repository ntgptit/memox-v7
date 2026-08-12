import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';
import 'deck_path_segment_model.dart';
import 'deck_schedule_status_model.dart';
import 'deck_summary_model.dart';

part 'deck_list_snapshot_model.freezed.dart';

/// One level of the deck tree: where the user is, what is in it, and when the
/// numbers expire.
///
/// **One type for the root list and for the inside of a deck**, because they are
/// one screen. Opening a deck does not change what the user is looking at — it
/// changes which level of the same tree — and modelling the two separately is
/// what produced two screens that drifted apart. This replaced
/// `DeckListSnapshot` and `DeckDetail`, which between them described exactly
/// this and disagreed about how much of it to carry.
///
/// Every field comes from **one** statement (AD-13). The parent and its children
/// have to agree: the action set on screen is computed from the parent's
/// `content_type` and from whether the children are empty at the same time, so
/// two reads would let the screen render an action matrix from a deck captured
/// at one instant and a list captured at another.
@freezed
abstract class DeckListSnapshot with _$DeckListSnapshot {
  const factory DeckListSnapshot({
    /// The deck being looked *inside*, or null at the root of the tree.
    ///
    /// Null is not "missing" — it is the top level, which has no deck of its own.
    /// A deck that was asked for and does not exist surfaces as a
    /// `NotFoundFailure` on the stream instead, because a dead route and the home
    /// screen must not render the same way.
    required DeckEntity? parent,

    /// What is directly inside [parent] — or every root deck when it is null.
    required List<DeckSummary> decks,

    /// The path from the root down to, but not including, [parent] — root first.
    ///
    /// Empty at the root level, and empty again one level in: a root deck's own
    /// ancestry is nothing. The first non-empty case is level 3, which is also
    /// the first level where "where am I" stops being answerable from the title
    /// alone.
    ///
    /// From the same statement as everything else (AD-13). Read separately, a
    /// rename could land on the title and not on the breadcrumb, and the screen
    /// would show one deck under two names.
    required List<DeckPathSegment> ancestors,

    /// The earliest instant strictly after the read's `now` at which some card
    /// becomes due, or null when no card is scheduled to.
    ///
    /// Null is a real state with two causes — no cards at all, or every card
    /// already due — and both mean the same thing to the caller: there is nothing
    /// to wait for, so do not wait.
    required DateTime? nextDueAt,

    /// The next local midnight, when any deck on this level has due cards —
    /// or null when none does (BR-161).
    ///
    /// This is the badge's clock. `nextDueAt` goes null the moment every
    /// scheduled card is already due, which is exactly when the overdue count
    /// still has to move: a list left open across midnight must re-read at the
    /// boundary even though no card's state changed in the database. Computed
    /// from the same read as everything else, so the counts and the instant
    /// they expire describe one snapshot (AD-13).
    required DateTime? nextOverdueTickAt,
  }) = _DeckListSnapshot;

  const DeckListSnapshot._();

  /// Whether this level is the top of the tree.
  bool get isRootLevel => parent == null;

  /// Due cards across everything this level shows (BR-150).
  ///
  /// **Arithmetic over [decks], never a second read.** A child's counts cover
  /// its whole subtree and sibling subtrees are disjoint, so the sum *is* the
  /// level's total — and the panel printing it can never disagree with the
  /// rows below it about the same instant (AD-13).
  int get levelDueCardCount =>
      decks.fold(0, (int sum, DeckSummary d) => sum + d.dueCardCount);

  /// New cards across everything this level shows (BR-150). Same fold, same
  /// disjointness argument as [levelDueCardCount].
  int get levelNewCardCount =>
      decks.fold(0, (int sum, DeckSummary d) => sum + d.newCardCount);

  /// Due cards that came due before today began, across the level (BR-162).
  ///
  /// Same fold, same disjointness argument — and because each summary's
  /// partition sums to its total, `levelDueCardCount ==
  /// levelOverdueCardCount + levelDueTodayCardCount` holds for the level too.
  int get levelOverdueCardCount =>
      decks.fold(0, (int sum, DeckSummary d) => sum + d.overdueCardCount);

  /// Due cards still belonging to today's local day, across the level
  /// (BR-162). The hero's middle metric.
  int get levelDueTodayCardCount =>
      decks.fold(0, (int sum, DeckSummary d) => sum + d.dueTodayCardCount);

  /// Cards resting until a future review, across the level (BR-162): the
  /// fourth disjoint set, so the hero's four figures partition every card the
  /// level holds. Same fold, same disjointness argument.
  int get levelScheduledCardCount =>
      decks.fold(0, (int sum, DeckSummary d) => sum + d.scheduledCardCount);

  /// Completed local days behind the level's **oldest** due card (BR-161).
  ///
  /// The max over children that actually have due cards: the level is as late
  /// as its latest subtree, exactly as each child is as late as its own oldest
  /// card. Children whose `dueCardCount` is zero take no part — their
  /// `overdueDayCount` is zero by mapper invariant, but the guard states the
  /// rule rather than leaning on it. Zero when nothing on the level is due.
  int get levelOverdueDayCount => decks
      .where((DeckSummary d) => d.hasDueCards)
      .fold(0, (int days, DeckSummary d) => math.max(days, d.overdueDayCount));

  /// Where this level as a whole stands against today (BR-161) — the same
  /// classification a single deck gets, through the same function, so the
  /// summary panel and the tiles under it speak one grammar.
  DeckScheduleStatus get levelScheduleStatus => deckScheduleStatusOf(
    dueCardCount: levelDueCardCount,
    overdueDayCount: levelOverdueDayCount,
  );
}
