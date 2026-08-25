import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_stroke.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';

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
    required this.onToggleExpanded,
    super.key,
  });

  final DeckListSnapshot snapshot;

  /// Whether the resting figures are open.
  final bool isExpanded;

  /// Opens or shuts them. The chevron is the panel's only control now — the
  /// dismiss button it replaced is gone (owner decision, 2026-08-25).
  final VoidCallback onToggleExpanded;

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
        Row(
          // **Top-aligned, not centred** (owner review, 2026-08-25). Centring
          // put the 40px figure line in the middle of a row the chevron's 48px
          // target sets the height of, which pushed the numeral 4px further
          // from the card's edge than the padding says it is. `start` gives
          // those 4 back; the chevron fills the row either way.
          //
          // Not `baseline`: the chevron is a 48px target with no text in it,
          // and a baseline cross-alignment asks every child for a baseline it
          // does not have. The figures keep their own baseline inside
          // [_HeroFigureLine].
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _HeroFigureLine(
                dueCount: dueCount,
                newCount: newCount,
                overdueCount: overdueCount,
                overdueDayCount: snapshot.levelOverdueDayCount,
              ),
            ),
            // **A disclosure, not a dismissal.** It pointed down and hid the
            // panel; it now points down to open the resting figures and up to
            // shut them — the arrow shows where the content goes, which is the
            // same rule the old chevron followed for a different content.
            MxIconButton(
              icon: isExpanded ? Icons.expand_less : Icons.expand_more,
              semanticLabel: isExpanded
                  ? context.l10n.deckSummaryCollapseLabel
                  : context.l10n.deckSummaryExpandLabel,
              onPressed: onToggleExpanded,
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    // The hero numeral: what is due; a level with nothing due but new cards
    // waiting leads with those instead (BR-150 — new-only is studyable).
    final heroCount = dueCount > 0 ? dueCount : newCount;
    final heroWord = dueCount > 0
        ? context.l10n.deckSummaryCardsDueWord
        : context.l10n.deckHeroNewMetricWord;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Flexible(
          child: Semantics(
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
                    // **The line box hugs the digits.** The rung's 40/32
                    // leading is right for running text and wrong for a lone
                    // numeral against a card edge: measured on the golden, it
                    // put 32.3px of air above the ink where the padding below
                    // the CTA is 16. Digits have no descenders and take no
                    // diacritics, so this is the one string in the app that
                    // can give its leading up without risking a clipped glyph.
                    //
                    // `height`, not a hand-tuned offset: what is left above
                    // the ink after this is the font's own ascent-above-cap,
                    // which only a font-specific constant could remove — and
                    // that is a magic number tied to a file we can swap.
                    //
                    // `headlineLarge`, one rung down from `displaySmall`
                    // (owner review, 2026-08-25): 36px was set when the
                    // numeral had a row to itself, and 32 is what fits beside
                    // its own breakdown on a 393 screen.
                    style: context.texts.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1,
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
          ),
        ),
        // The breakdown, only when there is one to state: with no overdue it
        // would repeat the numeral beside it in smaller type.
        if (overdueCount > 0) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Semantics(
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
            ),
          ),
        ],
      ],
    );
  }
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
