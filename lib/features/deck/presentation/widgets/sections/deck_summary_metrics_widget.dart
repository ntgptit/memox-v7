import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_metric_well.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../items/deck_overdue_badge_widget.dart';

/// The hero's metric band: the four disjoint sets of BR-162, most-urgent
/// first, as an explicit 2×2 grid — two rows of two `Expanded` cells, each
/// row aligned on the alphabetic baseline. Together the four cells sum to
/// every card the level holds.
///
/// Split from `deck_level_summary_widget.dart` at the 400-line guard, and the
/// seam is real: the panel owns the card, the header and the progress band;
/// this file owns what a metric *is* — the shared anatomy, the per-set roles,
/// and the emphasis rule that gives the row exactly one focal point.
///
/// **The emphasis rule lives here, next to the widgets it drives** (BR-162):
/// the most urgent non-empty set leads — a missed backlog first, today's
/// reviews next, waiting new cards last. Scheduled never leads: a resting
/// card asks for nothing. A caught-up level has nothing to shout, so
/// everything rests quiet. Order never changes; only weight does.
class DeckSummaryMetricsWidget extends StatelessWidget {
  const DeckSummaryMetricsWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final overdueCount = snapshot.levelOverdueCardCount;
    final dueTodayCount = snapshot.levelDueTodayCardCount;
    final newCount = snapshot.levelNewCardCount;
    final isOverduePrimary = overdueCount > 0;
    final isDueTodayPrimary = overdueCount == 0 && dueTodayCount > 0;
    final isNewPrimary = snapshot.levelDueCardCount == 0 && newCount > 0;

    // A real two-column grid: `Expanded` halves, so `Due today` above
    // `Scheduled` share a left edge whatever the overdue cell happens to say
    // — intrinsic sizing was tried and the aged overdue word pushed its
    // row's second column out of line with the row below.
    //
    // **Each row aligns on the text baseline, not the top.** The two cells
    // of a row can carry different type roles — a primary `headlineMedium`
    // numeral beside a supporting `titleLarge` one — and a top-aligned row
    // then hangs the taller line box's baseline below its neighbour's: the
    // figures read as jittering, not as one line. Baseline alignment is the
    // structural fix; a padding nudge would only hold for one font scale
    // and one locale. Inside a cell the text wraps rather than ellipsizing,
    // so 320px at double scale grows the row instead of losing figures.
    Widget row(Widget leading, Widget trailing) => Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Expanded(child: leading),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: trailing),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        row(
          _OverdueSummaryMetric(
            count: overdueCount,
            overdueDayCount: snapshot.levelOverdueDayCount,
            isPrimary: isOverduePrimary,
          ),
          _DueTodaySummaryMetric(
            count: dueTodayCount,
            isPrimary: isDueTodayPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        row(
          _NewSummaryMetric(count: newCount, isPrimary: isNewPrimary),
          _ScheduledSummaryMetric(count: snapshot.levelScheduledCardCount),
        ),
      ],
    );
  }
}

/// The numeral of a metric: `onSurface` at hero or supporting size.
///
/// One place decides what "primary" means so the two metrics cannot drift:
/// the leading workload speaks at `headlineMedium`, the supporting one at
/// `titleLarge`, and a zero in a caught-up panel rests at the supporting size
/// too — nothing is shouted when nothing is waiting.
TextStyle? _numeralStyle(BuildContext context, {required bool isPrimary}) =>
    (isPrimary ? context.texts.headlineMedium : context.texts.titleLarge)
        ?.copyWith(color: context.colors.onSurface);

/// One hero metric: anchor, numeral, word — one shape for all four sets, so
/// only the glyph, the semantic fill and the emphasis differ (BR-162).
///
/// Each caller wraps this in its own `Semantics` sentence and excludes these
/// visuals, so a screen reader hears every metric exactly once and never the
/// shorthand.
class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.count,
    required this.word,
    required this.icon,
    required this.tint,
    required this.wellColor,
    required this.wordInk,
    required this.isPrimary,
  });

  final int count;
  final String word;
  final IconData icon;
  final Color tint;
  final Color wellColor;
  final Color wordInk;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    // Baseline-aligned inside the cell too, so the baseline this cell
    // *reports* to the grid row is the text's alphabetic baseline. A
    // centre-aligned row reports its first child's baseline instead — the
    // icon glyph's, at a height that depends on the cell's own line box —
    // which is exactly the drift the grid's baseline row exists to remove.
    // The well rides the same baseline, so its geometry stays identical
    // across cells whatever type role the numeral speaks.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        MxMetricWell(icon: icon, tint: tint, wellColor: wellColor),
        const SizedBox(width: AppSpacing.xs),
        // Flexible so the text owns the rest of its fixed-width grid cell:
        // a long word — `Overdue (+7d)` at double scale — wraps onto a
        // second line inside the cell instead of overflowing or being
        // ellipsized into a lie.
        Flexible(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$count ',
                  style: _numeralStyle(context, isPrimary: isPrimary),
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
          ),
        ),
      ],
    );
  }
}

