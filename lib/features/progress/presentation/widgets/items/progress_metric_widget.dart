import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_metric_well.dart';
import '../../../domain/models/deck_activity_metrics_model.dart';

/// How large the numerals in a metric grid read.
///
/// Two rungs, and the difference carries meaning rather than decoration: the
/// summary panel is the level's headline and the rows beneath it are its parts,
/// so the panel speaks one step louder. Both use the same anatomy, which is what
/// keeps a row and the panel above it reading as one grammar.
enum ProgressMetricScale {
  /// The summary panel.
  panel,

  /// A deck row.
  row,
}

/// The four figures of one window, as a 2×2 baseline-aligned grid (BR-183,
/// BR-186).
///
/// **A real two-column grid, not a `Wrap`.** `Expanded` halves mean the second
/// column shares a left edge down the whole grid whatever the first column's
/// word happens to be — intrinsic sizing was what let one row's second cell
/// drift out of line with the row below it on the deck hero, and the same
/// arrangement would do it here.
///
/// **Each row aligns on the alphabetic baseline, not the top.** Two cells of one
/// row can wrap to different heights at large text scale, and a top-aligned row
/// then hangs one baseline below its neighbour's: the figures read as jittering
/// rather than as one line.
///
/// **Order is fixed and never reorders by value.** Cards and days say how much
/// and how often; learning and reviewing split that work in two. Sorting the
/// grid by size would make two screenshots of the same screen incomparable —
/// and it is the same four, in the same order, when the grid folds to one
/// column.
class ProgressMetricGridWidget extends StatelessWidget {
  const ProgressMetricGridWidget({
    required this.metrics,
    required this.scale,
    super.key,
  });

  final DeckActivityMetrics metrics;
  final ProgressMetricScale scale;

  /// The narrowest a cell may be before the grid folds into one column, at text
  /// scale 1.0.
  ///
  /// **Scaled by the reader's own text setting**, which is the whole point: what
  /// a cell has to hold is a numeral and a word, and both grow with
  /// `textScaler`. Comparing a fixed width against a growing demand is how the
  /// two columns survive on paper and clip on a real device — a run of digits
  /// has no break opportunity, so a cell too narrow does not wrap, it truncates,
  /// and a truncated number is a different number.
  ///
  /// 90 is the width the four words need at scale 1.0 with room for four
  /// figures. At 320dp a cell is 124, so the grid stays two columns for every
  /// normal reader; at scale 2.0 the demand becomes 180 and the grid folds,
  /// which is the right trade — a taller card, and nothing lost.
  // off-grid: a content threshold, not a size: the widest figure the cell must hold at 1.0x
  static const double minimumCellWidth = 90;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cellWidth = (constraints.maxWidth - AppSpacing.lg) / 2;
        final bool isTwoColumn =
            cellWidth >=
            MediaQuery.textScalerOf(context).scale(minimumCellWidth);

        final List<Widget> cells = <Widget>[
          _ActiveCardsMetric(count: metrics.activeCardCount, scale: scale),
          _ActiveDaysMetric(count: metrics.activeDayCount, scale: scale),
          _LearningMetric(count: metrics.learningCardDayCount, scale: scale),
          _ReviewingMetric(count: metrics.reviewingCardDayCount, scale: scale),
        ];

        if (!isTwoColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < cells.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                cells[i],
              ],
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _gridRow(cells[0], cells[1]),
            const SizedBox(height: AppSpacing.sm),
            _gridRow(cells[2], cells[3]),
          ],
        );
      },
    );
  }

  Widget _gridRow(Widget leading, Widget trailing) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: <Widget>[
      Expanded(child: leading),
      const SizedBox(width: AppSpacing.lg),
      Expanded(child: trailing),
    ],
  );
}

/// The numeral's type role. One place decides it, so a panel cell and a row cell
/// cannot drift apart by a rung nobody meant to change.
///
/// **`titleMedium` over `titleSmall`, and both in the body face.** The first
/// spelling used `titleLarge` for the panel, which is a *display*-face rung
/// (`app_typography.dart`) — so the two scales did not differ by a rung, they
/// differed by a typeface, while this file's own comments claimed one anatomy.
/// It also cost width nobody had: at 320dp and text scale 2.0 a cell has about
/// 92dp for its text, a display numeral at 44px fits three digits, and a run of
/// digits has no break opportunity — so a four-figure count did not wrap, it
/// **clipped**, and `1234` rendered as `123`. A truncated word is ugly; a
/// truncated number is a different number.
///
/// The row rung dropping to `titleSmall` fixes a second thing: it used to be
/// `titleMedium`, the same rung and weight as the deck name beside it, so five
/// blocks of type competed and the row's own name did not win.
///
/// **Tabular, the same feature Card Detail's own numeric metrics carry**
/// (`card_metric_widget.dart`'s `CardMetricKind.numeric`): a grid is a column
/// of counts read against each other, and proportional figures let a `1` sit
/// narrower than a `4` on the row below it, so the second column's numeral
/// does not share the first column's left edge it otherwise would.
TextStyle? _numeralStyle(BuildContext context, ProgressMetricScale scale) =>
    (scale == ProgressMetricScale.panel
            ? context.texts.titleMedium
            : context.texts.titleSmall)
        ?.inked(context, AppInk.stated, isTabular: true);

