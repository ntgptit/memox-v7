import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../states/deck_list_view_state.dart';
import '../overlays/deck_sort_sheet_widget.dart';

/// The list's heading and the one control that acts on it.
///
/// **The control lost its container** (owner review, 2026-08-25). It was a pill
/// reading `↑↓ Recently studied`, which measured 149.8px on a 393 screen —
/// **41.5% of the row**, against a heading of 88.6px. A control that outweighs
/// the thing it names has the hierarchy backwards: the heading says what the
/// list is, and the sort is an adjustment to it. What is left is a 20px glyph
/// in the brand ink, right-aligned on the heading's own centre line.
///
/// **The order it is in moved into the sheet.** A glyph cannot say "recently
/// studied", so the sheet ticks the live option and the control's screen-reader
/// label speaks it. That is a real trade — a sighted user now needs one tap to
/// answer "what is this sorted by" where the pill answered it at rest — and it
/// is what buys back the 100px and the visual weight.
///
/// **A sheet, not a cycle.** The pill advanced to the next order on each tap.
/// That is workable at two options and unusable at four (owner decision,
/// 2026-08-25): the order you want ends up one to three taps away, and the list
/// re-sorts under the finger on every one of them.
///
/// Feature-local: it speaks [DeckListSort]. `MxIconButton` is the shared half
/// and knows nothing about decks.
class DeckListToolbarWidget extends StatelessWidget {
  const DeckListToolbarWidget({
    required this.filter,
    required this.sort,
    required this.visibleCount,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.isRootLevel,
    super.key,
  });

  final DeckListFilter filter;
  final DeckListSort sort;
  final ValueChanged<DeckListFilter> onFilterChanged;
  final ValueChanged<DeckListSort> onSortChanged;

  /// Which heading the list gets — the library's, or this deck's children's.
  final bool isRootLevel;

  /// How many decks the list below actually shows, after the filter — the
  /// heading names the list, so it counts what is visible, not the level.
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    // **A `Row` again, where the two pills needed a `Wrap`.** The wrap existed
    // because at `textScaler` 2.0 on a 320 screen two pills could not share a
    // line with the heading and a `Row` overflowed. One 48px control leaves the
    // heading 240 even at that scale, and the heading ellipsizes rather than
    // pushing — which is the right thing to give up first, since the control is
    // the control and the heading only names what it acts on.
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            // **One count per level, and the root's lives in the header.**
            // The header's second line states the root's own totals now
            // (owner review, 2026-08-21), so repeating the figure here would
            // be the redundancy that line was freed of. Inside a deck the
            // header shows the path instead, so the heading keeps it. Middle
            // dot, not parentheses: it reads as part of the label.
            isRootLevel
                ? context.l10n.decksSectionLabelRoot.toUpperCase()
                : '${context.l10n.decksSectionLabelChild.toUpperCase()} · $visibleCount',
            // **`withWeight`, not `copyWith(fontWeight:)`.** The body face is a
            // variable font, and `copyWith` alone moves the declared weight
            // without moving the `wght` axis — it renders at the old weight and
            // says the new one, which is the silent no-op M99.39 found on the
            // study screen's mode chip.
            style:
                AppTypography.withWeight(
                  context.textStyles.sectionLabel,
                  FontWeight.w600,
                ).copyWith(
                  color: context.colors.onSurfaceVariant,
                  letterSpacing: AppTypography.listHeadingTracking,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // **48, and it is the row's whole height.** The design asks for a 32px
        // row; a 32px row and a real 48px target are mutually exclusive, and
        // the trick that appears to give both — a 48 box overflowing a 32 slot
        // — was measured and does not work: `meetsGuideline` passes because it
        // reads the semantics rect, while a tap 4px outside the row is never
        // delivered, because every ancestor hit-test starts with
        // `size.contains`. It would have shipped green and missed on a device.
        // With the pill's container gone the row reads as the 20px glyph and
        // the 12px heading inside it, which is the height the design was after.
        MxIconButton(
          icon: Icons.swap_vert,
          // Glyph at `mdCompact` (20), target untouched at 48.
          isCompact: true,
          // The row's only control, so it is allowed to be the accent.
          isAccent: true,
          // The glyph says "sort"; only this says what it is sorted by. A
          // sighted user reads that off the sheet's tick — a screen reader has
          // no sheet until it opens one, so the state travels with the control.
          semanticLabel: context.l10n.deckSortControlSemanticLabel(
            deckSortLabel(context.l10n, sort),
          ),
          onPressed: () => showDeckSortSheet(
            context,
            current: sort,
            onSelected: onSortChanged,
          ),
        ),
      ],
    );
  }
}
