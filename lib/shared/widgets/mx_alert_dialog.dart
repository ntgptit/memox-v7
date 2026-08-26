import 'package:flutter/material.dart';

import 'mx_action_button.dart';
import 'mx_dialog_tone.dart';

/// Reports something. It asks nothing, so it has one button.
///
/// **The third dialog shape, and the one that completes the severity
/// taxonomy.** `MxConfirmDialog` asks a question and `MxFormDialog` takes
/// input; both can wear a [MxDialogTone] but neither is *about* its tone. This
/// one is: the whole content is a statement, and how serious that statement is
/// is the first thing the reader needs.
///
/// **It has no caller in this app yet, and that is recorded rather than
/// hidden** (`docs/wbs.md` M99.59). This app reports failures three other ways,
/// each deliberate: a persistent error band with a retry where the failure
/// belongs to a section (wireframe W4), a `SnackBar` where a result is
/// transient and the user should not be stopped, and the confirm dialog's own
/// body where the failure answers the question that dialog just asked (D26).
/// Two candidates were examined and rejected — the bulk-operation result, which
/// is a `SnackBar` because interrupting after a completed action is the
/// interruption Material and NN/g both warn against, and the export failure,
/// which already has a band with a `Try again` the dialog would cover.
///
/// So the first real caller is what should decide the copy, the dismiss label
/// and whether it wants a tone at all. Until then this is the shape, tested and
/// in the catalog, and nothing in `lib/features/` imports it.
class MxAlertDialog extends StatelessWidget {
  const MxAlertDialog({
    required this.title,
    required this.message,
    required this.dismissLabel,
    required this.onDismiss,
    required this.tone,
    super.key,
  });

  /// Already-localized, and complete.
  final String title;
  final String message;
  final String dismissLabel;

  /// Pops. Unlike the confirm dialog there is nothing to wait for — by the time
  /// this is on screen, whatever it reports has already happened.
  final VoidCallback onDismiss;

  /// **Required, not optional.** On the confirm and form dialogs a tone is a
  /// hint about a question the words already ask; here the tone *is* the
  /// message's category, and a caller that has not decided whether it is
  /// reporting a success or a failure has not finished writing the message.
  final MxDialogTone tone;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Scrollable for the same reason as the confirm dialog: at a large text
      // scale on a narrow screen the alternative is silent truncation.
      scrollable: true,
      title: MxDialogHeader(title: title, tone: tone),
      // **Not a live region, and the difference from `MxConfirmDialog` is the
      // point.** There the body changes underneath a dialog that stays open, so
      // a failure arriving after the question needs announcing. Here the
      // message is the reason the dialog exists: `AlertDialog` already names
      // the route and marks its content as a semantics container, so it is read
      // on open. Marking it live as well would announce it twice.
      content: Text(message),
      actions: <Widget>[
        MxActionButton(
          label: dismissLabel,
          onPressed: onDismiss,
          // The only action, and it destroys nothing — so it takes the focus.
          // The rule that keeps focus off a confirm button (`destructive` and
          // `cautious`) is about choosing the *least* destructive of two; with
          // one action, that is this one.
          shouldAutofocus: true,
        ),
      ],
    );
  }
}

/// Shows an [MxAlertDialog] and completes when it is gone.
///
/// Every way out is the same way out — the button, the barrier, the back
/// gesture — so unlike [showMxConfirm] there is no answer to return.
Future<void> showMxAlert(
  BuildContext context, {
  required String title,
  required String message,
  required String dismissLabel,
  required MxDialogTone tone,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => MxAlertDialog(
    title: title,
    message: message,
    dismissLabel: dismissLabel,
    tone: tone,
    onDismiss: () => Navigator.of(dialogContext).pop(),
  ),
);
