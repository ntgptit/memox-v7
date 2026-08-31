import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_sheet.dart';
import '../../states/deck_list_view_state.dart';

/// The word for one order, in the language the sheet is being read in.
///
/// **A function on the enum's behalf, not a field on the enum.** A `DeckListSort`
/// that carried its own label would carry English into a value the domain layer
/// can hold, and the ARB lookup needs a `BuildContext` the enum has no business
/// owning. Public because the control on the heading row paints and announces
/// the same word the sheet ticks — two spellings of one fact is how a screen
/// reader and a sighted user end up disagreeing about what the list is sorted
/// by.
///
/// **One vocabulary, since the labels stopped lying.** There was a second, short
/// set for the heading row, and it existed for exactly one string: *Recently
/// studied* did not fit 96px. That string was a false claim about the sort and
/// is now *Date added*, which does fit — so the short set went with it. The one
/// order that still would not fit is Vietnamese `cardsDue`, and the shorter
/// phrasing is simply what that ARB entry carries.
String deckSortLabel(AppLocalizations l10n, DeckListSort sort) =>
    switch (sort) {
      DeckListSort.manual => l10n.deckSortManualLabel,
      DeckListSort.dateAdded => l10n.deckSortRecentLabel,
      DeckListSort.name => l10n.deckSortNameLabel,
      DeckListSort.cardsDue => l10n.deckSortCardsDueLabel,
      DeckListSort.progress => l10n.deckSortProgressLabel,
    };

/// The glyph beside each order in the sheet.
///
/// Decorative — the label is what is announced. It exists because four rows of
/// bare text read as a paragraph, and the eye needs somewhere to land while it
/// scans for the one it wants.
IconData _iconFor(DeckListSort sort) => switch (sort) {
  DeckListSort.manual => Icons.reorder,
  DeckListSort.dateAdded => Icons.schedule,
  DeckListSort.name => Icons.sort_by_alpha,
  DeckListSort.cardsDue => Icons.event_available,
  DeckListSort.progress => Icons.donut_small,
};

/// Chooses the deck list's order (owner decision, 2026-08-25).
///
/// **A sheet, not a control that cycles.** The heading row used to carry a pill
/// that advanced to the next order on each tap, which is workable at two options
/// and unusable at four: the order you want is between one and three taps away,
/// and the list re-sorts under you on every one of them. A sheet shows every
/// option at once, ticks the one in force, and re-sorts once.
///
/// **The tick is the only place the current order is written now.** The control
/// that opens this sheet paints a glyph and nothing else, so if this sheet did
/// not say which order is live, nothing on the screen would.
Future<void> showDeckSortSheet(
  BuildContext context, {
  required DeckListSort current,
  required ValueChanged<DeckListSort> onSelected,
}) async {
  final chosen = await showModalBottomSheet<DeckListSort>(
    context: context,
    builder: (sheetContext) => MxActionSheet(
      title: sheetContext.l10n.deckSortSheetTitle,
      actions: <MxActionSheetAction>[
        for (final sort in DeckListSort.values)
          MxActionSheetAction(
            label: deckSortLabel(sheetContext.l10n, sort),
            icon: _iconFor(sort),
            isSelected: sort == current,
            onPressed: () => Navigator.of(sheetContext).pop(sort),
          ),
      ],
    ),
  );

  // Dismissed, or the row already in force: re-emitting the current order would
  // rebuild the list to the arrangement it is already in.
  if (!context.mounted || chosen == null || chosen == current) return;

  onSelected(chosen);
}
