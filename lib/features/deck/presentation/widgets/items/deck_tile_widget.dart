import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_breakpoints.dart';
import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
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
    return MxCard.raised(
      padding: MxCardPadding.none,
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
            // **Named for its own row.** Every card carries this glyph, so a
            // screen reader moving control-to-control heard "Deck actions"
            // once per deck with nothing to tell them apart — the exact
            // problem `study_home_deck_item_widget.dart` already solved for
            // its own list, one tab away, and wrote the reasoning for. The app
            // bar's copy stays unqualified: there is one of it, and the title
            // beside it is the deck's name.
            semanticLabel: context.l10n.deckRowActionsSemanticLabel(
              summary.deck.name,
            ),
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
/// 14 New`) · rule · progress band (caption, gauge, Study). The workload comes
/// first because it is the decision input — a reader scans *what is pending*
/// before choosing to act. The track lives inside the surface, inset to the
/// content padding: flush on the card's bottom edge it read as a decorated
/// border rather than a measurement.
///
/// **The seam is drawn now, not merely spaced.** It was always a section
/// boundary — facts above, verbs below — and the comment on its padding said so
/// while nothing on screen did. `Divider` reads the app's `dividerTheme`, whose
/// `space` equals its `thickness`, so the rule occupies exactly the line it
/// draws and the spacing either side stays this widget's decision rather than
/// Material's default 16.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // `sm` either side of the rule, which is the seam the padding used to
        // hold on its own — one step more than the line breaks inside the
        // block above, because this is a section boundary and those are not.
        const SizedBox(height: AppSpacing.sm),
        Padding(
          // Inset to the gutter, not bled to the card's edge. A rule that runs
          // edge to edge cuts the card in two; one that stops where the text
          // stops separates two parts of the same card.
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: const Divider(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.sm,
            gutter,
            AppSpacing.lg,
          ),
          child: _DeckActionRow(summary: summary),
        ),
      ],
    );
  }
}

/// The gauge with its caption above it, and — when there is anything to study
/// — the verb beside it.
///
/// **The bar was a stub and now it is a measurement.** Caption and gauge shared
/// one line, so the track ran about 43% of the card's inner width with the
/// figure and the Study pill taking the rest — a 21% fill inside 43% of a
/// phone-width card is a sliver nobody reads a proportion off. Stacking the
/// caption over the track hands the gauge the whole column.
///
/// **And it costs nothing, which is why it is possible now.** The caption is
/// `labelMedium` (12 × 1.3 = 15.6), the gap is `sm`, the track is 4 — 27.6 in
/// total, under the [AppSizing.touchTarget] floor the Study pill already
/// imposes on this row. A studyable card is exactly as tall as it was.
///
/// **A finished card does pay for it**, by roughly the caption's own height:
/// with no verb there is no button, and with no button there is no floor. That
/// is the honest trade and `deck_summary_compact_geometry_test` measures it —
/// its fixture carries a fully-learned deck for exactly this reason.
///
/// **What is drawn is not what is announced.** The visible caption is
/// `Progress` and `21% learned`; the [Semantics] wrapper announces
/// `82 of 180 learned` with the percentage as its value, which is the fuller
/// sentence and the one this row has always given a screen reader. Drawing the
/// long form is what BR-88 removed from the card — "the same fact twice", a
/// caption restating the track beneath it — and it stays removed.
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
          // One semantics node for the whole gauge: the caption, the track and
          // the figure are one fact, and a reader should hear "82 of 180
          // learned, 46 percent learned" once — not a word, then a bar, then a
          // stray number. `MxProgressBar` announces its own label and value, so
          // it is excluded here rather than left to speak twice.
          child: Semantics(
            label: context.l10n.deckLearnedProgressLabel(
              summary.learnedCardCount,
              summary.totalCardCount,
            ),
            value: context.l10n.deckLearnedPercentLabel(percent),
            child: ExcludeSemantics(
              child: _DeckGauge(summary: summary, percent: percent),
            ),
          ),
        ),
        // **New counts too** (BR-150, BR-142): `hasDueCards` alone hid the
        // button on a deck of twenty unlearned cards. Absent — not disabled —
        // when both sets are empty: BR-29 makes "nothing pending" good news,
        // and a greyed verb says you cannot do the thing when the truth is
        // there is nothing to do.
        if (hasStudy) ...<Widget>[
          // **One step narrower below the compact breakpoint, for the reason
          // `deckTileGutter` is** — and the two are the same 4.9px argument.
          // That comment records this row arriving at 320 with `textScaler` 2.0
          // wanting more than the card had; shaving the gutter bought it back
          // with nothing to spare, and M100.30's bolder button label (w600 →
          // w700) then took 0.624px of the nothing. A gap is the cheapest thing
          // in the row to give: the gauge has already been sized, the figure
          // deliberately has no flex, and the verb is a touch target.
          SizedBox(
            width: AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width)
                ? AppSpacing.sm
                : AppSpacing.md,
          ),
          DeckStudyButtonWidget(
            deckId: summary.deck.id,
            deckName: summary.deck.name,
          ),
        ],
      ],
    );

    if (!hasStudy) return row;

    return Container(
      constraints: const BoxConstraints(minHeight: AppSizing.touchTarget),
      alignment: AlignmentDirectional.centerStart,
      child: row,
    );
  }
}

