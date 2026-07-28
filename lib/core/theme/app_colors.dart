import 'package:flutter/material.dart';

/// Colour tokens.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// **Source: Radix Colors**, read from the published package rather than picked
/// by eye — accents are step 9 (solid fill) and step 11 (text on a surface),
/// neutrals are steps 2/3/4/6/11/12. Radix tunes each step to hold its contrast
/// against the surfaces it is meant to sit on, which is the property that
/// matters here since every colour has to work in both brightnesses. The WCAG
/// tests in `test/core/theme/app_theme_test.dart` verify it anyway: the source
/// is a starting point, not the authority.
///
/// The family is **violet + mauve**. Violet carries identity; mauve is the
/// neutral tuned to sit beside it, so surfaces stay quiet without looking like
/// a different app's grey.
abstract final class AppColors {
  /// Source colour for both `ColorScheme.fromSeed` calls. Radix `violet-9`.
  static const Color seed = Color(0xFF6E56CF);

  // --- Neutral surfaces -----------------------------------------------------
  //
  // Two levels, not one: the page sits a step below the card, so a card reads
  // as a card without needing a shadow. Material would derive these from the
  // seed, which tints every surface — that lavender cast is what made the old
  // palette look dated, so the neutrals are declared instead of inherited.

  /// Page background, light. Radix `mauve-2`.
  static const Color backgroundLight = Color(0xFFFAF9FB);

  /// Card and sheet, light.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Primary text, light. Radix `mauve-12`.
  static const Color onSurfaceLight = Color(0xFF211F26);

  /// Secondary text, light. Radix `mauve-11`.
  static const Color onSurfaceVariantLight = Color(0xFF65636D);

  /// Hairline between rows and around cards, light. Radix `mauve-6`.
  static const Color borderSubtleLight = Color(0xFFDBD8E0);

  // Dark surfaces are deliberately NOT Radix steps 1–2.
  //
  // Radix step 1 is `#121113` — effectively black. On an OLED phone that reads
  // as a hole rather than a surface: elevation stops being legible, borders
  // have nothing to separate, and long reading sessions get harsher because the
  // contrast against white text is at its maximum. Steps 3 and 4 keep the same
  // hue relationship while giving the interface a floor to stand on.

  /// Page background, dark. Radix `mauve-3`.
  static const Color backgroundDark = Color(0xFF232225);

  /// Card and sheet, dark — a step above the page. Radix `mauve-4`.
  static const Color surfaceDark = Color(0xFF2B292D);

  /// Primary text, dark. Radix `mauve-12`.
  static const Color onSurfaceDark = Color(0xFFEEEEF0);

  /// Secondary text, dark. Radix `mauve-11`.
  static const Color onSurfaceVariantDark = Color(0xFFB5B2BC);

  /// Hairline, dark. Radix `mauve-7` — one step up from light's 6, because a
  /// border needs more separation against a lifted surface than against white.
  static const Color borderSubtleDark = Color(0xFF49474E);

  // --- Semantic accents -----------------------------------------------------
  //
  // Step 11 in both brightnesses: the step Radix tunes for text and icons on a
  // surface, which is exactly how these are used — an icon and a label, not a
  // filled block.

  /// Answer remembered, session completed, saved. Radix `jade-11`.
  static const Color successLight = Color(0xFF208368);
  static const Color successDark = Color(0xFF1FD8A4);

  /// Card due soon, streak at risk — informative, not alarming. `amber-11`.
  static const Color warningLight = Color(0xFFAB6400);
  static const Color warningDark = Color(0xFFFFCA16);

  /// Answer forgotten, destructive action, reset. Radix `ruby-11`.
  static const Color dangerLight = Color(0xFFCA244D);
  static const Color dangerDark = Color(0xFFFF949D);

  /// Neutral emphasis: hints, counters, "3 of 20". Radix `violet-11`.
  static const Color infoLight = Color(0xFF6550B9);
  static const Color infoDark = Color(0xFFBAA7FF);

  /// Behind a card, to separate it from the page without a border.
  static const Color surfaceMutedLight = backgroundLight;
  static const Color surfaceMutedDark = backgroundDark;
}
