import 'package:flutter/material.dart';

import 'mx_action_button.dart';

/// Whether the confirmed action destroys something.
///
/// An enum rather than an `isDestructive` flag beside a colour: a flag and a
/// colour can be passed independently, and a caller that sets one without the
/// other produces a dialog that looks safe and is not.
enum MxConfirmDialogVariant {
  /// Reversible, or harmless.
  normal,

  /// Deletes or discards. Styled as destructive, and — more importantly — not
  /// the initially focused control.
  destructive,
}

/// Asks the user to confirm one action.
///
/// **It counts nothing.** M4.10 deletes a deck and knows it is taking four
/// sub-decks and eleven cards with it; that sentence is built there, already
/// localized and already pluralised, and arrives here as [message]. A shared
/// dialog that knew about decks could not be used for anything else, and a
/// shared dialog that did its own pluralisation would do it in one language.
///
/// **It does not close itself.** The caller pops the route in its callback,
/// after the work either succeeded or failed. A dialog that dismissed on tap
/// would unmount [isSubmitting] before it could ever be shown, and the user
/// would see the screen behind it while the delete was still running.
class MxConfirmDialog extends StatelessWidget {
  const MxConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.variant = MxConfirmDialogVariant.normal,
    this.isSubmitting = false,
    super.key,
  });

  /// Already-localized, and complete. See the class doc.
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  final MxConfirmDialogVariant variant;

  /// While true both actions are inert. Confirming a delete twice sends two
  /// deletes, and the second one fails against data the first already removed —
  /// which surfaces to the user as an error for an action that worked.
  final bool isSubmitting;

  bool get _isDestructive => variant == MxConfirmDialogVariant.destructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Scrollable because the alternative is silent truncation, not an error.
      // At textScaler 3.0 on a 320-wide screen a translated message clips
      // mid-word inside the content box: no exception, no overflow stripe,
      // nothing a passing widget test would notice — and the user confirms a
      // delete having read half the sentence describing it.
      scrollable: true,
      title: Text(title),
      content: Text(message),
      // `OverflowBar` stacks the actions vertically when they no longer fit
      // side by side, which is what happens on a 320-wide screen at
      // textScaler 2.0. Left in Material's hands rather than reimplemented.
      actions: <Widget>[
        MxActionButton(
          label: cancelLabel,
          onPressed: isSubmitting ? null : onCancel,
          variant: MxActionButtonVariant.secondary,
          // Focus starts on cancel for a destructive dialog, so a stray Enter
          // does not delete anything. On a normal dialog neither action is
          // autofocused: pre-selecting "confirm" makes the keyboard path skip
          // the question the dialog exists to ask.
          shouldAutofocus: _isDestructive,
        ),
        MxActionButton(
          label: confirmLabel,
          onPressed: isSubmitting ? null : onConfirm,
          variant: _isDestructive
              ? MxActionButtonVariant.destructive
              : MxActionButtonVariant.primary,
          isLoading: isSubmitting,
        ),
      ],
    );
  }
}
