import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../items/settings_error_band_widget.dart';

/// Back to every default, and the sentence that says what that does not touch
/// (BR-217, wireframe S5).
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
          style: context.texts.bodySmall!.inked(context, AppInk.quiet),
        ),
        if (band != null) ...<Widget>[
          // **`lg`, the same step the study-defaults band takes** — one widget
          // introduced by three different gaps on one screen says the band is
          // three different kinds of thing. The other two at least follow their
          // own container: the choice card breathes at `sm` and the study card
          // separates its clusters at `lg`. The `md` that used to be here
          // followed nothing — this section's own internal step is `xs` above
          // and `SettingsScreen.sectionGap` is `xl` — and the screen this one
          // links to puts its failure banner under the card it reports on at
          // `lg` too (`reminder_settings_section_widget.dart`).
          const SizedBox(height: AppSpacing.lg),
          SettingsErrorBandWidget(
            failure: band,
            onRetry: isSubmitting ? null : onRetry,
          ),
        ],
      ],
    );
  }
}
