import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_icon_size.dart';
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // The wireframe's own W5 box opens with a warning glyph, and the
            // other in-flow error band in this batch
            // (`settings_error_band_widget.dart`) does the same. Two error
            // bands one tap apart that look different are two answers to
            // "what does a problem look like here".
            Icon(
              Icons.error_outline,
              size: AppIconSize.mdCompact,
              color: context.colors.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
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
                      // **`onErrorContainer`, because this button sits on
                      // `errorContainer`.** The default `primaryAccent` is right on
                      // a page and measures 3.72:1 here in dark — under the 4.5 its
                      // 14px w600 label needs. The band's own text already uses this
                      // ink. The sibling band found this first; this one did not get
                      // the fix because it arrived from a branch that predated it.
                      child: MxTextButton(
                        label: context.l10n.reminderRetryAction,
                        onPressed: onRetry,
                        accent: context.colors.onErrorContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
