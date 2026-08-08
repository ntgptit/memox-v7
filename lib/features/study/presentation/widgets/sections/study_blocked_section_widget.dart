import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';

/// A stage that could not build content for the card on screen (BR-124).
///
/// **It says what did not happen.** No turn was recorded and the card keeps its
/// place — without that sentence a blocked stage reads as work lost, which is
/// the opposite of what the rule protects.
///
/// The only action is leaving, and that is deliberate: BR-124 forbids skipping
/// the card, so there is nowhere forward to offer. A button that pretended
/// otherwise would have to break the rule to do anything.
class StudyBlockedSectionWidget extends StatelessWidget {
  const StudyBlockedSectionWidget({required this.onLeave, super.key});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Text(
        context.l10n.studyStageBlockedTitle,
        style: context.texts.titleMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        context.l10n.studyStageBlockedBody,
        style: context.texts.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      MxActionButton(
        label: context.l10n.studyLeaveSession,
        onPressed: onLeave,
        variant: MxActionButtonVariant.secondary,
      ),
    ],
  );
}
