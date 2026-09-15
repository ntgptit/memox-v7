import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_button_pair.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';

/// The create form's pinned footer: save, and save-and-add-another (UC-04 A4).
///
/// **It exists for the reason the edit bar does, one step earlier.** Create
/// autofocuses its front field, so the keyboard is up on the first frame and
/// the body has already shrunk; with the pair at the end of the scroll the
/// screen's primary action was off screen before the user typed anything. The
/// same command is now placed the same way in both modes.
///
/// **Same rhythm as `CardEditorActionBarWidget`** — the screen gutter across
/// and [AppSpacing.md] down — because the two bands are one anatomy drawn on
/// two modes of one screen, and a footer with its own numbers is how the two
/// drift apart.
///
/// It carries no standing note: `Changes save to this device only.` is edit's
/// copy, and adding it here would be a copy decision rather than a layout one.
///
/// **Presentation only.** Labels, callbacks and one boolean; the screen owns
/// the controllers whose text a save reads, so nothing here decides whether a
/// save may run.
class CardCreateActionBarWidget extends StatelessWidget {
  const CardCreateActionBarWidget({
    required this.onSave,
    required this.onSaveAndAdd,
    required this.isSaving,
    super.key,
  });

  /// `null` disables Save — a save already running.
  final VoidCallback? onSave;

  /// Saves and keeps the form open for the next card (UC-04 A4).
  final VoidCallback? onSaveAndAdd;

  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    // **No `SafeArea` here.** The shell puts the footer inside the body's, so a
    // second one would pay for the gesture strip twice; and the keyboard is
    // handled by the body shrinking, not by anything this widget computes.
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mxScreenGutter(context),
        vertical: AppSpacing.md,
      ),
      // Same-size pair, one row when the labels fit: the two dispositions are
      // one choice, and stacked full-width buttons spent a row of the form for
      // it (owner ask, 2026-08-28).
      child: MxButtonPair(
        primary: MxActionButton(
          label: context.l10n.cardEditorSave,
          onPressed: onSave,
          isLoading: isSaving,
        ),
        secondary: MxActionButton(
          label: context.l10n.cardEditorSaveAndAdd,
          variant: MxActionButtonVariant.secondary,
          onPressed: onSaveAndAdd,
        ),
      ),
    );
  }
}
