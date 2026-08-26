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
    required this.isLoading,
    super.key,
  });

  /// Already-localized.
  final String label;

  /// `null` disables the button — a pristine form, or a save already running.
  final VoidCallback? onSave;

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // `top: false`: the bar is at the bottom of the screen, so the only inset
    // it can owe is the gesture strip. `Scaffold` puts it above the keyboard
    // and takes its height out of the body, so nothing here computes an inset.
    return SafeArea(
      top: false,
      child: Padding(
        // The same gutter the content column uses, so the button's edges line
        // up with the field edges above it rather than with the screen.
        padding: EdgeInsets.fromLTRB(
          mxScreenGutter(context),
          AppSpacing.md,
          mxScreenGutter(context),
          AppSpacing.md,
        ),
        child: MxActionButton(
          label: label,
          onPressed: onSave,
          isLoading: isLoading,
        ),
      ),
    );
  }
}