/// The hero's first metric: cards whose day has passed (BR-162).
///
/// The missed calendar keeps its glyph at zero — the shape is the metric's
/// identity — and only wears the error pair while a backlog exists. The age
/// of the oldest backlog card rides the word in parentheses — `Overdue (+7d)`
/// — not as a chip: it is a different unit from the count and must not read
/// as one number, and a chip beside one grid cell is what broke the column
/// alignment. Capped at the same day the tile's badge caps
/// ([DeckOverdueBadgeWidget.capAt]), so the two forms never disagree.
class _OverdueSummaryMetric extends StatelessWidget {
  const _OverdueSummaryMetric({
    required this.count,
    required this.overdueDayCount,
    required this.isPrimary,
  });

  final int count;
  final int overdueDayCount;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final hasBacklog = count > 0;
    final word = !hasBacklog
        ? context.l10n.deckHeroOverdueMetricWord
        : overdueDayCount >= DeckOverdueBadgeWidget.capAt
        ? context.l10n.deckHeroOverdueAgedCapMetricWord
        : context.l10n.deckHeroOverdueAgedMetricWord(overdueDayCount);

    return Semantics(
      container: true,
      label: context.l10n.deckHeroOverdueSemanticLabel(count, overdueDayCount),
      child: ExcludeSemantics(
        child: _HeroMetric(
          count: count,
          word: word,
          // E5: outlined at rest, filled when there is a backlog. It was filled
          // unconditionally, so a deck with nothing overdue still wore the
          // solid crossed-out calendar.
          icon: hasBacklog ? Icons.event_busy : Icons.event_busy_outlined,
          tint: hasBacklog
              ? context.colors.onErrorContainer
              : context.colors.onSurfaceVariant,
          wellColor: hasBacklog
              ? context.colors.errorContainer
              : semantic.surfaceMuted,
          wordInk: hasBacklog
              ? context.colors.error
              : context.colors.onSurfaceVariant,
          isPrimary: isPrimary,
        ),
      ),
    );
  }
}

/// The hero's second metric: reviews that came due on today's local calendar
/// day (BR-162) — actionable and entirely normal, so it wears the streak
/// time-pressure pair, never a warning role.
class _DueTodaySummaryMetric extends StatelessWidget {
  const _DueTodaySummaryMetric({required this.count, required this.isPrimary});

  final int count;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final hasDue = count > 0;

    return Semantics(
      container: true,
      label: context.l10n.deckHeroDueTodaySemanticLabel(count),
      child: ExcludeSemantics(
        child: _HeroMetric(
          count: count,
          word: context.l10n.deckHeroDueTodayMetricWord,
          icon: hasDue ? Icons.event : Icons.event_outlined,
          tint: hasDue
              ? semantic.onStreakContainer
              : context.colors.onSurfaceVariant,
          wellColor: hasDue ? semantic.streakContainer : semantic.surfaceMuted,
          wordInk: hasDue
              ? semantic.onStreakContainer
              : context.colors.onSurfaceVariant,
          isPrimary: isPrimary,
        ),
      ),
    );
  }
}

/// The hero's fourth metric: learned cards resting until a future review
/// (BR-162) — the set with nothing to do, stated so the other three have a
/// denominator.
///
/// **Never primary and never coloured.** A resting card is the schedule
/// working; giving this figure a role or the headline would dress "no action
/// needed" as a call to action. The available-calendar glyph carries the
/// meaning, the neutral ink keeps it quiet.
class _ScheduledSummaryMetric extends StatelessWidget {
  const _ScheduledSummaryMetric({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.l10n.deckHeroScheduledSemanticLabel(count),
      child: ExcludeSemantics(
        child: _HeroMetric(
          count: count,
          word: context.l10n.deckHeroScheduledMetricWord,
          icon: Icons.event_available_outlined,
          tint: context.colors.onSurfaceVariant,
          wellColor: context.semanticColors.surfaceMuted,
          wordInk: context.colors.onSurfaceVariant,
          isPrimary: false,
        ),
      ),
    );
  }
}

/// The hero's third metric: cards still on the learning chain (BR-150).
///
/// Anchored like the other two — same well, same geometry — and quiet on the
/// muted neutral: New is work that waits, not work that expires, and only the
/// glyph and the `info` ink carry that.
class _NewSummaryMetric extends StatelessWidget {
  const _NewSummaryMetric({required this.count, required this.isPrimary});

  final int count;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final hasNew = count > 0;
    final ink = hasNew ? semantic.info : context.colors.onSurfaceVariant;

    return Semantics(
      container: true,
      label: context.l10n.deckHeroNewSemanticLabel(count),
      child: ExcludeSemantics(
        child: _HeroMetric(
          count: count,
          word: context.l10n.deckHeroNewMetricWord,
          // E5 again, the other way round: outlined at rest **and** when there
          // is work, so new cards never got the filled glyph the other two
          // metrics use to say "something is here".
          icon: count > 0 ? Icons.auto_awesome : Icons.auto_awesome_outlined,
          tint: ink,
          wellColor: semantic.surfaceMuted,
          wordInk: ink,
          isPrimary: isPrimary,
        ),
      ),
    );
  }
}
