import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_dialog_tone.dart';

/// Asks before leaving the card editor with work that has not been written
/// (UC-04 A1).
///
/// **A `showX` returning a bool, not a controller.** Nothing is being mutated —
/// the question is entirely about the widget tree the user is standing in — so
/// the async-confirm machinery `showCardDeleteConfirm` needs would be a
/// controller with nothing to control.
///
/// **`destructive` and `warning`, which is not the same thing said twice.** The
/// variant decides where focus starts: on `Keep editing`, so a stray Enter on a
/// keyboard cannot throw away the draft. The tone decides what the header says
/// about severity — losing unsaved text is serious and *has not happened yet*,
/// which is precisely `warning`. `error` would be a claim that something
/// already failed.
///
/// Copy is its own, not Deck's or Import's. Those say what *they* lose; this
/// one also has to say what it does **not** lose, because tags and the flag on
/// this very screen are already written (BR-92, BR-93) and a user who reads
/// "unsaved changes will be lost" has no way to know the tag they just added is
/// safe.
Future<bool> showCardEditorDiscardConfirm(BuildContext context) =>
    showMxConfirm(
      context,
      title: context.l10n.cardEditorDiscardTitle,
      message: context.l10n.cardEditorDiscardMessage,
      confirmLabel: context.l10n.cardEditorDiscardConfirm,
      cancelLabel: context.l10n.cardEditorDiscardCancel,
      variant: MxConfirmDialogVariant.destructive,
      tone: MxDialogTone.warning,
    );
