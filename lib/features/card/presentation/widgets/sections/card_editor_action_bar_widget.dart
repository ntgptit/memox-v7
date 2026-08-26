import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';

/// The edit form's pinned footer: leave, save, and a standing note.
///
/// **It exists because `Save changes` used to live in the scroll**, between the
/// optional details and the tag strip. Two things followed and both were bugs.
/// It scrolled away — a user editing the tags at the bottom of the form could
/// not see the button that saves the fields at the top — and, sitting above
/// Tags, it implied a *scope*: everything above me is what I save. Tags and the
/// flag write immediately (BR-92, BR-93), so the implication was wrong in the
/// one direction that costs data.
///
/// **Save takes the larger share, and nothing here decides by how much.**
/// Cancel is sized to its label and Save fills what is left, which reproduces
/// the concept's proportion at every width and translation — see the comment
/// on the row for the two ratios that were tried and what each got wrong.
///
/// **Presentation only.** It is handed labels, callbacks and two booleans; it
/// decides nothing about whether the form is dirty. That belongs to the screen
/// that owns the controllers, and a footer that computed it would be a second
/// place for the answer to live.
class CardEditorActionBarWidget extends StatelessWidget {
  const CardEditorActionBarWidget({
    required this.onCancel,
    required this.onSave,
    required this.isSaving,
    super.key,
  });

  /// Leaves the editor — through the same coordinator the back arrow and the
  /// system gesture use, so the discard question cannot be answered differently
  /// depending on which one the user reached for.
  final VoidCallback? onCancel;

  /// `null` disables Save — a pristine form, or a save already running.
  final VoidCallback? onSave;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // **`IntrinsicHeight`, because the two labels wrap differently.** At
          // 320dp and text scale 2.0 the Vietnamese `Huỷ` stayed on one line
          // while `Lưu thay đổi` took two — 64 against 104, two buttons at two
          // heights presenting one choice. Stretching both to the taller is the
          // same rule `MxButtonPair` encodes for dialogs.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // **Cancel is sized to its own label; Save takes the rest.**
                // Two attempts preceded this. 3 : 2 came out 1.50 : 1 and made
                // the pair read as near-equals, where the concept plainly
                // treats Cancel as the small way out (it draws 127px against
                // Save's 404). 3 : 1 got the proportion and broke the word —
                // at 390dp `Cancel` wrapped to `Canc / el`, which is what a
                // ratio does when it does not know how wide a label is.
                //
                // Letting the label decide reproduces the concept's shape at
                // every width and translation without a number that can be
                // wrong: Cancel is exactly as wide as the word, and Save is
                // everything left over — which is always the larger share on a
                // phone.
                MxActionButton(
                  label: context.l10n.cardEditorCancelAction,
                  variant: MxActionButtonVariant.secondary,
                  // Not disabled while saving: the way out stays open, the
                  // same rule `MxConfirmDialog` keeps for its cancel. The
                  // exit coordinator is what refuses to leave mid-write, and
                  // it says so by doing nothing rather than by greying the
                  // control the user would reach for if the save hung.
                  onPressed: onCancel,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MxActionButton(
                    label: context.l10n.cardEditorSaveChanges,
                    icon: Icons.check,
                    onPressed: onSave,
                    isLoading: isSaving,
                    // The width is decided from outside, so the label can stay
                    // painted while the spinner runs — this is the one place on
                    // the screen that says a save is happening.
                    shouldKeepLabelWhileLoading: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // **A standing fact, not a status.** It says where the data lives
          // (AD-01, local-first) and it reads the same before, during and after
          // a save. Wiring it to the submit state would turn an answer into a
          // progress message and lose both.
          Text(
            context.l10n.cardEditorLocalOnlyNote,
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
