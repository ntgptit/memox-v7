import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/progress_activity_day_model.dart';

/// Today's total and its two halves (W3, BR-195).
///
/// **Both halves are always on screen, zero included.** Hiding a zero would make
/// the panel change shape between a learning day and a reviewing day, and would
/// leave the reader unable to tell "no reviews today" from "reviews are not
/// shown here".
///
/// **The note under them is not decoration.** The two halves are a partition of
/// distinct cards, so a card met in both modes is counted once, on the Learning
/// side. A reader who assumes otherwise expects the halves to over-sum, and the
/// only place that expectation can be corrected is here.
class ProgressTodayWidget extends StatelessWidget {
  const ProgressTodayWidget({required this.today, super.key});

  final ProgressActivityDay today;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;

    // Flat, like every other card in a scrolling column (M99.26): two
    // competing depths in one column is what makes a list read as busy,
    // which is the reason the deck tile and the Study Home row already
    // gave. Progress was the only surface still taking the default.
    return MxCard.raised(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.progressTodaySectionLabel,
            style: texts.labelLarge!.inked(context, AppInk.quiet),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.progressTodayCardsLabel(today.totalCards),
            style: texts.headlineSmall!.inked(context, AppInk.stated),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProgressTodayBreakdownRow(
            label: context.l10n.progressTodayLearningLabel,
            count: today.learningCards,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ProgressTodayBreakdownRow(
            label: context.l10n.progressTodayReviewingLabel,
            count: today.reviewingCards,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.progressTodayPartitionNote,
            style: texts.bodySmall!.inked(context, AppInk.quiet),
          ),
        ],
      ),
    );
  }
}

/// One half of the breakdown: a name and a number, never a coloured dot alone.
///
/// The two halves are told apart by their words (P5). Colour would be a second
/// signal if it were added, never the first one.
class _ProgressTodayBreakdownRow extends StatelessWidget {
  const _ProgressTodayBreakdownRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;

    return MergeSemantics(
      child: Row(
        children: <Widget>[
          // The label takes the slack and wraps; the figure never does, so the
          // two rows keep their numbers on one vertical line at every text
          // scale.
          Expanded(
            child: Text(
              label,
              style: texts.bodyMedium!.inked(context, AppInk.stated),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$count',
            style: texts.titleMedium!.inked(context, AppInk.stated),
          ),
        ],
      ),
    );
  }
}
