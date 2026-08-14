import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../items/settings_error_band_widget.dart';

/// Back to every default, and the sentence that says what that does not touch
/// (BR-189, wireframe S5).
///
/// **`danger` as a label, not as a fill.** A red block at the foot of every
/// settings screen drags the eye downwards and reads as an error the app is
/// reporting rather than an action the user may take —
/// `test/design_preview/settings_preview_test.dart` settled that idiom before
/// this screen existed.
///
/// **The description is on screen at rest, not only inside the confirmation.**
/// This app has two actions whose name begins with "Reset", and the other one
/// clears every card's schedule (BR-42). A user who has to open a dialog to
/// find out which one this is has already been made to gamble.
///
/// No card: the two groups above are choices with state, and this is one
/// action. Putting it in a third card would give it the same weight as them.
class SettingsResetSectionWidget extends StatelessWidget {
  const SettingsResetSectionWidget({
    required this.isSubmitting,
    required this.onReset,
    this.failure,
    this.onRetry,
    super.key,
  });

  final bool isSubmitting;
  final VoidCallback onReset;
  final Failure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final band = failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxTextButton(
            label: l10n.settingsResetAction,
            icon: Icons.restart_alt,
            isDestructive: true,
            onPressed: isSubmitting ? null : onReset,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.settingsResetDescription,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (band != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          SettingsErrorBandWidget(
            failure: band,
            onRetry: isSubmitting ? null : onRetry,
          ),
        ],
      ],
    );
  }
}
