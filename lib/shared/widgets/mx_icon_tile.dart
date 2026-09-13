import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import 'mx_icon.dart';

/// The three handoff sizes, each with the glyph step it holds (D4).
enum MxIconTileSize {
  sm(AppSizing.iconTileSm, MxIconSize.xs),
  md(AppSizing.iconTileMd, MxIconSize.sm),
  lg(AppSizing.iconTileLg, MxIconSize.md);

  const MxIconTileSize(this.extent, this.glyph);

  final double extent;
  final MxIconSize glyph;
}

/// Handoff IconTile (section C): the tinted square holding a row's leading
/// glyph. Non-interactive — the row it sits in owns the tap and the label, so
/// the glyph is decorative here and reads nothing.
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    required this.icon,
    this.size = MxIconTileSize.md,
    super.key,
  });

  /// Handoff IconTile's tint: `primary` at 10%.
  ///
  /// **Blended over the card surface, not washed** (design_audit R7). A
  /// translucent fill composites against whatever is behind it at paint
  /// time, so one tint renders as two values. The handoff draws the tile in
  /// rows on a raised card (`surface-raised`, `surfaceContainerLowest`), so
  /// the tint is resolved against that ground: the same pixels there, and one
  /// value everywhere else — the move `app_chip_theme.dart`'s `_tint` makes.
  ///
  /// Public because the approved palette derives the same ground from it
  /// (`test/support/app_palette.dart`): the visual audit's closure rule takes
  /// a declared colour only as an exact token, and a copied 0.10 there would
  /// drift the first time this one moved.
  static const double tintAlpha = 0.10;

  final IconData icon;
  final MxIconTileSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size.extent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            context.colors.primary.withValues(alpha: tintAlpha),
            context.colors.surfaceContainerLowest,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: MxIcon(icon, ink: AppInk.accent, size: size.glyph),
        ),
      ),
    );
  }
}