/// The learned gauge: a caption line, then the track beneath it.
///
/// **The caption belongs to this widget, not to [MxProgressBar].** The
/// primitive draws one — the hero panel uses it — but its header gives the
/// left-hand label all the flex and the right-hand figure none, which is
/// correct for the panel (`353 of 868 learned` beside `41%`: the long half is
/// on the left) and wrong here (`Progress` beside `37% learned`: the long half
/// is on the right). Measured at 320dp and textScaler 2.0 the tile's figure
/// wants 155.2 in a 160.2 column and the primitive's leading `sm` gap takes it
/// past the edge — a 3.0px `RenderFlex` overflow, reproduced before this was
/// written.
///
/// That is a defect in a shared primitive, and `docs/design-system/v1-freeze.md`
/// §2 line 6 freezes those: a feature task **MUST NOT** fix one in passing, so
/// this one is written up in the WBS debt ledger for a design-system task and
/// left alone. What the tile does instead is what the tile already did before
/// the caption moved above the track — assemble its own figure, with its own
/// ink rule.
///
/// **Measured, then drawn.** Whether both halves fit is a width question, so it
/// is answered with a `TextPainter` rather than by giving both halves flex and
/// hoping. Flex would not have worked anyway: two flexible children split the
/// line by *flex* and not by need, which leaves a hole between the caption and
/// a figure that should sit against the right edge — the same trap
/// `_HeroFigureLine` records one file over. When both fit, the figure takes its
/// natural width and the caption fills the rest, so the figure lands on the
/// right edge exactly. When they do not, the caption goes and the figure keeps
/// the line: the number is the fact, and `Progress` is the word that says the
/// least.
class _DeckGauge extends StatelessWidget {
  const _DeckGauge({required this.summary, required this.percent});

  final DeckSummary summary;
  final int percent;

  /// How wide [text] draws in [style], at the reader's own text scale.
  double _widthOf(BuildContext context, String text, TextStyle? style) =>
      (TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout()).width;

  @override
  Widget build(BuildContext context) {
    // Success is earned at 100% and only there — the same moment the gauge's
    // own fill turns (BR-88). Anything less is the neutral figure, whatever
    // today's due count happens to be. Unchanged from when this figure sat
    // beside the track, so moving it above changes no colour.
    final figureStyle = context.texts.labelMedium!.inked(
      context,
      summary.isFullyLearned ? AppInk.success : AppInk.quiet,
      isEmphasized: true,
    );
    final captionStyle = context.texts.labelMedium!.inked(
      context,
      AppInk.quiet,
    );

    final figure = context.l10n.deckTileLearnedPercentLabel(percent);
    final caption = context.l10n.deckTileProgressLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bothFit =
            _widthOf(context, caption, captionStyle) +
                AppSpacing.sm +
                _widthOf(context, figure, figureStyle) <=
            constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _caption(
              context,
              caption,
              figure,
              captionStyle,
              figureStyle,
              bothFit: bothFit,
            ),
            // `sm`, matching the primitive's own caption gap: at 4 the figure
            // sits on the track and the two read as one object.
            const SizedBox(height: AppSpacing.sm),
            // No `label` or `valueLabel` — the caption above is this widget's.
            MxProgressBar(
              size: MxProgressBarSize.sm,
              value: summary.learnedFraction,
            ),
          ],
        );
      },
    );
  }

  Widget _caption(
    BuildContext context,
    String caption,
    String figure,
    TextStyle? captionStyle,
    TextStyle? figureStyle, {
    required bool bothFit,
  }) {
    final figureText = Text(
      figure,
      style: figureStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    // Alone, the figure takes the whole line. `Expanded` rather than a bare
    // `Text` so that a figure wider than even this column ellipsizes instead
    // of overflowing — the failure mode this branch exists to avoid.
    if (!bothFit) return Row(children: <Widget>[Expanded(child: figureText)]);

    return Row(
      // One baseline: a caption and a figure of the same rung sitting on two
      // baselines read as two lines that happen to overlap.
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(
          child: Text(
            caption,
            style: captionStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // No flex, and it is safe: `bothFit` has already proved the natural
        // width fits. That is what puts the figure against the right edge
        // instead of somewhere in the middle of its flex share.
        figureText,
      ],
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
