import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/deck_summary_model.dart';

/// A filled chip when something is waiting; quiet text when nothing is.
///
/// **One height for all three states.** The chip pads itself and the text does
/// not, so a list mixing them stepped 120 / 112 / 100 down the column — three
/// card heights for what is one row of information, and a scrolling rhythm that
/// visibly stutters. The box is the chip's height; the text sits inside it.
///
/// **Three states, not two.** "Nothing due" and "no cards yet" are different
/// facts and the design separates them: one deck is finished for today, the
/// other has never been filled in. Collapsing them tells a user who has just
/// created a deck that they are up to date with it.
///
/// The chip is the design's `--color-streak-container`; its label is not the
/// design's `--color-streak`, which measures 3.12:1 on that container at this
/// size. See `AppColors.streakContainerLight`.
/// The chip's own height: a `label-md` line plus `xs` above and below. Stated
/// once so the quiet states can match it without re-deriving the arithmetic.
const double _kDueStateHeight = 24;

class DeckDueStateWidget extends StatelessWidget {
  const DeckDueStateWidget({required this.summary, super.key});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    if (!summary.hasDueCards) {
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: semantic.streakContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.schedule,
                size: AppIconSize.sm,
                color: semantic.onStreakContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  context.l10n.deckDueNowLabel(summary.dueCardCount),
                  style: context.texts.labelMedium?.copyWith(
                    color: semantic.onStreakContainer,
                    fontWeight: FontWeight.w600,
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
  }
}

/// The fixed-height, start-aligned box both states sit in.
class _DueStateBox extends StatelessWidget {
  const _DueStateBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _kDueStateHeight,
    child: Align(alignment: AlignmentDirectional.centerStart, child: child),
  );
}
