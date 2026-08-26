import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_dialog_tone.dart';

/// Asks before an unsaved card edit is thrown away (UC-04 A1).
///
/// **The editor's Close and Android's back gesture ask the same question**, so
/// the question lives in one function rather than being written twice with two
/// sets of words. The bar's `×` used to leave immediately and the gesture used
/// to leave immediately, which meant a typed correction was one stray swipe
/// from gone and nothing on screen had ever said so (owner review, 2026-08-26).
///
/// **`destructive`, so Enter cannot discard.** `MxConfirmDialog` starts focus on
/// cancel for that variant, and cancel here means *keep what I typed* — the
/// safe side of a dialog opened by an accidental gesture in the first place.
///
/// **`warning`, not `error`.** Nothing has failed and nothing stored is at
/// stake: the card on disk is untouched, and only the draft above it is. Tags
/// are untouched too — they are written as they are typed (BR-93), which is
/// why the message speaks about edits rather than about the card.
Future<bool> showCardEditorDiscardConfirm(BuildContext context) {
  final l10n = context.l10n;

  return showMxConfirm(
    context,
    title: l10n.cardEditorDiscardTitle,
    message: l10n.cardEditorDiscardMessage,
    confirmLabel: l10n.cardEditorDiscardConfirmAction,
    // Not `commonCancelAction`: on this dialog both buttons cancel something,
    // so the word "Cancel" answers the wrong question. "Keep editing" says
    // what staying does.
    cancelLabel: l10n.cardEditorKeepEditingAction,
    variant: MxConfirmDialogVariant.destructive,
    tone: MxDialogTone.warning,
  );
}
