import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pill_button.dart';
import '../../states/deck_list_view_state.dart';

/// The root list's view controls: which decks, and in what order.
///
/// **Two pills, and both do something.** The reference this screen was designed
/// against shows a row of four — search, a filter sheet, a sort menu, a profile
/// avatar. Three of those have no behaviour in this build, and a control that
/// looks live and does nothing is worse than an emptier toolbar: the user pays
/// attention to it once and learns to distrust the row. So the toolbar carries
/// exactly the two switches that are real.
///
/// Both are toggles rather than menus. With two options each, a menu costs a tap
/// and a frame to say what a label already says — and the label doubles as the
/// answer to "what am I looking at", which a menu hides until opened.
///
/// Feature-local: it speaks [DeckListFilter] and [DeckListSort]. `MxPillButton`
/// is the shared half and knows neither.
class DeckListToolbarWidget extends StatelessWidget {
  const DeckListToolbarWidget({
    required this.filter,
    required this.sort,
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

  @override
  Widget build(BuildContext context) {
    final isDueOnly = filter == DeckListFilter.due;
    final isByName = sort == DeckListSort.name;

    // Wrap, not Row: at `textScaler` 2.0 on a 320-wide screen the two pills do
    // not fit side by side, and a Row would overflow rather than stack.
    // **Label left, pills hard right.** The design gives the heading `flex: 1`
    // so the two controls sit at the end of the row rather than trailing the
    // words. A `Row` with an `Expanded` heading is that, and the heading
    // ellipsizes rather than clipping when the row runs out — the right thing
    // to give up first, since the pills are the controls and the heading only
    // names what they act on.
    // **Heading left, pills hard right — and it has to survive 320 at
    // textScaler 2.0.** The design gives the heading `flex: 1` so the controls
    // sit at the end of the row. A `Row` with an `Expanded` heading is exactly
    // that, and it overflowed at the compact size: the heading ellipsizes, but
    // the two pills together are already wider than the screen once the text
    // doubles.
    //
    // A `Wrap` holding the heading and a second `Wrap` of the pills is both. On
    // one line `spaceBetween` pushes the pills to the end; when they no longer
    // fit, the group drops to its own line, and if the two cannot share even
    // that, the inner `Wrap` breaks them apart as well.
    //
    // The heading itself: without it the two pills float above the cards with
    // nothing saying what they filter, and "Your decks" against "Sub-decks" is
    // the one place besides the app-bar title where the screen says which level
    // the user is on.
    return Wrap(
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            (isRootLevel
                    ? context.l10n.decksSectionLabelRoot
                    : context.l10n.decksSectionLabelChild)
                .toUpperCase(),
            // **`label-md`, not `label-sm`.** The heading and the two pills read
            // as one row, and the pills carry a container while the heading is
            // bare text — so at 11 against their 12 the heading looked like a
            // caption for controls rather than the title of the list they filter.
            // Same rung now; the pills still lead on weight of surface, which is
            // the right order for a label and a control.
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              letterSpacing: AppTypography.sectionLabelTracking,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            MxPillButton(
              label: isDueOnly
                  ? context.l10n.deckFilterDueLabel
                  : context.l10n.deckFilterAllLabel,
              icon: Icons.filter_list,
              isSelected: isDueOnly,
              semanticLabel: isDueOnly
                  ? context.l10n.deckFilterDueSemanticLabel
                  : context.l10n.deckFilterAllSemanticLabel,
              onPressed: () => onFilterChanged(
                isDueOnly ? DeckListFilter.all : DeckListFilter.due,
              ),
            ),
            MxPillButton(
              label: isByName
                  ? context.l10n.deckSortNameLabel
                  : context.l10n.deckSortRecentLabel,
              icon: Icons.swap_vert,
              isSelected: isByName,
              // `A-Z` is two letters to a screen reader. The expansion is what
              // gets announced; the abbreviation is what gets read.
              semanticLabel: isByName
                  ? context.l10n.deckSortNameSemanticLabel
                  : context.l10n.deckSortRecentSemanticLabel,
              onPressed: () => onSortChanged(
                isByName ? DeckListSort.recent : DeckListSort.name,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