/// One metric: anchor, numeral, word — one shape for all four.
///
/// **Zero is quiet, never wrong.** A window with nothing in it is a normal
/// reading of a normal week, so an empty metric drops to the neutral ink and the
/// muted well: no error role, no warning role, and the glyph keeps its shape so
/// the cell stays recognisable as the same metric.
///
/// **Colour is never the only signal.** Every cell states its number and its word
/// in text; the tint only separates "there is something here" from "there is
/// not", which the numeral already says.
///
/// Each caller wraps this in its own `Semantics` sentence and excludes these
/// visuals, so a screen reader hears each metric once, as a sentence, rather than
/// as a bare number followed by a fragment.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.count,
    required this.word,
    required this.icon,
    required this.tint,
    required this.wellColor,
    required this.scale,
  });

  final int count;
  final String word;
  final IconData icon;
  final AppInk tint;
  final Color wellColor;
  final ProgressMetricScale scale;

  @override
  Widget build(BuildContext context) {
    // Baseline-aligned inside the cell too, so the baseline this cell *reports*
    // to the grid row is the text's alphabetic baseline rather than the icon
    // glyph's — which is exactly the drift the grid's baseline row exists to
    // remove.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        MxMetricWell(icon: icon, tint: tint, wellColor: wellColor),
        const SizedBox(width: AppSpacing.xs),
        // Flexible so the text owns the rest of its fixed-width grid cell: a
        // long word at double scale wraps onto a second line inside the cell
        // instead of overflowing or being ellipsized into a lie.
        Flexible(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: '$count ', style: _numeralStyle(context, scale)),
                TextSpan(
                  text: word,
                  style: context.texts.labelMedium!.inked(
                    context,
                    tint,
                    isEmphasized: count != 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Distinct cards answered in the window (BR-183) — how much of the library was
/// touched.
class _ActiveCardsMetric extends StatelessWidget {
  const _ActiveCardsMetric({required this.count, required this.scale});

  final int count;
  final ProgressMetricScale scale;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final tint = count == 0 ? AppInk.quiet : AppInk.info;

    return Semantics(
      container: true,
      label: context.l10n.progressActiveCardsSemanticLabel(count),
      child: ExcludeSemantics(
        child: _Metric(
          count: count,
          word: context.l10n.progressActiveCardsMetricWord,
          icon: Icons.style_outlined,
          tint: tint,
          wellColor: semantic.surfaceMuted,
          scale: scale,
        ),
      ),
    );
  }
}

/// Distinct local days with at least one answer (BR-183) — how often the person
/// showed up. It wears the streak pair, which is the app's existing vocabulary
/// for time kept rather than work owed.
class _ActiveDaysMetric extends StatelessWidget {
  const _ActiveDaysMetric({required this.count, required this.scale});

  final int count;
  final ProgressMetricScale scale;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final hasDays = count > 0;

    return Semantics(
      container: true,
      label: context.l10n.progressActiveDaysSemanticLabel(count),
      child: ExcludeSemantics(
        child: _Metric(
          count: count,
          word: context.l10n.progressActiveDaysMetricWord,
          icon: Icons.calendar_month_outlined,
          tint: hasDays ? AppInk.onDueContainer : AppInk.quiet,
          wellColor: hasDays ? semantic.streakContainer : semantic.surfaceMuted,
          scale: scale,
        ),
      ),
    );
  }
}

/// Card-days spent on the learning chain (BR-186). The same glyph the deck
/// hero's New metric uses, because it counts work on the same set of cards.
class _LearningMetric extends StatelessWidget {
  const _LearningMetric({required this.count, required this.scale});

  final int count;
  final ProgressMetricScale scale;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final tint = count == 0 ? AppInk.quiet : AppInk.info;

    return Semantics(
      container: true,
      label: context.l10n.progressLearningSemanticLabel(count),
      child: ExcludeSemantics(
        child: _Metric(
          count: count,
          word: context.l10n.progressLearningMetricWord,
          // E5: filled once the count is non-zero, outlined at rest — the same
          // pair the deck hero and Study Home use for this fact.
          icon: count > 0 ? Icons.auto_awesome : Icons.auto_awesome_outlined,
          tint: tint,
          wellColor: semantic.surfaceMuted,
          scale: scale,
        ),
      ),
    );
  }
}

/// Card-days spent reviewing — `scheduled` and `relearning` alike (BR-186).
///
/// Neutral by design: review is the ordinary state of a working schedule, and a
/// colour here would make the everyday half of the partition compete with the
/// half that is actually changing.
class _ReviewingMetric extends StatelessWidget {
  const _ReviewingMetric({required this.count, required this.scale});

  final int count;
  final ProgressMetricScale scale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.l10n.progressReviewingSemanticLabel(count),
      child: ExcludeSemantics(
        child: _Metric(
          count: count,
          word: context.l10n.progressReviewingMetricWord,
          icon: Icons.event_repeat_outlined,
          tint: AppInk.quiet,
          wellColor: context.semanticColors.surfaceMuted,
          scale: scale,
        ),
      ),
    );
  }
}
