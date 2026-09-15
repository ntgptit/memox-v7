import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/mx_text_button.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_list_sort_model.dart';
import '../../controllers/card_list_filter_controller.dart';
import '../overlays/card_sort_sheet_widget.dart';

/// Picks the sort (D3).
///
/// A free function, not a closure in `build()`: `ref.read` inside a build reads
/// without subscribing and is the bug the guard forbids, so the command is
/// written where the guard can tell it apart — the shape `_growWindow` and
/// `_selectFilter` already use.
void _selectSort(WidgetRef ref, String deckId, CardListSort sort) =>
    ref.read(cardListSortSelectionProvider(deckId).notifier).select(sort);

/// The card list's sort control, sitting opposite the "showing N of M" line.
///
/// **A link over a sheet, which is how the deck list's heading row already
/// chooses an order** (SC-C4-13). This row used to open an `MxMenuButton` with
/// a trailing `expand_more`, so the same act — choose the order of a list — had
/// two mechanisms and two shapes one tap apart. The deck side carries three
/// recorded owner-review passes, including the one that put the glyph *before*
/// the label; the card side is the one that moved.
///
/// **Still not a second pill row.** The filters own the row of pills above, and
/// a second row would double the chrome over the list and make two different
/// controls look like one set — the argument this control was built on, and it
/// is untouched: a sheet adds nothing above the list, and the order in force is
/// still painted here rather than hidden behind the control.
///
/// **`label-md`, and it is a rung above the line it sits beside.** The count
/// line is `sectionLabelSmall`; a `TextButton` takes `label-lg` from Material,
/// which is the hierarchy the deck toolbar was rebuilt to fix, so `isCompact`
/// brings it down to the deck control's rung. Landing one rung above the count
/// line rather than on it is the accepted cost of one shape across the two
/// lists: the count is a detail, the sort is the control.
///
/// The 48 target is the theme's — `buildTextButtonTheme` sets the height floor,
/// so the box the finger gets is no longer this widget's to hand-build.
class CardSortControlWidget extends ConsumerWidget {
  const CardSortControlWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(cardListSortSelectionProvider(deckId));
    // The order it is in, in the same words the sheet ticks — one vocabulary,
    // so a reader and a sighted user cannot end up disagreeing about it.
    final label = cardSortOptionLabel(context.l10n, active);

    return MxTextButton(
      label: label,
      // **Leading, because the glyph names the axis rather than disclosing
      // anything.** `expand_more` in the trailing seat said "a menu opens
      // here"; `swap_vert` in that seat would read as an arrow belonging to
      // nothing. Leading, the pair reads as one phrase — "sort: newest".
      icon: Icons.swap_vert,
      isCompact: true,
      // The painted word is a value, not an action: a reader hearing "Newest,
      // button" is told a word and not what pressing it does. The announcement
      // contains the painted label rather than replacing it (WCAG 2.5.3).
      semanticLabel: context.l10n.cardSortControlSemanticLabel(label),
      onPressed: () => showCardSortSheet(
        context,
        current: active,
        onSelected: (sort) => _selectSort(ref, deckId, sort),
      ),
    );
  }
}
