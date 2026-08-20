import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_material_roles.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../../../shared/widgets/mx_progress_bar.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_summary_model.dart';
import '../../states/deck_list_view_state.dart';
import 'deck_summary_metrics_widget.dart';

/// The level's study status, as the screen's one hero (BR-150, BR-161).
///
/// At the root it answers "what is waiting today"; inside a deck it answers the
/// same question about that deck. They are the same question at different
/// scopes, so they are one block rather than a home screen and a header.
///
/// **Status-first, in scan order.** The panel reads top to bottom the way the
/// question is actually asked: the time scope (`Today`), then the four
/// disjoint sets of BR-162 most-urgent-first — the backlog that missed its day
/// (Overdue), the reviews that belong to today (Due today), the cards still
/// waiting to be learned (New), the cards resting until a later review
/// (Scheduled) — then how far the level has come. Together the four partition
/// every card the level holds, so the grid also reads as a whole. One focal
/// point — the most urgent non-empty set leads with the larger numeral —
/// because figures at equal weight is what made the old panel scan as a table
/// row instead of an answer. The tile keeps the undivided `Due` total; the
/// hero is where the breakdown lives.
///
/// **Every number here is arithmetic over the snapshot the screen already has.**
/// A child's counts are its whole subtree, and sibling subtrees are disjoint, so
/// the level folds on [DeckListSnapshot] are the level's totals — no second
/// read, and therefore no chance of the panel and the list disagreeing about
/// the same instant (AD-13). A deck holds one kind of thing (BR-63), so a level
/// whose children are decks has no cards of its own to leave out of the sum.
///
/// **The surface is [MxCard], not a hand-rolled box.** Radius, border,
/// elevation and interaction states all come from the one shared surface; the
/// panel itself is not tappable — the close button is its only control.
class DeckLevelSummaryWidget extends StatelessWidget {
  const DeckLevelSummaryWidget({
    required this.snapshot,
    required this.onDismiss,
    this.onStudyDue,
    super.key,
  });

  final DeckListSnapshot snapshot;

  /// Starts studying what the hero counts. Null hides the CTA — the panel
  /// stays honest on a level with nothing due.
  final VoidCallback? onStudyDue;

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
    final cardCount = decks.fold<int>(0, (sum, d) => sum + d.totalCardCount);
    final learnedCount = decks.fold<int>(
      0,
      (sum, d) => sum + d.learnedCardCount,
    );
    return MxCard(
      // **Indigo hairline, and a step further off the page** (owner review,
      // 2026-08-20). On the default border the panel did not separate from the
      // background at all — a card that carries the screen's one answer has to
      // look like a surface, not like a region of the page.
      borderColor: context.semanticColors.borderAccent,
      elevation: AppElevation.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            // Centred against the close button's 48 floor: the eyebrow is one
            // short label, and the button's surplus splits evenly around it
            // instead of pooling underneath.
            children: <Widget>[
              Expanded(
                child: Text(
                  // The scope, not a narration: every figure below is "as of
                  // today", and saying it once up here is what lets the
                  // metrics be bare numbers.
                  context.l10n.deckSummaryTodayLabel.toUpperCase(),
                  // The section-label treatment the list heading already
                  // wears, in the brand ink: an eyebrow set like body copy
                  // read as a stray word above the numeral rather than as the
                  // panel's scope (owner review, 2026-08-20).
                  style: context.texts.labelMedium?.copyWith(
                    color: brandInk(context.colors),
                    letterSpacing: AppTypography.sectionLabelTracking,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // A chevron, not an X: this collapses to a one-line link and
              // comes back — X promised removal (owner mockup, 2026-08-20).
              // **It points down while the panel is open**: the arrow shows
              // where the content goes, and up is what the collapsed link
              // wears to bring it back (owner review, 2026-08-20).
              MxIconButton(
                icon: Icons.expand_more,
                semanticLabel: context.l10n.deckSummaryHideLabel,
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          DeckSummaryMetricsWidget(snapshot: snapshot),
          if (cardCount > 0) ...<Widget>[
            // `lg`: the seam between "what is waiting" and "how far you are"
            // is the panel's one section break, one step wider than the line
            // breaks inside each band.
            const SizedBox(height: AppSpacing.lg),
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
          // The main task, on top of the screen instead of a scroll away
          // (owner mockup, 2026-08-20). At the root it opens the Study tab —
          // a session belongs to one root deck (BR-101), so a cross-deck
          // session cannot honestly be offered; inside a deck it starts that
          // deck's study. The caller decides which; null means nothing is
          // due and the button would be a promise with no cards behind it.
          if (onStudyDue != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            MxActionButton(
              label: context.l10n.deckSummaryStudyDueAction(
                snapshot.levelDueCardCount,
              ),
              onPressed: onStudyDue,
            ),
          ],
        ],
      ),
    );
  }
}
