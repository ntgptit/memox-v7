import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../../domain/failures/reminder_failure.dart';
import '../support/reminder_labels_widget.dart';

/// The in-flow error band of the reminder screen (M6 W5, R5).
///
/// **In the flow, not a snackbar.** A refused permission is a state that lasts
/// until the user changes it in system settings, and a snackbar takes both the
/// explanation and the only recovery away after four seconds — usually while the
/// user is still in the settings app it told them to open.
///
/// **`isRetryable` is read off the label mapping, not re-derived here.** A
/// platform without reminders has no recovery (M6 S7), and a screen that decided
/// that by matching the enum again could grow a retry button for a state that
/// can never change.
class ReminderBannerSectionWidget extends StatelessWidget {
  const ReminderBannerSectionWidget({
    required this.rejection,
    required this.onRetry,
    super.key,
  });

  final ReminderSetupRejection rejection;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final banner = context.reminderBanner(rejection);

    // A live region: the band appears after an action the user took, and a
    // screen reader that does not announce it leaves them with a toggle that
    // silently sprang back (M6 A5).
    return Semantics(
      liveRegion: true,
      child: MxCard(
        color: context.colors.errorContainer,
        // A shadow stacked on a shadow is a rendering fault rather than
        // depth: this banner sits inside a scrolling body of flat cards (D20).
        elevation: AppElevation.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              banner.title,
              style: context.texts.titleSmall?.copyWith(
                color: context.colors.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              banner.message,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onErrorContainer,
              ),
            ),
            if (banner.isRetryable) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: MxTextButton(
                  label: context.l10n.reminderRetryAction,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
