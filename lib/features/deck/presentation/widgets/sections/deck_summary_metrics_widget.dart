import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/app_stroke.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';

/// How far the figure line stops short of the card's right edge.
///
/// The disclosure is [AppSpacing.minimumTouchTarget] wide and sits in the
/// card's own corner, outside the content's [AppSpacing.lg] padding — so the
/// line has to give back the difference, or the overdue split runs under it.
/// Derived from the two numbers it is made of rather than written as 32, so
/// moving either one moves this with it.
const double heroDisclosureInset =
    AppSpacing.minimumTouchTarget - AppSpacing.lg;

/// The hero's figure line, and the resting figures behind its disclosure
/// (owner mockup, 2026-08-20; compacted 2026-08-25).
///
/// **One number, because one question.** The panel used to print the four
/// disjoint sets of BR-162 at near-equal weight, and the owner's review read
/// it the way any table reads: as homework. What the user asks the panel is
/// "how much is waiting", and the answer is overdue + due today in one
/// numeral — the split survives beside it, red on the overdue half only.
///
/// **The split shares the numeral's line rather than sitting under it.** It
/// was a subline, which cost a whole row of height to say something that fits
/// in the space the numeral leaves empty. Both groups are `Flexible`, so a
/// long translation at double scale ellipsizes instead of overflowing, and
/// they share one baseline: figures of two sizes sitting on different baselines
/// is what made the old two-line arrangement read as two facts rather than one.
///
/// **New and Scheduled are context, not actions — and now they are also not
/// default.** They were the third band of a panel that stood at 38% of the
/// viewport; they keep their tint and their indigo hairline, one disclosure
/// away. With them behind the chevron, overdue red is the only semantic colour
/// left on the collapsed card, which is what lets it mean something.
///
/// **Every number is still arithmetic over the snapshot the screen already
/// has** (AD-13): a child's counts cover its whole subtree and siblings are
/// disjoint, so the level folds are the level's totals — no second read.
class DeckSummaryMetricsWidget extends StatelessWidget {
  const DeckSummaryMetricsWidget({
    required this.snapshot,
    required this.isExpanded,
    super.key,
  });

  final DeckListSnapshot snapshot;

  /// Whether the resting figures are open.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final overdueCount = snapshot.levelOverdueCardCount;
    final dueCount = snapshot.levelDueCardCount;
    final newCount = snapshot.levelNewCardCount;
    final scheduledCount = snapshot.levelScheduledCardCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // **The chevron is not in this row, and that is the whole point**
        // (owner review, 2026-08-25, fourth pass). It used to be, and its 48px
        // touch target then set the row's height while the figure line is 32 —
        // so 16px of nothing had to sit either above the numeral or below it,
        // and the arithmetic made the two things the owner asked for exclusive:
        //
        //     above_ink + below_ink = 48 - 23.7 = 24.3   (fixed)
        //     gap to card top       = 16 + above_ink
        //     gap to the CTA        = below_ink + 12
        //     => their sum is 52.3, whatever the alignment
        //
        // Top-aligning gave 24.3 above and 28 below; centring would give 32.3
        // and 20. Neither is "16 above, 12 below". The row has to stop being
        // 48 tall, so the chevron moved to the card's own corner — see
        // [DeckLevelSummaryWidget], which owns the `Stack` it now lives in.
        //
        // The right inset is what keeps the overdue split from running under
        // it: the chevron is 48 wide at the card's edge and the content's own
        // padding is 16, so the line stops 32 earlier than the rest.
        Padding(
          padding: const EdgeInsets.only(right: heroDisclosureInset),
          child: _HeroFigureLine(
            dueCount: dueCount,
            newCount: newCount,
            overdueCount: overdueCount,
            overdueDayCount: snapshot.levelOverdueDayCount,
          ),
        ),
        if (isExpanded) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _QuietContextRow(newCount: newCount, scheduledCount: scheduledCount),
        ],
      ],
    );
  }
}

