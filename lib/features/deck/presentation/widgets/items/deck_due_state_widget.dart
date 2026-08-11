import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_summary_model.dart';

/// The deck's two workloads as two marks, or quiet text when there are none.
///
/// **Two numbers, never one** (BR-150). New and due are the two disjoint sets of
/// BR-142 and they cost differently — a new card is a whole learning chain, a
/// due card is one review — so a single merged count would hide exactly the
/// fact a learner budgets by. The due chip keeps the filled emphasis it always
/// had; the new count is an outlined chip beside it, present but quieter,
/// because due is the one that expires.
///
/// **Neither mark relies on colour alone.** Each carries an icon and a worded
/// count; the two differ by fill *and* by icon *and* by word, so every pair of
/// eyes and every screen reader gets the distinction.
///
/// **Three resting states, not two.** "No cards yet" and "nothing to study" are
/// different facts and stay separate: one deck has never been filled in, the
/// other is actually finished for today. Collapsing them tells a user who has
/// just created a deck that they are up to date with it.
///
/// The chip is the design's `--color-streak-container`; its label is not the
/// design's `--color-streak`, which measures 3.12:1 on that container at this
/// size. See `AppColors.streakContainerLight`.
/// The chips' own height: a `label-md` line plus `xs` above and below. Stated
/// once so the quiet states can match it without re-deriving the arithmetic.
const double _kDueStateHeight = 24;

class DeckDueStateWidget extends StatelessWidget {
  const DeckDueStateWidget({required this.summary, super.key});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    if (!summary.hasStudyableCards) {
      return _DueStateBox(
        child: Text(
          summary.totalCardCount == 0
              ? context.l10n.deckNoCardsLabel
              : context.l10n.deckNoDueLabel,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return _DueStateBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (summary.hasDueCards)
            Flexible(
              child: _CountChip(
                icon: Icons.schedule,
                label: context.l10n.deckDueNowLabel(summary.dueCardCount),
                fill: semantic.streakContainer,
                ink: semantic.onStreakContainer,
              ),
            ),
          if (summary.hasDueCards && summary.hasNewCards)
            const SizedBox(width: AppSpacing.xs),
          if (summary.hasNewCards)
            Flexible(
              child: _CountChip(
                icon: Icons.fiber_new_outlined,
                label: context.l10n.deckNewCountLabel(summary.newCardCount),
                // An edge rather than a fill: new cards wait indefinitely, so
                // the mark states the fact without competing with the one that
                // expires today.
                outline: semantic.borderControl,
                ink: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// One count as a pill: an icon, a worded number, and either a fill or an edge.
class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.label,
    required this.ink,
    this.fill,
    this.outline,
  }) : assert(
         (fill == null) != (outline == null),
         'a chip is filled or outlined, never both or neither',
       );

  final IconData icon;
  final String label;
  final Color ink;
  final Color? fill;
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final edge = outline;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: edge == null ? null : Border.all(color: edge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppIconSize.sm, color: ink),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: context.texts.labelMedium?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The fixed-height, start-aligned box every resting state sits in.
class _DueStateBox extends StatelessWidget {
  const _DueStateBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _kDueStateHeight,
    child: Align(alignment: AlignmentDirectional.centerStart, child: child),
  );
}
