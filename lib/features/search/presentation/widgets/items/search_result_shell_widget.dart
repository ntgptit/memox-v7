import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_icon_tile.dart';
import '../../../../../shared/widgets/mx_pressable.dart';

/// The frame every result row shares: the leading tile, the trailing chevron,
/// and the tap target — a handoff ListRow on its section's card.
///
/// **`chevron_right`, not `north_east`.** The trailing glyph was `north_east`,
/// and it was the app's only one — the mark that conventionally says "this
/// leaves here". Neither destination does: the deck row makes the same
/// `pushNamed(RouteNames.deckDetail, ...)` call the deck list makes, so one
/// route wore two affordances depending on which list it was reached from.
/// `chevron_right` is what the rest of the app says for "there is a screen
/// behind this" — the progress deck row, the settings reminder entry and the
/// card editor's context row all use it, and `card_editor_details_widget.dart`
/// states the rule outright.
///
/// **One frame for two row types, so they cannot drift apart.** A deck row and
/// a card row differ in what they say and in nothing else — the same inset, the
/// same tile, the same 48 floor — and two files drawing that separately is how
/// one of them ends up a pixel out and stays that way.
///
/// **A row on its section's card, not a card per row** (M100.91). Each result
/// was its own `MxCard`, `lg` apart; the handoff groups a section's results on
/// one surface with a hairline between rows, so the section owns the card
/// (`library_search_body_widget.dart`) and this owns the row. The focus ring
/// the card carried comes from `MxPressable`'s `MxFocusRing` now — the shared
/// indicator, where a bare `InkWell`'s 10% wash measures ~1.15:1 against the
/// 3:1 WCAG 1.4.11 asks of a focus indicator.
class SearchResultShellWidget extends StatelessWidget {
  const SearchResultShellWidget({
    required this.icon,
    required this.semanticLabel,
    required this.onOpen,
    required this.child,
    super.key,
  });

  final IconData icon;

  /// Already-localized, and it carries the whole row: the group, the kind, the
  /// text and the path. The children are wrapped in [ExcludeSemantics] so a
  /// screen reader reads this once rather than reading four fragments in layout
  /// order.
  final String semanticLabel;

  final VoidCallback onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // **One node** (A20.1 P2-17). The label used to sit on a `Semantics`
    // *above* the card while the tap lived on the card's own ink node below
    // it, so the node that takes the tap had no name — the labelled-target
    // guideline reads the node with the action, not its parent. Merging
    // folds the name onto the tap.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: MxPressable(
          onTap: onOpen,
          shape: MxPressableShape.none,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizing.rowMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: ExcludeSemantics(
                child: Row(
                  children: <Widget>[
                    // `sm`: with the 16 inset and 12 gap the text lands on
                    // the 56 hairline its section card draws (UI audit P2).
                    MxIconTile(icon: icon, size: MxIconTileSize.sm),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: child),
                    const SizedBox(width: AppSpacing.sm),
                    const MxIcon(Icons.chevron_right, size: MxIconSize.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
