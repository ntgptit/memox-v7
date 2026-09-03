import 'package:flutter/material.dart';

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
/// * `surfaceContainerLow` — `_CardDefaultsM3.color`, the paper;
/// * `AppElevation.card` with `materialShadowColor`, so Material paints the
///   depth in the mode that has one and nothing in the mode that does not;
/// * no neutral outline. A page-level card separates by its surface step and
///   its shadow, not by a decorative frame (M99.94);
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
  ),
);
