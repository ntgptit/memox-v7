import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../../../shared/widgets/mx_mastery_ring.dart';
import '../../../../../shared/widgets/mx_pressable.dart';
import '../../../domain/models/deck_summary_model.dart';
import 'deck_status_icon_widget.dart';
import 'deck_workload_line_widget.dart';

/// One deck in a deck list, at any level (UC-06 step 2) — the handoff's
/// "ListTile · deck row".
///
/// There used to be a second tile for sub-decks, showing only a name — because
/// the detail screen's query did not load counts for them. The recursive
/// aggregate landed and the reason evaporated: a sub-deck now carries the same
/// facts a root does, so it gets the same row.
///
/// A feature widget, not a shared one: it knows [DeckSummary], and a shared
/// row that knew a domain type would drag the deck domain into every widget
/// test in the project.
///
/// **A row again, reversing M4.12** (owner decision 7, 2026-09-13). M4.12 made
/// each deck its own card with a gauge band and a Study button, on the argument
/// that a `ListTile` reads as a table. The owner chose the handoff's row: the
/// identity tile, the name over what the deck holds and what is waiting, the
/// learned ring, the overflow — rows grouped on one card by
/// `DeckListSliverWidget`. A session starts from the Study tab or inside the
/// deck; the row opens the deck.
///
/// **Three lines where the handoff draws two**, because UC-06 step 2 names the
/// total card count beside the two BR-150 counts, and the counts are chips —
/// one line cannot carry both without the words wrapping into the grounds.
///
/// The due state is carried by an icon, by words **and** by colour, never by
/// colour alone (UC-06 step 3). "Nothing due" is neutral — the resting state
/// of the schedule, not an achievement (BR-29). `mastery` belongs to one
/// moment only: the ring at 100% learned (BR-88, D8).
class DeckTileWidget extends StatelessWidget {
  const DeckTileWidget({
    required this.summary,
    required this.onTap,
    required this.onActions,
    super.key,
  });

  final DeckSummary summary;
  final VoidCallback onTap;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final percent = (summary.learnedFraction * 100).round();

    // `button` over the ink, as `MxCard` annotates a tappable card: an
    // `InkWell` contributes the tap but not the flag. The overflow is a nested
    // button and wins the gesture arena, so it stays its own action.
    return Semantics(
      button: true,
      child: MxPressable(
        onTap: onTap,
        shape: MxPressableShape.none,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizing.rowMinHeight),
          child: Padding(
            // `xs` at the end: the overflow is a 48 box around a 24 glyph, so
            // 4 + its own 12 inset lands the glyph on the 16 gutter.
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                DeckStatusIconWidget(
                  status: summary.scheduleStatus,
                  contentType: summary.deck.contentType,
                  dueCardCount: summary.dueCardCount,
                  overdueDayCount: summary.overdueDayCount,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.xs,
                    children: <Widget>[
                      Text(
                        summary.deck.name,
                        style: context.texts.bodyLarge,
                        // **Two lines, where the handoff's generic ListRow
                        // cuts at one.** The deck row's own spec names no line
                        // budget, and `deck_text_fit_test` holds that an
                        // ordinary name never loses a word: beside the ring and
                        // the overflow, `Academic Word List` cut at 360 × 1.3.
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      _DeckMetaLine(summary: summary),
                      DeckWorkloadLineWidget(summary: summary),
                    ],
                  ),
                ),
                // A deck with no cards has no denominator, so there is no
                // ring to draw — the workload line already says "No cards".
                if (summary.totalCardCount > 0) ...<Widget>[
                  const SizedBox(width: AppSpacing.md),
                  MxMasteryRing(
                    value: summary.learnedFraction,
                    isComplete: summary.isFullyLearned,
                    semanticsLabel: l10n.deckLearnedProgressLabel(
                      summary.learnedCardCount,
                      summary.totalCardCount,
                    ),
                    semanticsValue: l10n.deckLearnedPercentLabel(percent),
                  ),
                ],
                MxIconButton(
                  icon: Icons.more_vert,
                  // **Named for its own row.** Every row carries this glyph,
                  // so a screen reader moving control-to-control would hear
                  // "Deck actions" once per deck with nothing to tell them
                  // apart. The app bar's copy stays unqualified: there is one
                  // of it, and the title beside it is the deck's name.
                  semanticLabel: l10n.deckRowActionsSemanticLabel(
                    summary.deck.name,
                  ),
                  onPressed: onActions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The structural facts: `570 cards · 4 sub-decks` (UC-06).
///
/// **Plain text groups, back by measurement.** The icon-per-metric pass gave
/// every fact its own glyph and the golden showed the cost: five anchors on a
/// three-line block, metadata wrapping at ordinary widths, taller cards. The
/// facts are quiet context, and quiet context reads best as words.
///
/// A `Wrap` of atomic groups rather than one rich text: each `·` is glued to
/// the fact it introduces, so a narrow screen breaks between facts and never
/// strands a separator. **Cards first, and no scheduler** (owner mockup,
/// 2026-08-20): the card count is the fact a learner compares decks by, and
/// the algorithm is a configuration detail that moved to the deck's own
/// level — a column of "8 boxes" distinguished nothing and dressed every
/// row in a term from the settings sheet.
class _DeckMetaLine extends StatelessWidget {
  const _DeckMetaLine({required this.summary});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    final facts = <String>[
      context.l10n.deckCardCountLabel(summary.totalCardCount),
      // Only when there are any: a group that reads "0 sub-decks" spends
      // itself saying nothing happened.
      if (summary.subDeckCount > 0)
        context.l10n.deckSubDeckCountLabel(summary.subDeckCount),
    ];
    final quiet = context.texts.bodySmall!.inked(context, AppInk.quiet);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final (index, fact) in facts.indexed)
          index == 0
              ? Text(
                  fact,
                  style: quiet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('·', style: quiet),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      fact,
                      style: quiet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
      ],
    );
  }
}
