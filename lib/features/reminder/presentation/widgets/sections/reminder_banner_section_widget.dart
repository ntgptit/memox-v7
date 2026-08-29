import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/failures/reminder_failure.dart';
import '../support/reminder_labels_widget.dart';
import '../../../../../shared/widgets/mx_feedback_band.dart';

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
    return MxFeedbackBand(
      title: banner.title,
      message: banner.message,
      actionLabel: banner.isRetryable ? context.l10n.retryAction : null,
      onAction: banner.isRetryable ? onRetry : null,
    );
  }
}
