import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../domain/models/study_entry_summary_model.dart';

/// The way into a deck's study flow: two numbers, and up to two ways in.
///
/// **Two numbers, never one** (BR-150). The sets have very different costs — a
/// new card walks five stages, a due one takes a single turn — so a combined
/// total tells the user nothing about what the next ten minutes will be like.
/// Since v5 they are disjoint by shape, which is what lets them be read side by
/// side without either double-counting a card.
///
/// **Nothing due means no way in, and that is a normal screen** (BR-29, BR-145).
/// Studying ahead is a rule rather than a missing feature, so the review button
/// is absent with an explanation rather than present and refusing.
class StudyEntrySectionWidget extends StatelessWidget {
  const StudyEntrySectionWidget({
    required this.summary,
    required this.onLearn,
    required this.onReview,
    super.key,
  });

  final StudyEntrySummaryModel summary;
  final VoidCallback onLearn;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Plain text, not a disabled pill. A first draft used
            // `MxPillButton(onPressed: null)` for the shape, and the visual
            // audit refused it: a disabled control renders its label at 38%
            // alpha, which is not a palette colour — and these are readouts,
            // not controls somebody is being stopped from pressing.
            Text(
              l10n.studyNewCount(summary.newCount),
              style: context.texts.titleMedium,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              l10n.studyDueCount(summary.dueCount),
              style: context.texts.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (summary.newCount > 0)
          MxActionButton(label: l10n.studyStartLearning, onPressed: onLearn)
        else
          Text(l10n.studyNothingNewMessage),
        const SizedBox(height: AppSpacing.md),
        if (summary.dueCount > 0)
          MxActionButton(
            label: l10n.studyStartReview,
            onPressed: onReview,
            variant: MxActionButtonVariant.secondary,
          )
        else
          Text(l10n.studyNothingDueMessage),
      ],
    );
  }
}
