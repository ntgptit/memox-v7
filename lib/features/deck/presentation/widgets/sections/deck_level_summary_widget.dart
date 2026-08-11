import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../../../shared/widgets/mx_progress_bar.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_summary_model.dart';
import '../../states/deck_list_view_state.dart';

/// What this level amounts to, above the list of what is in it.
///
/// At the root it answers "what is waiting today"; inside a deck it answers the
/// same question about that deck. They are the same question at different
/// scopes, so they are one block rather than a home screen and a header.
///
/// **Support, not hero.** The list is the screen's content and this panel is a
/// figure and a bar above it — one line of headline, one line of context, one
/// track. It was taller, and the cost was measured in decks: every extra line
/// here is a row of the list pushed under the fold.
///
/// **Every number here is arithmetic over the snapshot the screen already has.**
/// A child's counts are its whole subtree, and sibling subtrees are disjoint, so
/// summing the children is the level's total — no second read, and therefore no
/// chance of the panel and the list disagreeing about the same instant (AD-13).
/// A deck holds one kind of thing (BR-63), so a level whose children are decks
/// has no cards of its own to leave out of the sum.
///
/// **"Caught up" requires both sets empty** (BR-150, BR-142). The headline used
/// to follow the due count alone, so a library of twenty unlearned cards was
/// greeted with "All caught up" — true of reviews, false of the day: the new
/// set is work too, it merely does not expire.
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

  /// Whether anything on this level is waiting to be studied — new **or** due
  /// (BR-150).
  ///
  /// What [DeckSummaryVisibility.auto] follows. Exposed here rather than computed
  /// by the caller so that the number deciding whether the panel appears and the
  /// number the panel prints are the same fold over the same snapshot — a panel
  /// that appeared because of one count and then displayed another would be worse
  /// than one that never appeared.
  ///
  /// `any` rather than summing: the question is whether the sum is non-zero, and
  /// a card count cannot be negative, so the first studyable deck answers it.
  static bool hasStudyable(DeckListSnapshot snapshot) =>
      snapshot.decks.any((DeckSummary summary) => summary.hasStudyableCards);

  @override
  Widget build(BuildContext context) {
    final decks = snapshot.decks;
    final newCount = decks.fold<int>(0, (sum, d) => sum + d.newCardCount);
    final dueCount = decks.fold<int>(0, (sum, d) => sum + d.dueCardCount);
    final cardCount = decks.fold<int>(0, (sum, d) => sum + d.totalCardCount);
    final learnedCount = decks.fold<int>(
      0,
      (sum, d) => sum + d.learnedCardCount,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semanticColors.borderSubtle),
      ),
      child: Padding(
        // `md`, one step down from the card gutter: a support panel that pads
        // itself like a hero reads as one.
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // **Metrics, not a sentence.** The panel used to open with
                // "12 cards due in this deck today, and 14 new to learn" --
                // prose that wraps at large scales and buries the two numbers
                // a reader is actually scanning for. The numbers now lead, in
                // the same Due-then-New order and the same roles as every
                // tile, so the eye learns one grammar for the whole screen.
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      _SummaryMetric.due(count: dueCount),
                      _SummaryMetric.fresh(count: newCount),
                    ],
                  ),
                ),
                // Top-aligned against the figures rather than centred on the
                // block: the panel grows a progress bar under it, and a close
                // button that drifted downwards as it did would stop reading
                // as belonging to the panel's own corner.
                MxIconButton(
                  icon: Icons.close,
                  semanticLabel: context.l10n.deckSummaryHideLabel,
                  onPressed: onDismiss,
                ),
              ],
            ),
            if (cardCount > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              // The learned line and the bar come as one component, and use
              // the same progress tokens as every tile: track, fill, and
              // success only at 100%.
              MxProgressBar(
                size: MxProgressBarSize.sm,
                value: learnedCount / cardCount,
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

/// One number and its word: `12 Due` / `14 New`.
///
/// The numeral is `onSurface` at title weight -- it is the datum -- and the
/// word is the quiet label beside it. Due keeps the tile's
/// clock-on-streakContainer mark when it is non-zero; New keeps the tile's
/// `info` ink. Zeroes stay on screen in the neutral variant: the absence
/// convention is exactly what the metric-first panel exists to kill (BR-150).
class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric.due({required this.count}) : isDue = true;

  const _SummaryMetric.fresh({required this.count}) : isDue = false;

  final int count;
  final bool isDue;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final word = isDue
        ? context.l10n.deckDueMetricWord
        : context.l10n.deckNewMetricWord;
    final wordInk = count == 0
        ? context.colors.onSurfaceVariant
        : isDue
        ? semantic.onStreakContainer
        : semantic.info;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isDue && count > 0) ...<Widget>[
          // The tile's time-pressure mark, at metric scale: the clock on its
          // own small streakContainer well, so the panel and the rows speak
          // one language without turning the whole panel into a warning
          // surface.
          DecoratedBox(
            decoration: BoxDecoration(
              color: semantic.streakContainer,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Icon(
                Icons.schedule,
                size: AppIconSize.sm,
                color: semantic.onStreakContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '$count ',
                style: context.texts.titleLarge?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              TextSpan(
                text: word,
                style: context.texts.labelMedium?.copyWith(
                  color: wordInk,
                  fontWeight: count == 0 ? null : FontWeight.w600,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
