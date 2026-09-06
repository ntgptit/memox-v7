import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../../../../shared/widgets/mx_sheet.dart';
import '../../../domain/models/card_list_sort_model.dart';

/// The word for one card order, in the language the sheet is being read in.
///
/// **A function on the enum's behalf, not a field on the enum** — the shape
/// `deckSortLabel` already takes, for the same two reasons: a [CardListSort]
/// carrying its own label would carry English into a value the domain layer
/// holds, and the ARB lookup needs a `BuildContext` the enum has no business
/// owning. Public because the control on the count row paints and announces the
/// same word this sheet ticks; two spellings of one fact is how a screen reader
/// and a sighted user end up disagreeing about what the list is sorted by.
String cardSortOptionLabel(AppLocalizations l10n, CardListSort sort) =>
    switch (sort) {
      CardListSort.newest => l10n.cardSortNewest,
      CardListSort.dueFirst => l10n.cardSortDueFirst,
    };

/// The glyph beside each order in the sheet.
///
/// Decorative — the label is what is announced. It exists for the reason the
/// deck sheet's does: rows of bare text read as a paragraph, and the eye needs
/// somewhere to land while it scans for the one it wants. Both glyphs are the
/// deck sheet's own, because the two orders mean there what they mean here —
/// one glyph per meaning, across the two lists.
IconData _iconFor(CardListSort sort) => switch (sort) {
  CardListSort.newest => Icons.schedule,
  CardListSort.dueFirst => Icons.event_available,
};

/// Chooses the card list's order (D3).
///
/// **A sheet, so the two lists choose an order the same way** (SC-C4-13). The
/// count row used to open an `MxMenuButton` while the deck list's heading row
/// opened this shape — one act, two mechanisms, one tap apart. The deck side is
/// the reviewed one (owner reviews, 2026-08-25), so the card side moved.
///
/// This does not contradict what the control used to argue against, which was a
/// *second pill row* beside the filters: a sheet adds no chrome above the list
/// at all, and it shows every order at once, ticks the one in force, and
/// re-sorts once.
Future<void> showCardSortSheet(
  BuildContext context, {
  required CardListSort current,
  required ValueChanged<CardListSort> onSelected,
}) async {
  final chosen = await showMxSheet<CardListSort>(
    context,
    builder: (sheetContext) => MxActionSheet(
      title: sheetContext.l10n.cardSortSheetTitle,
      actions: <MxActionSheetAction>[
        for (final sort in CardListSort.values)
          MxActionSheetAction(
            label: cardSortOptionLabel(sheetContext.l10n, sort),
            icon: _iconFor(sort),
            isSelected: sort == current,
            onPressed: () => Navigator.of(sheetContext).pop(sort),
          ),
      ],
    ),
  );

  // Dismissed, or the row already in force: re-emitting the current order would
  // rebuild the list to the arrangement it is already in — and on this list it
  // would cost more than a rebuild, because every order change resets the
  // window a reader may have grown to 150 rows.
  if (!context.mounted || chosen == null || chosen == current) return;

  onSelected(chosen);
}
