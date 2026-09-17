import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Every line the app draws around or inside a component.
///
/// **`borderSubtle` and `borderControl` are v3 literals** from
/// `colors_and_type.css` (2026-09-17, GC-1) — `ColorScheme.outlineVariant` and
/// `.outline` read them directly, so they stay the source rather than a
/// derivation. The other three legacy names (`borderSelected`, `borderOption`,
/// `borderAccent`) are call-site aliases: the first two derive from a role
/// below them, the third is its own v3 formula because no role names it.
abstract final class AppBorderColors {
  /// Hairline between rows, around cards, and an input at rest — feeds
  /// `ColorScheme.outlineVariant`.
  static const Color borderSubtleLight = Color(0xFFC5CBE3);
  static const Color borderSubtleDark = Color(0xFF2A3267);

  /// A control's resting edge (WCAG 1.4.11) — feeds `ColorScheme.outline`.
  static const Color borderControlLight = Color(0xFF7C85AB);
  static const Color borderControlDark = Color(0xFF5A6BAE);

  /// The edge a picked card wears — v3 puts it on `primary`.
  static const Color borderSelectedLight = AppColors.primaryLight;
  static const Color borderSelectedDark = AppColors.primaryDark;

  /// The hairline a panel wears when it is the screen's *answer* rather than
  /// one row among many — v3 `primary-border`: `primary` at 24% (light) / 32%
  /// (dark) over `surfaceContainerLowest`. No role names this tint, so it
  /// stays a literal.
  static const Color borderAccentLight = Color(0xFFD5DAFD);
  static const Color borderAccentDark = Color(0xFF394379);

  /// The resting edge of a selectable card — v3 has one non-brand edge, so
  /// this is [borderControlLight] under its call-site name.
  static const Color borderOptionLight = borderControlLight;
  static const Color borderOptionDark = borderControlDark;
}