/// `15 cards due · 8 overdue · 7 today`, on one baseline.
///
/// Two semantic nodes rather than one sentence: the numeral answers "how much"
/// and the split answers "how bad", and a reader who has heard the first may
/// not need the second. Each group excludes its own children so the figures are
/// not read twice.
class _HeroFigureLine extends StatelessWidget {
  const _HeroFigureLine({
    required this.dueCount,
    required this.newCount,
    required this.overdueCount,
    required this.overdueDayCount,
  });

  final int dueCount;
  final int newCount;
  final int overdueCount;
  final int overdueDayCount;

  /// How wide [text] draws in [style], at the reader's text scale.
  ///
  /// The line has to be measured rather than laid out speculatively: both
  /// halves are `Flexible`, so when the row is short both of them shrink and
  /// both ellipsize — which is how `15 cards due  8 overdue · 7 today` became
  /// `15 car…  8 overdue…` and lost half of BR-162 rather than losing the less
  /// important half whole.
  double _widthOf(BuildContext context, String text, TextStyle? style) =>
      _widthOfSpan(context, TextSpan(text: text, style: style));

  /// **The span that is measured is the span that is drawn.** Measuring the
  /// breakdown as plain `bodyMedium` under-reported it: its first half is
  /// `w600`, which is wider, so the line was judged to fit by a few pixels and
  /// then clipped by exactly those few — 6px in English, 9 in Vietnamese.
  double _widthOfSpan(BuildContext context, InlineSpan span) {
    final painter = TextPainter(
      text: span,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    return painter.width;
  }

  /// The numeral's style — **one definition, used to measure and to draw.**
  /// `tabularFigures` widens the digits, and leaving it out of the measurement
  /// under-reported the line by the few pixels it then clipped.
  TextStyle? _numeralStyle(BuildContext context) =>
      context.texts.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: AppTypography.heroNumeralCapTrim,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );

  /// BR-162's split as one span: `8 overdue` in the overdue ink, then the rest.
  TextSpan _breakdownSpan(BuildContext context) => TextSpan(
    style: context.texts.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    ),
    children: <InlineSpan>[
      TextSpan(
        text: context.l10n.deckSummaryOverduePart(overdueCount),
        style: context.texts.bodyMedium?.copyWith(
          color: context.semanticColors.overdue,
          fontWeight: FontWeight.w600,
        ),
      ),
      const TextSpan(text: ' · '),
      TextSpan(
        text: context.l10n.deckSummaryDueTodayPart(dueCount - overdueCount),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // The hero numeral: what is due; a level with nothing due but new cards
    // waiting leads with those instead (BR-150 — new-only is studyable).
    final heroCount = dueCount > 0 ? dueCount : newCount;
    final heroWord = dueCount > 0
        ? context.l10n.deckSummaryCardsDueWord
        : context.l10n.deckHeroNewMetricWord;

    return LayoutBuilder(
      builder: (context, constraints) {
        // **Both halves whole on two lines, or neither whole on one.** At 360
        // the row is six pixels short in English and nine in Vietnamese — at
        // the default text scale, on the width the gallery does not capture —
        // so it wrapped both halves rather than moving one down.
        final needed =
            _widthOf(context, '$heroCount', _numeralStyle(context)) +
            AppSpacing.sm +
            _widthOf(context, heroWord, context.texts.titleMedium) +
            (overdueCount == 0
                ? 0
                : AppSpacing.md +
                      _widthOfSpan(context, _breakdownSpan(context)));
        final fitsOnOneLine = needed <= constraints.maxWidth;

        return _line(
          context,
          heroCount,
          heroWord,
          fitsOnOneLine: fitsOnOneLine,
        );
      },
    );
  }

  Widget _line(
    BuildContext context,
    int heroCount,
    String heroWord, {
    required bool fitsOnOneLine,
  }) {
    // Stacked, the breakdown is its own line under the numeral, so neither is
    // cut. The baseline alignment only means anything while they share a line.
    if (!fitsOnOneLine) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _numeral(context, heroCount, heroWord),
          if (overdueCount > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            _breakdown(context),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Flexible(child: _numeral(context, heroCount, heroWord)),
        // The breakdown, only when there is one to state: with no overdue it
        // would repeat the numeral beside it in smaller type.
        if (overdueCount > 0) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          Flexible(child: _breakdown(context)),
        ],
      ],
    );
  }

  /// `15 cards due` — the figure and the unit it counts, on one baseline.
  Widget _numeral(BuildContext context, int heroCount, String heroWord) =>
      Semantics(
        container: true,
        label: dueCount > 0
            ? context.l10n.deckHeroDueTodaySemanticLabel(dueCount)
            : context.l10n.deckHeroNewSemanticLabel(newCount),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$heroCount',
                // **A cap-height trim, not a leading cut.** `height: 1`
                // already made the box exactly the font size, and the
                // remaining 8.3px above the digits is the font's ascent
                // above its cap — no `TextStyle` knob reaches it, and
                // `leadingDistribution: even` was measured to change
                // nothing because there is no leading left to distribute.
                // [AppTypography.heroNumeralCapTrim] carries the derivation
                // and the measurement.
                //
                // Digits have no descenders and take no diacritics, so this
                // is the one string in the app whose box can under-report
                // its glyph without risking a clip. The 12px below this
                // line is what the overflow eats into, and it fits at every
                // scale the responsive matrix covers.
                //
                // `headlineLarge`, one rung down from `displaySmall`
                // (owner review, 2026-08-25): 36px was set when the
                // numeral had a row to itself, and 32 is what fits beside
                // its own breakdown on a 393 screen.
                style: context.texts.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: AppTypography.heroNumeralCapTrim,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  heroWord,
                  style: context.texts.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  /// `8 overdue · 7 today` — BR-162's split, in one sentence.
  Widget _breakdown(BuildContext context) => Semantics(
    label: context.l10n.deckHeroOverdueSemanticLabel(
      overdueCount,
      overdueDayCount,
    ),
    child: ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: context.l10n.deckSummaryOverduePart(overdueCount),
              style: context.texts.bodyMedium?.copyWith(
                color: context.semanticColors.overdue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' · '),
            TextSpan(
              text: context.l10n.deckSummaryDueTodayPart(
                dueCount - overdueCount,
              ),
            ),
          ],
        ),
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

