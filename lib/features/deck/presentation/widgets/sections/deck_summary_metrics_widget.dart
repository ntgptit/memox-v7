import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';

/// The hero's figure line (owner mockup, 2026-08-20; compacted 2026-08-25;
/// flattened 2026-09-10).
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
/// **New and Scheduled are gone rather than hidden.** They were the third band
/// of a panel that stood at 38% of the viewport, then spent a year one
/// disclosure away. Neither placement earned them: `new` is a chip on every
/// deck row, and `scheduled` counts the one thing this screen cannot act on —
/// a card due next week is precisely the card today is not about. Overdue red
/// stays the only semantic colour here, which is what lets it mean something.
///
/// **Every number is still arithmetic over the snapshot the screen already
/// has** (AD-13): a child's counts cover its whole subtree and siblings are
/// disjoint, so the level folds are the level's totals — no second read.
class DeckSummaryMetricsWidget extends StatelessWidget {
  const DeckSummaryMetricsWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final overdueCount = snapshot.levelOverdueCardCount;
    final dueCount = snapshot.levelDueCardCount;
    final newCount = snapshot.levelNewCardCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // **The line runs the full width again.** It used to stop 32dp short
        // of the card's right edge, because a 48dp chevron sat in that corner
        // and the overdue split ran under it. With the chevron gone there is
        // nothing to give way to, and the split gets the pixels back — which
        // is what keeps `8 overdue · 7 today` on the numeral's line at 393
        // instead of wrapping under it.
        _HeroFigureLine(
          dueCount: dueCount,
          newCount: newCount,
          overdueCount: overdueCount,
          overdueDayCount: snapshot.levelOverdueDayCount,
        ),
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
  ///
  /// Now the `heroNumeral` role: assembled per-site, its bare
  /// `fontWeight: heroNumeralWeight` was the twelfth instance of the
  /// weight-without-axis bug — the fourth weight was declared and never
  /// painted.
  TextStyle? _numeralStyle(BuildContext context) =>
      context.textStyles.heroNumeral;

  /// BR-162's split as one span: `8 overdue` in the overdue ink, then the rest.
  TextSpan _breakdownSpan(BuildContext context) => TextSpan(
    style: context.texts.bodyMedium!.inked(context, AppInk.quiet),
    children: <InlineSpan>[
      TextSpan(
        text: context.l10n.deckSummaryOverduePart(overdueCount),
        // Through the wght axis — a bare `fontWeight:` paints the rung's
        // old weight.
        style: context.texts.bodyMedium!.inked(
          context,
          AppInk.overdue,
          isEmphasized: true,
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
        // **The numeral is not `Flexible`, and that is load-bearing.**
        // `Flexible` splits the line by *flex*, not by need: two of them at
        // flex 1 each take half, so a 133-wide breakdown beside a 100-wide
        // numeral still ellipsized at 126 even though the fit calculation had
        // already proved both fit together. The numeral takes its own width —
        // `fitsOnOneLine` guarantees there is room — and the breakdown takes
        // what is left.
        _numeral(context, heroCount, heroWord),
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
  ///
  /// **The headline is the Reviewing total, and it used to be announced as
  /// due-today.** `dueCount` is `overdue + dueToday` by BR-162's own identity,
  /// so `deckHeroDueTodaySemanticLabel(dueCount)` told a listener "15 cards due
  /// today" about a figure the same panel splits into 8 overdue and 7 today —
  /// a classification the eye never receives, contradicted one line below by
  /// the panel's own breakdown. The due-today resource keeps its meaning and
  /// keeps its own number; the headline gets a sentence for the sum.
  Widget _numeral(BuildContext context, int heroCount, String heroWord) =>
      Semantics(
        container: true,
        label: dueCount > 0
            ? context.l10n.deckHeroDueTotalSemanticLabel(dueCount)
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
                style: _numeralStyle(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  heroWord,
                  style: context.texts.titleMedium,
                  // **Two, and it costs nothing where one was enough.** The
                  // side-by-side branch is only taken once `fitsOnOneLine` has
                  // proved the whole line fits, so this never wraps there; the
                  // stacked branch is where it matters, and there it was
                  // drawing `cards d…` on a 320dp screen at textScaler 2.0 —
                  // the one corner of the responsive matrix this panel's
                  // clipping guard had never been pointed at (hero audit,
                  // 2026-09-08). Wrapping a two-word unit is not a defect;
                  // ellipsizing it is, because the word is what says *what*
                  // the numeral counts.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  /// `8 overdue · 7 today` — BR-162's split, in one sentence.
  ///
  /// **Both halves, because the visible line has both.** The node announced the
  /// overdue sentence alone, so the `· 7 today` half of the split reached no
  /// listener anywhere on the panel: the headline above it was announcing the
  /// sum. The overdue sentence stays exactly as it was — BR-162 requires the
  /// backlog age to arrive through this resource — and the due-today sentence
  /// is appended with its own count.
  Widget _breakdown(BuildContext context) => Semantics(
    label: context.l10n.deckHeroBreakdownSemanticLabel(
      context.l10n.deckHeroOverdueSemanticLabel(overdueCount, overdueDayCount),
      context.l10n.deckHeroDueTodaySemanticLabel(dueCount - overdueCount),
    ),
    child: ExcludeSemantics(
      child: Text.rich(
        _breakdownSpan(context),
        // Same reason as the unit word above, and a stronger one: this line
        // *is* BR-162's split, so an ellipsis here deletes the half of the
        // panel the split exists to state. Inert on the shared-baseline
        // branch, which is measured to fit before it is chosen.
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
