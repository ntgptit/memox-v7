import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';

/// The card's leading glyph, in a tinted well.
///
/// Feature-local rather than shared: it exists to give the deck list a scannable
/// left column, and nothing else in the app has asked for one. Promoting it on the
/// first caller would be guessing at what varies — the second caller is what shows
/// whether the tint, the size or the shape is the part worth parameterising.
///
/// Sized to [AppSpacing.minimumTouchTarget] even though it is not a target: it is
/// the one square in the row, and reusing the number the row's real controls use
/// keeps the icon, the title and the action optically aligned.
///
/// **The well is `primaryContainer` and the default glyph is
/// `onPrimaryContainer`** — a Material 3 container pair, chosen because the pair
/// is what carries a contrast guarantee. The first version used `surfaceMuted`
/// with a `primary` glyph, which looked right in light and failed the strict
/// audit in dark at **2.31:1** against a 3.0 floor: `primary` is a fill colour,
/// and nothing promises it is legible *on* another surface. The audit is what
/// caught it, on a screen that had already been looked at.
class DeckIconArea extends StatelessWidget {
  /// The well's square edge — [AppSpacing.minimumTouchTarget], for the optical
  /// reason above.
  ///
  /// Public because the tile aligns other rows to the column this square
  /// creates: the workload line starts at `dimension + AppSpacing.md`, exactly
  /// where the title does. A copy of the number in the tile would drift the
  /// first time this well is resized.
  static const double dimension = AppSpacing.minimumTouchTarget;

  const DeckIconArea({
    required this.icon,
    required this.tint,
    this.semanticLabel,
    this.wellColor,
    super.key,
  });

  final IconData icon;
  final Color tint;
  final String? semanticLabel;

  /// Null keeps the brand container. Pass one only to say the row is in a state
  /// the brand colour would talk over.
  final Color? wellColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wellColor ?? context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: Icon(
            icon,
            size: AppIconSize.md,
            color: tint,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
