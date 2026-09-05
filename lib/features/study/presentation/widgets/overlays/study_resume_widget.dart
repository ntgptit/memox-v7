import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_sheet_insets.dart';

/// Which of the three paths the user took (BR-103).
///
/// An enum rather than a nullable pair of booleans: the sheet can also be
/// dismissed, and "dismissed" has to be distinguishable from "chose to continue"
/// — one leaves the session untouched and showing, the other opens it.
enum StudyResumeChoice { resume, learn, review }

/// The three ways forward when a session from today is still open (BR-103).
///
/// **All three are offered, and none is preselected.** The rule is that the user
/// is not forced back into a session they walked away from — an app that resumes
/// automatically honours the letter of "the session survived" and none of the
/// intent. Learning that starting fresh ends the open one belongs here, before
/// the tap, not in a toast afterwards.
class StudyResumeWidget extends StatelessWidget {
  const StudyResumeWidget({required this.onChoice, super.key});

  final ValueChanged<StudyResumeChoice> onChoice;

  /// **Scrollable, and the bottom inset is the sheet's own.**
  ///
  /// A modal sheet is capped at a fraction of the screen, and this is the
  /// longest body paragraph of the three study sheets: the title, that
  /// paragraph and three full-width buttons overflow at 320dp long before a
  /// large text scale, which paints `Review` off the bottom with no way to
  /// reach it. Same shape and same fix as the mode and direction choosers, and
  /// like them it does not change the layout wherever the content already fits.
  @override
  Widget build(BuildContext context) => MxSheetInsets(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The sheet's title announces as a header (A20.1 P1-01, §23 #17).
          Semantics(
            header: true,
            child: Text(
              context.l10n.studyResumeTitle,
              style: context.texts.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.studyResumeBody, style: context.texts.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          MxActionButton(
            label: context.l10n.studyResumeContinue,
            onPressed: () => onChoice(StudyResumeChoice.resume),
          ),
          const SizedBox(height: AppSpacing.sm),
          MxActionButton(
            label: context.l10n.studyStartLearning,
            onPressed: () => onChoice(StudyResumeChoice.learn),
            variant: MxActionButtonVariant.secondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          MxActionButton(
            label: context.l10n.studyStartReview,
            onPressed: () => onChoice(StudyResumeChoice.review),
            variant: MxActionButtonVariant.secondary,
          ),
        ],
      ),
    ),
  );
}
