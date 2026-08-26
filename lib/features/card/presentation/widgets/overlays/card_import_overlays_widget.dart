import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_dialog_tone.dart';

/// The dirty-draft confirmation (wireframe W5): shown by Close and Android
/// Back once a source is chosen or the mapping was touched — never for a
/// cancelled file pick, which is not a decision about the draft (I5).
///
/// Returns true only when the user confirmed discarding.
Future<bool> showCardImportDiscardConfirm(BuildContext context) {
  final l10n = context.l10n;

  return showMxConfirm(
    context,
    title: l10n.cardImportDiscardTitle,
    message: l10n.cardImportDiscardMessage,
    confirmLabel: l10n.cardImportDiscardConfirmAction,
    cancelLabel: l10n.commonCancelAction,
    variant: MxConfirmDialogVariant.destructive,
    // A draft, not stored data: warning, not error. The distinction is the
    // whole reason the tone axis is separate from the variant one — this
    // dialog is destructive *and* only a warning.
    tone: MxDialogTone.warning,
  );
}
