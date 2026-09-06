import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
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
///
/// **Nothing new *and* nothing due is a different face, not this one with its
/// numbers set to zero.** Both entries are gone, so what is left is two loose
/// sentences under a readout row whose largest type spends itself saying
/// "New 0" — the app's loudest element stating an absence. `MxEmptyState` is
/// the face the rest of the app gives a dead end, and like `trash_screen.dart`
/// and `progress_deck_screen.dart` this one carries no action: the way out is
/// the app bar, and a button here would be a second one.
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

    // Before the counts row, because at (0, 0) the row is the problem: it is
    // the only thing left at `titleMedium` and it says nothing. Deliberately
    // action-free — see the class doc.
    if (summary.newCount == 0 && summary.dueCount == 0) {
      return MxEmptyState(
        title: l10n.studyEntryAllCaughtUpTitle,
        message: l10n.studyNothingDueMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // **A `Wrap`, because a `Row` of two unconstrained `Text`s cannot
        // break** (SC-C7-05). There was no `Flexible`, no `maxLines` and no
        // second run, so at the size the project promises to fit the pair
        // simply painted overflow stripes across the screen's primary content:
        // measured on this section at `textScaler` 2.0, Vietnamese overflowed
        // by 7.9px at 360dp with three-digit counts, 51px with four, 18px at
        // 393dp and 91px at 320dp. English fits in every one of those cells,
        // which is why nobody saw it — `Mới {count}` and `Đến hạn {count}` are
        // longer than `New` and `Due`, and these counts aggregate a whole deck
        // subtree, so four figures is an ordinary number for somebody who has
        // been away.
        //
        // `lg` keeps the gap the row already had — it is the item gap, and
        // these are two items. The three siblings that solved the same problem
        // reached for `Wrap` too: `study_home_workload_item_widget.dart`,
        // `progress_metric_widget.dart` and `deck_workload_line_widget.dart`.
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            // Plain text, not a disabled pill. A first draft used
            // `MxPillButton(onPressed: null)` for the shape, and the visual
            // audit refused it: a disabled control renders its label at 38%
            // alpha, which is not a palette colour — and these are readouts,
            // not controls somebody is being stopped from pressing.
            //
            // `maxLines: 2` rather than none: a count that clips mid-numeral
            // does not read as truncated, it reads as a different number
            // (`progress_metric_widget.dart` records measuring exactly that).
            Text(
              l10n.studyNewCount(summary.newCount),
              style: context.texts.titleMedium,
              maxLines: 2,
            ),
            Text(
              l10n.studyDueCount(summary.dueCount),
              style: context.texts.titleMedium,
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (summary.newCount > 0)
          MxActionButton(label: l10n.studyStartLearning, onPressed: onLearn)
        else
          Text(l10n.studyNothingNewMessage),
        // `sm`, the gap `study_resume_widget.dart` already stacks these same
        // two labels at. It was `md`, which `app_spacing.dart` reserves for the
        // inside of a compact control — so one dismiss apart, on the same
        // route, `Learn new` and `Review` sat 12 apart here and 8 apart there
        // (SC-C2-12). A stacked action group gets one gap.
        const SizedBox(height: AppSpacing.sm),
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
