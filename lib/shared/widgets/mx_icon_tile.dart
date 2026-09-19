import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_icon_size.dart';
import '../../core/theme/foundations/app_radius.dart';

/// The three fixed geometries `MxIconTile` paints — box, corner radius and
/// glyph size, one rung per row context the v3 registry names it for.
///
/// Box values have no shared ladder entry (`AppRadius.sm`'s own doc already
/// names 28dp as the icon-tile pairing, but nothing declares the box itself);
/// they are owned here, the same way `DeckIconArea.dimension` and
/// `MxIconSize` each hold a widget-local dimension rather than growing
/// `AppSizing` a rung only one caller uses.
enum MxIconTileSize {
  /// 28 box · radius 8 — content rows, move targets.
  sm(box: 28, radius: AppRadius.sm, glyphSize: AppIconSize.sm),

  /// 36 box · radius 12 — settings rows, sheet commands.
  md(box: 36, radius: AppRadius.md, glyphSize: AppIconSize.mdCompact),

  /// 44 box · radius 12 — deck rows, at every depth.
  lg(box: 44, radius: AppRadius.md, glyphSize: AppIconSize.mdCompact);

  const MxIconTileSize({
    required this.box,
    required this.radius,
    required this.glyphSize,
  });

  final double box;
  final double radius;
  final double glyphSize;
}

/// The tinted square that leads a row: [ListRow]'s and [SettingsRow]'s
/// leading visual (once those exist), and the deck row's icon well at
/// [MxIconTileSize.lg].
///
/// **A surface, not a control** — no interaction state, no touch target of
/// its own; the row around it owns tapping. **Never shrinks**: it is always
/// [SizedBox.square]-sized to [MxIconTileSize.box], and the caller's row
/// gives the *text* column the flexible space instead.
///
/// **Two tint variants, not a theme role each.** `primary` at 10% light /
/// 16% dark is the default; a caller-supplied [seed] (a per-deck colour,
/// never a theme field — `seed` is `COMPONENT_INPUT`) replaces it at a flat
/// 12% in both themes. Composited via `Color.alphaBlend` against
/// [ColorScheme.surface] rather than left translucent: a bare
/// `.withValues(alpha:)` on a background element trips rule R7 the moment
/// the file is not `app_elevation.dart`/`app_decorations.dart` — the R7
/// argument is precisely this widget's situation (composed on an unknown
/// caller ground) — so the ground is chosen once, here, rather than left to
/// whatever is behind the row at paint time.
///
/// **The glyph bypasses `AppInk` on purpose.** `AppInk.accent` is
/// `accentInk`, a contrast-lightened value distinct from `ColorScheme.primary`
/// — this component's glyph is bound to the M3 role directly, and a `seed`
/// glyph is a genuinely computed colour with no name to give it, the same
/// exception `mx_pill_button.dart` already carries
/// (`test/app/icon_ink_boundary_test.dart`'s `allowedInKit`).
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    this.icon,
    this.child,
    this.size = MxIconTileSize.md,
    this.seed,
    this.semanticLabel,
    super.key,
  }) : assert(
         (icon == null) != (child == null),
         'Provide exactly one of icon or child: the glyph slot cannot be '
         'empty, and a custom child already owns its own styling — a second '
         'icon would be a second, conflicting glyph.',
       );

  /// The glyph, coloured and sized by this tile. Mutually exclusive with
  /// [child].
  final IconData? icon;

  /// A caller-supplied replacement for the glyph — a letter, a count, a
  /// donut — centred in the tile with no colour applied by this widget.
  /// Mutually exclusive with [icon].
  final Widget? child;

  final MxIconTileSize size;

  /// A per-deck colour that replaces the default `primary` tint. Never a
  /// theme field — this is the caller's to pass per instance.
  final Color? seed;

  /// Read by screen readers when [icon] carries meaning of its own; null
  /// (the default) excludes the glyph from semantics, matching [MxIcon]'s
  /// rule that a glyph beside a label already saying the thing stays silent.
  /// Ignored when [child] is given — the child speaks for itself.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color tintSource = seed ?? scheme.primary;
    final double tintAlpha = seed != null
        ? _seedTintAlpha
        : (scheme.brightness == Brightness.dark
              ? _defaultTintAlphaDark
              : _defaultTintAlphaLight);
    final Color tileColor = Color.alphaBlend(
      tintSource.withValues(alpha: tintAlpha),
      scheme.surface,
    );

    return SizedBox.square(
      dimension: size.box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(size.radius),
        ),
        child: Center(child: child ?? _glyph(tintSource)),
      ),
    );
  }

  Widget _glyph(Color color) {
    final Widget rendered = Icon(
      icon,
      size: size.glyphSize,
      color: color,
      semanticLabel: semanticLabel,
    );
    if (semanticLabel != null) return rendered;

    return ExcludeSemantics(child: rendered);
  }
}

/// `IconTile.default.tile` — `primary` TINT 10% light / 16% dark
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md:354).
const double _defaultTintAlphaLight = 0.10;
const double _defaultTintAlphaDark = 0.16;

/// `seed … tile TINT 12%` — flat across both themes
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md:209).
const double _seedTintAlpha = 0.12;
