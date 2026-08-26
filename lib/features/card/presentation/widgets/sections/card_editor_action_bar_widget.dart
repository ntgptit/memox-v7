import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';

/// The edit form's pinned footer: one action, and it is the one the screen is
/// for.
///
/// **It exists because `Save changes` used to live in the scroll**, between the
/// optional details and the tag strip. Two things followed from that and both
/// were bugs. It scrolled away — a user editing the tags at the bottom of the
/// form could not see the button that saves the fields at the top — and, sitting
/// above Tags, it implied a *scope*: everything above me is what I save. Tags
/// and the flag write immediately (BR-92, BR-93), so the implication was wrong
/// in the one direction that costs data.
///
/// **Presentation only.** It is handed a label, a callback and two booleans; it
/// decides nothing about whether the form is dirty. That belongs to the screen
/// that owns the controllers, and a footer that computed it would be a second
/// place for the answer to live.
class CardEditorActionBarWidget extends StatelessWidget {
  const CardEditorActionBarWidget({
    required this.label,
    required this.onSave,
    required this.isSaving,
    super.key,
  });

  /// Already-localized.
  final String label;

  /// `null` disables the button — a pristine form, or a save already running.
  final VoidCallback? onSave;

  /// **`isSaving`, not `isLoading`.** This bar holds one action, so a flag
  /// named after the *operation* is the honest name — and a screen-wide
  /// `isLoading` is exactly the shape that cannot say "refreshing while
  /// submitting" once a second operation appears.
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    // **No `SafeArea` here.** The shell puts the footer inside the body's, so a
    // second one would pay for the gesture strip twice; and the keyboard is
    // handled by the body shrinking, not by anything this widget computes.
    return Padding(
      // The same gutter the content column uses, so the button's edges line up
      // with the field edges above it rather than with the screen.
      padding: EdgeInsets.symmetric(
        horizontal: mxScreenGutter(context),
        vertical: AppSpacing.md,
      ),
      child: MxActionButton(
        label: label,
        onPressed: onSave,
        isLoading: isSaving,
      ),
    );
  }
}
