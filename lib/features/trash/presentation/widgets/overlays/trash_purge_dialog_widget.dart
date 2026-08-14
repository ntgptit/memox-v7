import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';

/// The strong confirmation permanent deletion requires (BR-192, wireframe T11).
///
/// Three things the rule asks for, and all three are here rather than in the
/// caller: the **exact count**, the sentence that says the study history goes
/// with it, and `MxConfirmDialogVariant.destructive` — which is what puts the
/// initial focus on Cancel. A dialog that opened focused on the destructive
/// control would make Enter a way to lose data.
///
/// Returns true only if the user confirmed; dismissing any other way is a no.
Future<bool> showTrashPurgeDialog(
  BuildContext context, {
  required int count,
}) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => MxConfirmDialog(
      title: l10n.trashPurgeConfirmTitle(count),
      message: l10n.trashPurgeConfirmMessage,
      confirmLabel: l10n.trashPurgeConfirmAction,
      cancelLabel: l10n.trashPurgeCancelAction,
      variant: MxConfirmDialogVariant.destructive,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );

  return confirmed ?? false;
}