/// New and Scheduled, side by side on the brand tint, split by an indigo
/// hairline (owner review, 2026-08-20). It was a neutral grey inset, which
/// left the panel flat: the tint is what makes the row read as part of the
/// hero rather than as a gap in it.
class _QuietContextRow extends StatelessWidget {
  const _QuietContextRow({
    required this.newCount,
    required this.scheduledCount,
  });

  final int newCount;
  final int scheduledCount;

  @override
  Widget build(BuildContext context) {
    Widget cell(int count, String word, String semanticLabel) => Expanded(
      child: Semantics(
        label: semanticLabel,
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$count',
                style: context.texts.titleMedium?.copyWith(
                  color: context.colors.onPrimaryContainer,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Flexible: at double scale on a compact width half the row is
              // narrower than the word — the figure holds, the word clips.
              Flexible(
                child: Text(
                  // Lower-case: the word is the unit, the figure is the fact,
                  // and a capital gave the two equal billing.
                  word.toLowerCase(),
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      // 12 down the sides of the figures, 16 across: the block is a panel
      // inside a panel, so it takes the grid's next step in rather than the
      // card's own inset (owner review, 2026-08-20).
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          cell(
            newCount,
            context.l10n.deckHeroNewMetricWord,
            context.l10n.deckHeroNewSemanticLabel(newCount),
          ),
          // A decoration, not `color:`: `Container(color:)` builds a
          // ColoredBox, which the visual audit cannot read a colour from —
          // the DecoratedBox route keeps the hairline auditable. The rule is
          // the brand ink so it belongs to the tint it divides; a neutral
          // grey line on an indigo ground read as a seam.
          Container(
            width: AppStroke.hairline,
            height: AppSpacing.lg,
            decoration: BoxDecoration(color: context.colors.primary),
          ),
          cell(
            scheduledCount,
            context.l10n.deckHeroScheduledMetricWord,
            context.l10n.deckHeroScheduledSemanticLabel(scheduledCount),
          ),
        ],
      ),
    );
  }
}
