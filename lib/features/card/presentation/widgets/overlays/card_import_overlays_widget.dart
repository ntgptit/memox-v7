import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';

/// The dirty-draft confirmation (wireframe W5): shown by Close and Android
/// Back once a source is chosen or the mapping was touched — never for a
/// cancelled file pick, which is not a decision about the draft (I5).
///
/// Returns true only when the user confirmed discarding.
Future<bool> showCardImportDiscardConfirm(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => MxConfirmDialog(
      title: dialogContext.l10n.cardImportDiscardTitle,
      message: dialogContext.l10n.cardImportDiscardMessage,
      confirmLabel: dialogContext.l10n.cardImportDiscardConfirmAction,
      cancelLabel: dialogContext.l10n.commonCancelAction,
      variant: MxConfirmDialogVariant.destructive,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );

  return confirmed ?? false;
}
