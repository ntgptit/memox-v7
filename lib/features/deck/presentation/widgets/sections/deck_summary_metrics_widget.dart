import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';

/// The hero's metric band: one number, its breakdown, and the context row
/// (owner mockup, 2026-08-20).
///
/// **One number, because one question.** The panel used to print the four
/// disjoint sets of BR-162 at near-equal weight, and the owner's review read
/// it the way any table reads: as homework. What the user asks the panel is
/// "how much is waiting", and the answer is overdue + due today in one
/// numeral — the split survives as the subline, red on the overdue half only.
///
/// **New and Scheduled are context, not actions.** They keep no icons, no
/// semantic ink and no tiles of their own: one quiet row, halved by a
/// hairline. With them demoted, overdue red is the single accent left on the
/// card — which is what lets it mean something.
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
    final scheduledCount = snapshot.levelScheduledCardCount;

    // The hero numeral: what is due; a level with nothing due but new cards
    // waiting leads with those instead (BR-150 — new-only is studyable).
    final heroCount = dueCount > 0 ? dueCount : newCount;
    final heroWord = dueCount > 0
        ? context.l10n.deckSummaryCardsDueWord
        : context.l10n.deckHeroNewMetricWord;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          container: true,
          label: dueCount > 0
              ? context.l10n.deckHeroDueTodaySemanticLabel(dueCount)
              : context.l10n.deckHeroNewSemanticLabel(newCount),
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  '$heroCount',
                  style: context.texts.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(heroWord, style: context.texts.titleMedium),
              ],
            ),
          ),
        ),
        // The breakdown, only when there is one to state: with no overdue the
        // subline would repeat the numeral above it in smaller type.
        if (overdueCount > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label: context.l10n.deckHeroOverdueSemanticLabel(
              overdueCount,
              snapshot.levelOverdueDayCount,
            ),
            child: ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: context.l10n.deckSummaryOverduePart(overdueCount),
                      style: context.texts.bodyMedium?.copyWith(
                        color: context.semanticColors.danger,
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
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _QuietContextRow(newCount: newCount, scheduledCount: scheduledCount),
      ],
    );
  }
}

/// New and Scheduled, side by side on a muted inset, split by a hairline.
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
                  word,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
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
        color: context.semanticColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          cell(
            newCount,
            context.l10n.deckHeroNewMetricWord,
            context.l10n.deckHeroNewSemanticLabel(newCount),
          ),
          // A decoration, not `color:`: `Container(color:)` builds a
          // ColoredBox, which the visual audit cannot read a colour from —
          // the DecoratedBox route keeps the hairline auditable.
          Container(
            width: 1,
            height: AppSpacing.lg,
            decoration: BoxDecoration(color: context.colors.outlineVariant),
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
