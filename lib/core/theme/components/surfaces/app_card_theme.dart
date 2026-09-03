import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_stroke.dart';

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
/// * `surfaceContainerLow` — `_CardDefaultsM3.color`, the paper;
/// * `AppElevation.card` with `materialShadowColor`, so Material paints the
///   depth in the mode that has one and nothing in the mode that does not;
/// * no neutral outline **in light**. A page-level card there separates by its
///   surface step and its shadow, not by a decorative frame (M99.94);
/// * a hairline `outlineVariant` side **in dark**, because that mode has no
///   shadow to separate with and the surface step alone is 1.09:1. This is the
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
  color: scheme.surfaceContainerLow,
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
    ? BorderSide(color: scheme.outlineVariant, width: AppStroke.hairline)
    : BorderSide.none;
