import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../../../shared/widgets/mx_progress_bar.dart';
import '../../domain/models/deck_list_snapshot_model.dart';

/// What this level amounts to, above the list of what is in it.
///
/// At the root it answers "what is waiting today"; inside a deck it answers the
/// same question about that deck. They are the same question at different
/// scopes, so they are one block rather than a home screen and a header.
///
/// **Every number here is arithmetic over the snapshot the screen already has.**
/// A child's counts are its whole subtree, and sibling subtrees are disjoint, so
/// summing the children is the level's total — no second read, and therefore no
/// chance of the panel and the list disagreeing about the same instant (AD-13).
/// A deck holds one kind of thing (BR-63), so a level whose children are decks
/// has no cards of its own to leave out of the sum.
///
/// **Two things the design puts here are deliberately absent.** Its streak chip
/// needs `review_history`, which nothing writes until the review slice lands in
/// M5 — a streak that is always zero is worse than no streak. Its "Start
/// studying" button needs a session to start, from the same milestone. Both
/// would be controls that look live and are not.
class DeckLevelSummaryWidget extends StatelessWidget {
  const DeckLevelSummaryWidget({
    required this.snapshot,
    required this.onDismiss,
    super.key,
  });

  final DeckListSnapshot snapshot;

  /// Hides the panel. **Dismissible on purpose**: it is the most useful thing on
  /// the screen on the day you opened the app to study, and the thing in the way
  /// of the list on the day you opened it to reorganise your decks. Getting it
  /// back is one tap, so nothing is lost by hiding it.
  final VoidCallback onDismiss;

  /// Whether this level has anything to summarise.
  ///
  /// Exposed so the screen can leave the panel out entirely rather than render
  /// an empty one: a level with no decks has an empty state that already says
  /// more than "0 cards due" would.
  static bool hasContent(DeckListSnapshot snapshot) =>
      snapshot.decks.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final decks = snapshot.decks;
    final dueCount = decks.fold<int>(0, (sum, d) => sum + d.dueCardCount);
    final cardCount = decks.fold<int>(0, (sum, d) => sum + d.totalCardCount);
    final learnedCount = decks.fold<int>(
      0,
      (sum, d) => sum + d.learnedCardCount,
    );
    final isRoot = snapshot.parent == null;
    final isCaughtUp = dueCount == 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semanticColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _SummaryHeadline(
                    dueCount: dueCount,
                    isRoot: isRoot,
                    isCaughtUp: isCaughtUp,
                  ),
                ),
                // Top-aligned against the figure rather than centred on the
                // block: the panel grows a progress bar under it, and a close
                // button that drifted downwards as it did would stop reading as
                // belonging to the panel's own corner.
                MxIconButton(
                  icon: Icons.close,
                  semanticLabel: context.l10n.deckSummaryHideLabel,
                  onPressed: onDismiss,
                ),
              ],
            ),
            if (cardCount > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              MxProgressBar(
                size: MxProgressBarSize.sm,
                value: cardCount == 0 ? 0 : learnedCount / cardCount,
                label: context.l10n.deckLearnedProgressLabel(
                  learnedCount,
                  cardCount,
                ),
                valueLabel: context.l10n.deckLearnedPercentLabel(
                  (learnedCount / cardCount * 100).round(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The figure and the sentence that continues it.
class _SummaryHeadline extends StatelessWidget {
  const _SummaryHeadline({
    required this.dueCount,
    required this.isRoot,
    required this.isCaughtUp,
  });

  final int dueCount;
  final bool isRoot;
  final bool isCaughtUp;

  @override
  Widget build(BuildContext context) {
    // **The word, not a zero.** A `0` set in the display face is the largest
    // thing on the screen saying nothing happened; BR-29 makes "nothing due" a
    // normal state, and it should not be rendered as the day's headline failure.
    final figure = isCaughtUp
        ? context.l10n.deckSummaryCaughtUpFigure
        : '$dueCount';
    final sentence = isCaughtUp
        ? context.l10n.deckSummaryCaughtUp
        : isRoot
        ? context.l10n.deckSummaryDueAcrossLibrary(dueCount)
        : context.l10n.deckSummaryDueInDeck(dueCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          figure,
          style: context.texts.headlineMedium?.copyWith(
            // Green only when it is good news. Left in the default ink the word
            // "All" reads as a label; in `success` it reads as a result.
            color: isCaughtUp ? context.semanticColors.success : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          sentence,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
