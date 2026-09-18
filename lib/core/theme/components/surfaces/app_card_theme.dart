import 'package:flutter/material.dart';

import '../../foundations/app_decorations.dart';
import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';

/// The safety net for a bare or third-party `Card` — no app widget renders
/// one. `MxCard` is the canonical card and paints itself, because its focus
/// ring and `shadowsFor` depth have no `CardThemeData` slot; this keeps an
/// untended `Card` in the app's own language instead of Material's default.
///
/// **An ordinary *elevated* card, which it was not until M100.33.** It carried
/// `elevation: 0` plus an `outlineVariant` hairline — the recipe for
/// `Card.outlined`, wearing the fill of the elevated one. So a bare `Card`
/// degraded into a flat framed panel while every `MxCard.raised` beside it was
/// a borderless surface with a soft shadow: two card languages in one app, and
/// the one nobody renders was the odd one.
///
/// It now degrades toward `MxCard.raised`:
///
/// * `surfaceContainerLowest` — v3's `surface-raised`, the raised paper.
///   **Not `_CardDefaultsM3.color`, which is `surfaceContainerLow`**: the v3
///   ladder moved the raised rung one step, so the SDK default now names
///   this app's *muted* surface (M100.99);
/// * `AppElevation.card` with `materialShadowColor`, so Material paints the
///   depth in the mode that has one and nothing in the mode that does not;
/// * no neutral outline **in light**. A page-level card there separates by its
///   surface step and its shadow, not by a decorative frame (M99.94);
/// * a `border-ghost` hairline **in dark** (`AppDecorations.hairlineEdge`),
///   because that mode has no shadow to separate with. **It is much fainter
///   than the `outlineVariant` it replaces:** `primary` at 16% over the new
///   `#131A3A` fill composites to `#262E5A`, 1.31:1 against that fill where
///   `outlineVariant` gave a crisp step. v3 asks for the ghost by name and
///   the owner took that trade knowingly (M100.99). This is the
///   same cue `MxCard` paints there (`_darkDepth`) — drawn on the shape rather
///   than as a ring outside it, which is the difference between a widget that
///   composes its own layers and a `CardThemeData` slot. §5 of the M100.35
///   brief asks these two to read as one product, not to share an
///   implementation;
/// * `AppRadius.lg`, **not** M3's 12. Material owns the colour roles; memox
///   owns its structural shape scale, and 16 is what an ordinary card wears
///   here.
///
/// `margin: zero` because inter-card spacing belongs to the screen's layout,
/// which is the one place that knows what sits between two cards.
CardThemeData buildCardTheme(ColorScheme scheme) => CardThemeData(
  color: scheme.surfaceContainerLowest,
  shadowColor: materialShadowColor(scheme),
  elevation: AppElevation.card,
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    side: _neutralSide(scheme),
  ),
);

/// The hairline a bare `Card` wears in dark, and nothing in light.
///
/// A function rather than a ternary in the argument: `BorderSide.none` *is*
/// `RoundedRectangleBorder`'s default, so written inline the analyzer reads the
/// light branch as a redundant argument and is right to.
BorderSide _neutralSide(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark
    // Stated rather than defaulted, and the redundancy is the point: the
    // width is one *because the stroke scale says a hairline is one*, not
    // because `BorderSide` happens to agree today.
    // ignore: avoid_redundant_argument_values
    ? AppDecorations.hairlineEdge(scheme)
    : BorderSide.none;
