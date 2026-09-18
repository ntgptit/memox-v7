import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';

/// The 28dp tinted glyph well that leads an [MxListRow] — and, later,
/// `SettingsRow`'s own leading slot, once that component's task extends it.
///
/// **One size today.** `AppRadius.sm`'s own doc comment already names "icon
/// tile (28dp)" as the v3 Radius table's 8 — this widget is that tile, sized
/// [dimension]. A `md` step belongs to whichever task gives `SettingsRow` its
/// own leading tile; adding an unused second size here would be a guess this
/// component has no second caller to check it against.
///
/// **Two tones, not a theme field.** `primary-soft` — the general "tint
/// primary and box it" token — is deliberately absent from the theme:
/// several components each tint `primary` at their own percentage instead
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.3).
/// This tile's own recipe: the `default` tone tints `primary` at 10% (light)
/// / 16% (dark); the `seeded` tone tints the caller's [seed] at a flat 12% in
/// both themes. Either way the glyph paints in the same source colour at full
/// strength — never a separate derived ink — which is what the spec's "tile
/// TINT, glyph FULL_STRENGTH" pairing means (spec §5.7).
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    required this.icon,
    this.seed,
    this.semanticLabel,
    super.key,
  });

  /// The tile's square edge.
  static const double dimension = 28;

  final IconData icon;

  /// A per-instance colour — a per-deck tint, typically. `null` keeps the
  /// neutral brand-tinted `default` tone. Never stored in the theme: the
  /// caller (`MxListRow.seed`, forwarded unchanged) owns it per instance.
  final Color? seed;

  /// Read by screen readers; `null` excludes the glyph from semantics
  /// entirely — the usual case, since the tile sits beside a title that
  /// already names the row.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = context.colors;
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color source = seed ?? scheme.primary;
    final double tintAlpha = seed != null
        ? _seededTintAlpha
        : (isDark ? _defaultTintDarkAlpha : _defaultTintLightAlpha);
    final Color fill = Color.alphaBlend(
      source.withValues(alpha: tintAlpha),
      scheme.surface,
    );

    final Widget glyph = Icon(
      icon,
      size: AppIconSize.mdCompact,
      color: source,
      semanticLabel: semanticLabel,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Center(
          child: semanticLabel == null ? ExcludeSemantics(child: glyph) : glyph,
        ),
      ),
    );
  }
}

const double _defaultTintLightAlpha = 0.10;
const double _defaultTintDarkAlpha = 0.16;
const double _seededTintAlpha = 0.12;
