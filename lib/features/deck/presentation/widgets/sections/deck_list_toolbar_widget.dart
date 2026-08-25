import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../states/deck_list_view_state.dart';
import '../overlays/deck_sort_sheet_widget.dart';

/// The list's heading and the one control that acts on it.
///
/// **The control lost its container** (owner review, 2026-08-25). It was a pill
/// reading `↑↓ Recently studied`, which measured 149.8px on a 393 screen —
/// **41.5% of the row**, against a heading of 88.6px. A control that outweighs
/// the thing it names has the hierarchy backwards: the heading says what the
/// list is, and the sort is an adjustment to it. What is left is one word and
/// a 16px glyph in the brand ink, right-aligned on the heading's own centre
/// line — under 96px, against the pill's 149.8.
///
/// **The label came back, the container did not** (owner review, 2026-08-25,
/// second pass). The first pass took the pill down to a bare `swap_vert` glyph
/// and moved the order it is in into the sheet — 48px, but a glyph says
/// "sort" and cannot say "sorted by what", which is the half a user actually
/// needs. The order is painted again, in the short form the row has space for,
/// with the glyph trailing it. That is `MxTextButton`, not a pill: flat, no
/// container, brand ink, `label-md` so it sits on the heading's own rung
/// instead of a size above it.
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
    // line with the heading and a `Row` overflowed. One control under 96px
    // leaves the heading room even at that scale, and the heading ellipsizes
    // rather than pushing — the right thing to give up first, since the control
    // is the control and the heading only names what it acts on.
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
        // **48 tall, and it is the row's whole height.** The design asks for a
        // 32px row; a 32px row and a real 48px target are mutually exclusive,
        // and the trick that appears to give both — a 48 box overflowing a 32
        // slot — was measured and does not work: `meetsGuideline` passes
        // because it reads the semantics rect, while a tap 4px outside the row
        // is never delivered, because every ancestor hit-test starts with
        // `size.contains`. It would have shipped green and missed on a device.
        // With the pill's container gone the row reads as one 12px word, one
        // 16px glyph and the heading, which is the weight the design was after.
        MxTextButton(
          // The order it is in, in the short form — `Recent`, not `Recently
          // studied`, which does not fit the room a heading row has.
          label: deckSortShortLabel(context.l10n, sort),
          // Trailing, because the word is the fact and the glyph is what marks
          // it pressable. Leading, the eye met an arrow before it met an
          // answer.
          trailingIcon: Icons.swap_vert,
          // `label-md`, the heading's own rung. A `TextButton` takes `label-lg`
          // from Material, and a control set larger than the thing it names is
          // the defect this row was rebuilt to fix.
          isCompact: true,
          // The painted word is a value, not an action. A reader hearing
          // "Recent, button" is told a word and not what pressing it does; the
          // announcement contains the painted label rather than replacing it.
          semanticLabel: context.l10n.deckSortControlSemanticLabel(
            deckSortShortLabel(context.l10n, sort),
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
