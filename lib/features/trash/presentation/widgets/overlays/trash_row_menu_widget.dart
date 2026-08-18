import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';

/// The row's overflow menu, holding exactly one action on purpose.
///
/// **Purge stays behind a menu even though it is alone there** (wireframe T6):
/// Restore is the row's trailing button and permanent deletion must cost one
/// tap more — the action that rescues data has to be cheaper than the one
/// that destroys it. A kebab that fired the purge confirmation directly would
/// also be the one `more_vert` in the app that opens no menu, which is how a
/// user learns to distrust the glyph.
Future<void> showTrashRowMenu(
  BuildContext context, {
  required VoidCallback onPurge,
}) async {
  final bool? purge = await showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => MxActionSheet(
      title: sheetContext.l10n.trashRowMenuTitle,
      actions: <MxActionSheetAction>[
        MxActionSheetAction(
          label: sheetContext.l10n.trashPurgeAction,
          icon: Icons.delete_forever_outlined,
          variant: MxActionSheetActionVariant.destructive,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
      ],
    ),
  );
  // The sheet's await is an async gap and `onPurge` re-enters the caller's
  // context to open the confirm dialog — the same guard the deck actions
  // sheet carries for the same shape.
  if (!context.mounted) return;
  if (purge ?? false) onPurge();
}
