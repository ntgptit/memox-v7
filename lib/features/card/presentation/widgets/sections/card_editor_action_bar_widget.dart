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
/// **Save takes the larger share, and the ratio is a flex rather than a
/// number.** The concept draws Cancel about half of Save's width; two flex
/// factors reproduce that at every text scale, where a pair of pixel widths
/// would be right at one and clipped at the rest.
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

  /// Cancel's share of the row against Save's. The concept's proportion, kept
  /// as a ratio so it survives translation and text scale.
  static const int _cancelFlex = 2;
  static const int _saveFlex = 3;

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
          Row(
            children: <Widget>[
              Expanded(
                flex: _cancelFlex,
                child: MxActionButton(
                  label: context.l10n.cardEditorCancelAction,
                  variant: MxActionButtonVariant.secondary,
                  // Not disabled while saving: the way out stays open, the same
                  // rule `MxConfirmDialog` keeps for its cancel. The exit
                  // coordinator is what refuses to leave mid-write, and it says
                  // so by doing nothing rather than by greying the control the
                  // user would reach for if the save hung.
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: _saveFlex,
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
