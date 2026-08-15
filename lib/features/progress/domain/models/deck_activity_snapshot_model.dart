import 'package:freezed_annotation/freezed_annotation.dart';

import 'deck_activity_metrics_model.dart';
import 'deck_activity_model.dart';
import 'progress_path_segment_model.dart';
import 'progress_range_model.dart';

part 'deck_activity_snapshot_model.freezed.dart';

/// One level of Progress by Deck: what the scope amounts to, and what each deck
/// inside it contributed.
///
/// **Every field comes from one statement** (AD-13). The total and the rows have
/// to agree, and two reads would let the panel print a figure measured before a
/// review that the list below it already shows — the classic "the summary says
/// 12, the rows add to 13" that no amount of UI care can fix afterwards.
///
/// **The totals are read, not summed from [decks].** Active cards and card-days
/// would sum correctly, because sibling subtrees are disjoint; active *days*
/// would not, because the same Tuesday can be active in two decks and is still
/// one day of study (BR-193). Reading all four the same way keeps the rule in one
/// place instead of half in SQL and half in a fold nobody re-checks.
@freezed
abstract class DeckActivitySnapshot with _$DeckActivitySnapshot {
  const factory DeckActivitySnapshot({
    /// The deck being looked inside, or null at the top of the tree.
    ///
    /// Null is not "missing" — it is every deck there is. A deck that was asked
    /// for and does not exist surfaces as a `NotFoundFailure` on the stream
    /// instead, because a dead link and the home level must not render alike.
    required String? scopeDeckId,

    /// The scope's own name, null at the top level for the same reason.
    required String? scopeName,

    /// The path down to, but not including, the scope — root first. Empty at the
    /// top level and empty again one level in, because a root has no ancestors.
    required List<ProgressPathSegment> scopePath,

    /// The direct children of the scope — every root deck at the top level —
    /// each carrying its whole subtree's figures.
    required List<DeckActivity> decks,

    required DeckActivityMetrics scopeLast7Days,
    required DeckActivityMetrics scopeLast30Days,

    /// The next local midnight: the instant every window shifts by one day with
    /// no write behind it (BR-194).
    ///
    /// A read taken at 23:59 is wrong one minute later — yesterday's answers
    /// leave the 7-day window and today becomes a day with nothing in it yet —
    /// and no row changes in the database to say so. Carried from the same
    /// snapshot as the figures, so the numbers and the instant they expire
    /// describe one moment.
    required DateTime nextDayBoundaryAt,
  }) = _DeckActivitySnapshot;

  const DeckActivitySnapshot._();

  /// Whether this level is the top of the tree.
  bool get isTopLevel => scopeDeckId == null;

  /// The scope's figures for [range] — the same mapping [DeckActivity] uses, so
  /// the panel and the rows below it can never answer to different windows.
  DeckActivityMetrics scopeMetricsFor(ProgressRange range) => switch (range) {
    ProgressRange.last7Days => scopeLast7Days,
    ProgressRange.last30Days => scopeLast30Days,
  };

  /// Whether anything at all happened in the scope during [range].
  ///
  /// Distinguishes the all-zero state from the no-decks state: a level can hold
  /// six decks and still have nothing to report, and the two need different
  /// words on screen (UC-13).
  bool hasActivityIn(ProgressRange range) => scopeMetricsFor(range).hasActivity;
}
