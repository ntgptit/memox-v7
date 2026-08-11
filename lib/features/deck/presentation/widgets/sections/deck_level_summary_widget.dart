import 'package:flutter/material.dart';

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
                Expanded(
                  child: _SummaryHeadline(
                    newCount: newCount,
                    dueCount: dueCount,
                    isRoot: snapshot.parent == null,
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
              const SizedBox(height: AppSpacing.sm),
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

/// The figure and the sentence that continues it — both sets, always.
class _SummaryHeadline extends StatelessWidget {
  const _SummaryHeadline({
    required this.newCount,
    required this.dueCount,
    required this.isRoot,
  });

  final int newCount;
  final int dueCount;
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // **The word, not a zero — and only when both sets are empty.** A `0` set
    // large is the loudest thing on the screen saying nothing happened; BR-29
    // makes "nothing due" a normal state. But the word is earned by having
    // nothing to do at all: with new cards waiting, the level is not caught up,
    // it just has no deadline yet (BR-150).
    final isCaughtUp = dueCount == 0 && newCount == 0;

    // Due leads when it exists — it expires, new does not. New takes the
    // headline only when it is the only work there is.
    final figure = isCaughtUp
        ? l10n.deckSummaryCaughtUpFigure
        : dueCount > 0
        ? '$dueCount'
        : '$newCount';
    final dueSentence = isRoot
        ? l10n.deckSummaryDueAcrossLibrary(dueCount)
        : l10n.deckSummaryDueInDeck(dueCount);
    final sentence = isCaughtUp
        ? l10n.deckSummaryCaughtUp
        : dueCount > 0
        // Both numbers on one line when both sets are non-empty, never merged
        // into one figure (BR-150).
        ? (newCount > 0
              ? '$dueSentence, ${l10n.deckSummaryNewBesideDue(newCount)}'
              : dueSentence)
        : l10n.deckSummaryNewToLearn(newCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // One line holding the figure and its sentence: the stacked version
        // cost a text row and read as a banner. `titleLarge` rather than a
        // display face for the same reason — the list is the hero.
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: figure,
                style: context.texts.titleLarge?.copyWith(
                  // Green only when it is good news. Left in the default ink
                  // the word "All" reads as a label; in `success` it reads as
                  // a result.
                  color: isCaughtUp ? context.semanticColors.success : null,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: sentence,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
