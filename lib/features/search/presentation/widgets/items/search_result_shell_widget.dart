import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_card.dart';

/// The frame every result row shares: the surface, the leading glyph, the
/// trailing "opens elsewhere" arrow, and the tap target.
///
/// **One frame for two row types, so they cannot drift apart.** A deck row and
/// a card row differ in what they say and in nothing else — the same gutter, the
/// same radius, the same 48 floor — and two files drawing that separately is how
/// one of them ends up a pixel out and stays that way.
///
/// **`MxCard`, not a hand-drawn `Material` + `InkWell`.** It was the latter
/// first, with the same `surface` fill, the same `AppRadius.lg` and the same
/// `borderSubtle` edge — a manual copy of the shared card, and it inherited two
/// defects from being one. It had no **focus ring**: the row declares itself a
/// button, this screen is reached with the keyboard already in the field, and a
/// bare `InkWell` falls back to a 10% wash that `AppStateOpacity.focus`'s own
/// documentation measures at ~1.15:1 — below the 3:1 WCAG 1.4.11 asks of a focus
/// indicator. And its press fell back to the theme's splash rather than
/// `AppInteractionStates.cardOverlay`, which is the pressed value the design kit
/// declares for a tappable card. `MxCard` carries both.
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
    return Semantics(
      button: true,
      label: semanticLabel,
      child: MxCard.flat(
        // Flat: this card sits inside a list on the page's own surface, and a
        // shadow per row would make the list read as a stack of sheets.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        onTap: onOpen,
        child: ConstrainedBox(
          // The row is taller than this at every scale that has been measured;
          // the floor is here so a future single-line variant cannot fall under
          // the target a finger needs.
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minimumTouchTarget,
          ),
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MxIcon(icon, size: MxIconSize.sm),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: child),
                const SizedBox(width: AppSpacing.sm),
                const MxIcon(Icons.north_east, size: MxIconSize.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
