import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_progress_bar.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_summary_model.dart';
import 'deck_summary_metrics_widget.dart';

/// The level's study status, as the screen's one hero (BR-150, BR-161).
///
/// At the root it answers "what is waiting today"; inside a deck it answers the
/// same question about that deck. They are the same question at different
/// scopes, so they are one block rather than a home screen and a header.
///
/// **Two lines, because the screen belongs to the list under it** (owner
/// review, 2026-08-25). Measured before the change: 320px of a 852px viewport
/// — 37.6% — which left one and a half deck cards on screen and put the third
/// below the fold. The panel now reads
///
/// ```
/// 15 cards due   8 overdue · 7 today            ⌄
/// [        Study 15 due cards        ]
/// ```
///
/// which measures 140px, 16.4%. What went is not
/// data but *ranking*: the eyebrow (`TODAY` said nothing "cards due" does not),
/// the New/Scheduled band and the learned caption are resting figures, and they
/// sit one chevron away rather than at the top of the screen every time it
/// opens.
///
/// **The panel is no longer dismissible, and that is the same decision.** The
/// dismiss button existed because the panel was in the way of the list; at 16%
/// it is not, and one chevron cannot mean both "hide me" and "show me more"
/// (owner decision, 2026-08-25). A level with nothing studyable renders no
/// panel at all — [hasStudyable] is now the presence rule outright, where it
/// used to be what `auto` resolved to.
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
/// panel itself is not tappable — the chevron is its only control.
class DeckLevelSummaryWidget extends StatelessWidget {
  const DeckLevelSummaryWidget({
    required this.snapshot,
    required this.isExpanded,
    required this.onToggleExpanded,
    this.onStudyDue,
    super.key,
  });

  final DeckListSnapshot snapshot;

  /// Starts studying what the hero counts. Null hides the CTA — the panel
  /// stays honest on a level with nothing due.
  final VoidCallback? onStudyDue;

  /// Whether the resting figures — New, Scheduled, and the learned caption —
  /// are on screen.
  final bool isExpanded;

  /// Opens or shuts them.
  final VoidCallback onToggleExpanded;

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
  /// The presence rule. Exposed here rather than computed by the caller so that
  /// the number deciding whether the panel appears and the number the panel
  /// prints are the same fold over the same snapshot — a panel that appeared
  /// because of one count and then displayed another would be worse than one
  /// that never appeared.
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
          DeckSummaryMetricsWidget(
            snapshot: snapshot,
            isExpanded: isExpanded,
            onToggleExpanded: onToggleExpanded,
          ),
          // **The bar belongs to the disclosure, not to the resting panel**
          // (owner review, 2026-08-25, third pass). It shipped as a bare 4px
          // rule on the brief's own instruction — "no label" — and the owner's
          // read of the result is the argument against it: a 41% fill sitting
          // between `15 cards due` and the Study button states a proportion of
          // nothing the eye can name. A gauge with no referent is not quieter
          // than a labelled one, it is only smaller.
          //
          // So it goes where its caption already was. Collapsed, the panel is
          // the figure line and the CTA and nothing else; open, the bar arrives
          // with `353 of 868 learned` and `41%` attached. The learned figure is
          // now behind the chevron for a screen reader too, which is the
          // honest consequence — it was the only reader getting it at rest.
          if (isExpanded && cardCount > 0) ...<Widget>[
            // `md` between every band, not `lg` between some and `xl` between
            // others: the panel is two lines and a rule now, and a section
            // break inside three rows is a break between nothing.
            const SizedBox(height: AppSpacing.md),
            // The same progress tokens as every tile: track, fill, and success
            // only at 100%.
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
            const SizedBox(height: AppSpacing.md),
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
