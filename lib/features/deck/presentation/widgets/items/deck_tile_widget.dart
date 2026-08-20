import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_breakpoints.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../../../shared/widgets/mx_progress_bar.dart';
import '../../../domain/models/deck_summary_model.dart';
import 'deck_status_icon_widget.dart';
import 'deck_workload_line_widget.dart';
import 'deck_study_button_widget.dart';

/// One deck in a deck list, at any level (UC-06 step 2).
///
/// There used to be a second tile for sub-decks, showing only a name — because
/// the detail screen's query did not load counts for them. The recursive
/// aggregate landed and the reason evaporated: a sub-deck now carries the same
/// facts a root does, so it gets the same row.
///
/// A feature widget, not a shared one: it knows [DeckSummary], and a shared
/// tile that knew a domain type would drag the deck domain into every widget test
/// in the project. It is built **on** `MxCard`, so the surface colour, the corner
/// radius, the border and the ripple still come from one place.
///
/// **It stopped being an `MxListTile` at M4.12.** A `ListTile` puts everything on
/// one baseline at a fixed height, which reads as a row in a table — every deck
/// the same weight, nothing to scan for. The card gives the name its own line,
/// the counts a quieter one under it, and the state its own colour, so a list of
/// twenty decks can be read by shape rather than by reading each row.
///
/// The due state is carried by an icon, by words **and** by colour, never by
/// colour alone (UC-06 step 3). "Nothing due" is neutral — the resting state
/// of the schedule, not an achievement (BR-29). `success` belongs to one
/// moment only: the gauge and its figure at 100% learned (BR-88).
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

  /// Whether the metadata line names the review algorithm.
  ///
  /// True at the root list, where decks genuinely differ; false inside a
  /// deck, where every descendant inherits the root's scheduler (BR-06) and
  /// repeating `8 boxes` on every child row is a column of non-information.
  /// The *screen* passes this from its snapshot — a tile guessing the level
  /// from its entity would be a second copy of `isRootLevel`.

  @override
  Widget build(BuildContext context) {
    // **Flat, and padded by its bands rather than as a whole.** The design's
    // deck card carries a hairline and no shadow -- two competing depths in one
    // scrolling column is what makes a list read as busy, and the card no longer
    // needs a shadow to separate from the page now that it has three bands of
    // its own. The padding moves inside so the card's ink covers the whole of
    // what it opens, edge to edge.
    //
    // **The whole card opens the deck.** Only the top band used to, and the two
    // bands under it -- the progress bar, the due chip -- then looked tappable
    // and were not. `MxCard` takes the tap; the overflow menu is a nested button
    // and wins the gesture arena over it, so it stays its own action.
    return MxCard(
      elevation: AppElevation.none,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DeckHeadRegion(summary: summary, onActions: onActions),
          _DeckStateRegion(summary: summary),
        ],
      ),
    );
  }
}

/// The card's first band: the well, the name, the counts, and the row's menu.
///
/// **Layout only — the tap belongs to the card.** This was its own `InkWell` for
/// one release, which made the hover and the ripple cover the top third of a card
/// whose other bands opened the same deck and showed nothing.
///
/// **The menu moved up here from a band of its own.** A 48-tall row holding one
/// icon button cost the card 48 pixels to say nothing; this band is already at
/// least that tall because the button sets its floor, so the row came for free.
/// That is most of what took the card from 168 to about 110 — on a 393x852 screen
/// the difference is 2.3 visible decks against 3.5.
class _DeckHeadRegion extends StatelessWidget {
  const _DeckHeadRegion({required this.summary, required this.onActions});

  final DeckSummary summary;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // **`xs` on the right:** the overflow button is a 48 box around a 24
      // glyph, so 4 + its own 12 inset lands on the 16 gutter every other
      // element uses. `md` on top since the density pass. **Zero at the
      // bottom, deliberately:** the head owns every line break inside the
      // block, and the action row below owns its own seam.
      padding: EdgeInsets.fromLTRB(
        deckTileGutter(context),
        AppSpacing.lg,
        AppSpacing.xs,
        0,
      ),
      child: Row(
        // Top, not centre. Once the name wraps -- a long deck title, or any
        // title at `textScaler` 2.0 -- a centred glyph floats halfway down the
        // card with nothing beside it, and the row stops reading left to right.
        crossAxisAlignment: CrossAxisAlignment.start,
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
              children: <Widget>[
                Text(
                  summary.deck.name,
                  style: context.texts.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                _DeckMetaLine(summary: summary),
                const SizedBox(height: AppSpacing.xs),
                DeckWorkloadLineWidget(summary: summary),
              ],
            ),
          ),
          MxIconButton(
            icon: Icons.more_vert,
            semanticLabel: context.l10n.deckActionsSemanticLabel,
            onPressed: onActions,
          ),
        ],
      ),
    );
  }
}

