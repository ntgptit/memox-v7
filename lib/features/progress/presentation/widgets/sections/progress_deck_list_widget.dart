import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/deck_activity_model.dart';
import '../../../domain/models/progress_range_model.dart';
import '../items/progress_deck_row_widget.dart';

/// The level's deck rows, as a sliver.
///
/// **A sliver rather than a `Column` of cards**, so the list is built lazily and
/// the summary panel above it scrolls with the rows rather than eating a fixed
/// slice of the screen — the arrangement the deck list had to be repaired into
/// once its chrome grew.
///
/// The rows arrive already ordered (BR-197); nothing here sorts, filters or
/// hides. A zero-activity deck renders exactly like a busy one, with zeroes in
/// it.
class ProgressDeckListWidget extends StatelessWidget {
  const ProgressDeckListWidget({
    required this.decks,
    required this.range,
    required this.gutter,
    required this.onOpenDeck,
    super.key,
  });

  /// The screen gutter, passed in rather than re-derived.
  ///
  /// The list and the panel above it have to share an edge, and two widgets each
  /// resolving the breakpoint rule for themselves is how they stop sharing it —
  /// silently, and only below 360 where nobody looks.
  final double gutter;

  final List<DeckActivity> decks;
  final ProgressRange range;
  final ValueChanged<DeckActivity> onOpenDeck;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      // The screen gutter, and a breathing space under the last row.
      //
      // **Not bottom-bar clearance** — `Scaffold` already subtracts the
      // navigation bar's height from the body's `MediaQuery`, so no row can hide
      // behind it and a test asserting that could never fail. What this buys is
      // that the last row does not end flush against the bar, which reads as a
      // list cut off mid-way.
      padding: EdgeInsets.only(
        left: gutter,
        right: gutter,
        bottom: AppSpacing.xxl,
      ),
      sliver: SliverList.separated(
        itemCount: decks.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final DeckActivity activity = decks[index];

          return ProgressDeckRowWidget(
            // Keyed by deck id so a re-sort after a review moves the widget
            // rather than rebuilding a different deck's numbers into it.
            key: ValueKey<String>(activity.deckId),
            activity: activity,
            range: range,
            onOpen: () => onOpenDeck(activity),
          );
        },
      ),
    );
  }
}
