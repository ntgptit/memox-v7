import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';

/// What the library's overflow chose.
enum _LibraryAction { tagCatalog, trash, toggleDueFilter }

/// The Library bar's one overflow (owner mockup, 2026-08-20).
///
/// The bar leads with search and create; everything a library is *sometimes*
/// used for lives here — the tag catalog (UC-18), Trash, and the due-only
/// view toggle that left the toolbar. Trash's entry moving off the bar
/// amends wireframe T2's "always on the root bar": the recovery surface is
/// still discoverable from the root before anything is deleted, one tap
/// deeper, and the trade is a header that never crowds three targets. The
/// amendment is recorded in the design-parity checklist.
Future<void> showLibraryMenu(
  BuildContext context, {
  required bool isDueFilterActive,
  required VoidCallback onToggleDueFilter,
}) async {
  final action = await showModalBottomSheet<_LibraryAction>(
    context: context,
    builder: (sheetContext) => MxActionSheet(
      title: sheetContext.l10n.libraryActionsTitle,
      actions: <MxActionSheetAction>[
        MxActionSheetAction(
          label: sheetContext.l10n.tagCatalogEntryAction,
          icon: Icons.sell_outlined,
          onPressed: () =>
              Navigator.of(sheetContext).pop(_LibraryAction.tagCatalog),
        ),
        MxActionSheetAction(
          label: sheetContext.l10n.trashEntryLabel,
          icon: Icons.delete_outline,
          onPressed: () => Navigator.of(sheetContext).pop(_LibraryAction.trash),
        ),
        MxActionSheetAction(
          // The label names the state the tap moves to, like every toggle
          // in the app's sheets.
          label: isDueFilterActive
              ? sheetContext.l10n.deckFilterAllLabel
              : sheetContext.l10n.deckFilterDueLabel,
          icon: Icons.filter_list,
          onPressed: () =>
              Navigator.of(sheetContext).pop(_LibraryAction.toggleDueFilter),
        ),
      ],
    ),
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case _LibraryAction.tagCatalog:
      context.goNamed(RouteNames.tagCatalog);
    case _LibraryAction.trash:
      context.goNamed(RouteNames.trash);
    case _LibraryAction.toggleDueFilter:
      onToggleDueFilter();
  }
}