/// The card's lower bands: what is waiting, then how far through it is and
/// what to do about it.
///
/// **Anatomy, fixed:** header (identity + menu) · workload line (`7 Due ·
/// 14 New`) · action row (gauge, percentage, Study). The workload comes first
/// because it is the decision input — a reader scans *what is pending* before
/// choosing to act. The track lives inside the surface, inset to the content
/// padding: flush on the card's bottom edge it read as a decorated border
/// rather than a measurement.
class _DeckStateRegion extends StatelessWidget {
  const _DeckStateRegion({required this.summary});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    // A deck with no cards has no denominator, so there is no gauge to draw
    // and no verb to offer — the metadata block already says "No cards", and
    // the card simply ends after it.
    if (summary.totalCardCount == 0) {
      return const SizedBox(height: AppSpacing.md);
    }

    final gutter = deckTileGutter(context);

    return Padding(
      // `sm` on top: the seam between the metadata block and the action row is
      // a *section* boundary — information above, verbs below — so it gets one
      // step more than the line breaks inside the block.
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.sm,
        gutter,
        AppSpacing.lg,
      ),
      child: _DeckActionRow(summary: summary),
    );
  }
}

/// The gauge, its figure, and — when there is anything to study — the verb.
///
/// **The touch floor belongs to the button, not to the row.** With a Study
/// pill the row stands 48 tall because the pill's hit area does — a minimum,
/// so text scale 2.0 still grows past it. Without one there is nothing whose
/// target the height would protect, so the row takes its natural height and a
/// completed card is honestly shorter than a studyable one.
class _DeckActionRow extends StatelessWidget {
  const _DeckActionRow({required this.summary});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    final percent = (summary.learnedFraction * 100).round();
    final hasStudy = summary.hasStudyableCards;

    final row = Row(
      children: <Widget>[
        Expanded(
          // One semantics node for the pair: the gauge and its figure are
          // one fact, and a reader should hear "82 of 180 learned,
          // 46 percent learned" once, not a bar and then a stray number.
          child: Semantics(
            label: context.l10n.deckLearnedProgressLabel(
              summary.learnedCardCount,
              summary.totalCardCount,
            ),
            value: context.l10n.deckLearnedPercentLabel(percent),
            child: ExcludeSemantics(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: MxProgressBar(
                      size: MxProgressBarSize.sm,
                      value: summary.learnedFraction,
                    ),
                  ),
                  // `xs`, not `sm`: the figure belongs to the gauge it
                  // measures, and the wider gap read as two elements (owner
                  // review, 2026-08-20).
                  const SizedBox(width: AppSpacing.xs),
                  // **No flex on the label** (owner review, 2026-08-20). A
                  // loose flex child takes only the width it needs and its
                  // share of the leftover stays empty, which put a hole
                  // between the gauge and its figure and left the bar at half
                  // the row. Natural width here, and the gauge's `Expanded`
                  // absorbs everything else — the mockup's `flex: 1`.
                  Text(
                    context.l10n.deckTileLearnedPercentLabel(percent),
                    style: context.texts.labelMedium?.copyWith(
                      // Success is earned at 100% and only there — the same
                      // moment the gauge's own fill turns (BR-88). Anything
                      // less is the neutral figure, whatever today's due
                      // count happens to be.
                      color: summary.isFullyLearned
                          ? context.semanticColors.success
                          : context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        // **New counts too** (BR-150, BR-142): `hasDueCards` alone hid the
        // button on a deck of twenty unlearned cards. Absent — not disabled —
        // when both sets are empty: BR-29 makes "nothing pending" good news,
        // and a greyed verb says you cannot do the thing when the truth is
        // there is nothing to do.
        if (hasStudy) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          DeckStudyButtonWidget(deckId: summary.deck.id),
        ],
      ],
    );

    if (!hasStudy) return row;

    return Container(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minimumTouchTarget,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: row,
    );
  }
}

/// The card's own gutter: 16, or 12 below [AppBreakpoints.compact].
///
/// **One number for every band on the card**, because the well, the text
/// column and the gauge all line up against it — a region that scaled alone
/// would break the axis the geometry test pins.
///
/// It scales for the same reason `mxScreenGutter` and `applyCompactScale` do:
/// at 320 with `textScaler` 2.0 the gauge, the worded figure and the verb
/// wanted 4.9px more than the card had, and one step off each side is the
/// version that keeps all three rather than dropping one.
double deckTileGutter(BuildContext context) =>
    AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width)
    ? AppSpacing.md
    : AppSpacing.lg;

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
/// card in a term from the settings sheet.
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
    final quiet = context.texts.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

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
