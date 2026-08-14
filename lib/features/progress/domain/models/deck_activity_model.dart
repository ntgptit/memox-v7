import 'package:freezed_annotation/freezed_annotation.dart';

import 'deck_activity_metrics_model.dart';
import 'progress_path_segment_model.dart';
import 'progress_range_model.dart';

part 'deck_activity_model.freezed.dart';

/// One deck's row on the Progress by Deck list: where it sits, and what it
/// amounts to in each of the two windows.
///
/// **Both windows ride on every row** (BR-184). They come from one statement, so
/// switching the range on screen is a field access rather than a re-read — which
/// is what makes it impossible for the 7-day figure and the 30-day figure to
/// describe two different snapshots of the tree.
///
/// The metrics cover the deck's **whole subtree** (BR-185): its own cards and
/// every descendant's. Sibling subtrees are disjoint, so the rows of one level
/// never double-count a card between them.
@freezed
abstract class DeckActivity with _$DeckActivity {
  const factory DeckActivity({
    required String deckId,
    required String name,

    /// The path from the root down to, but not including, this deck — root
    /// first. Empty for a root deck, which has no ancestors.
    required List<ProgressPathSegment> path,

    required DeckActivityMetrics last7Days,
    required DeckActivityMetrics last30Days,
  }) = _DeckActivity;

  const DeckActivity._();

  /// The figures for [range].
  ///
  /// A method rather than two fields read by name at the call site: the range is
  /// one user choice and every metric on screen has to answer to the same one,
  /// so there is exactly one place that maps the choice to a set of numbers.
  DeckActivityMetrics metricsFor(ProgressRange range) => switch (range) {
    ProgressRange.last7Days => last7Days,
    ProgressRange.last30Days => last30Days,
  };
}
