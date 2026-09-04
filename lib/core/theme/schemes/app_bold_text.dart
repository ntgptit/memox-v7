import 'package:flutter/material.dart';

import '../typography/app_text_styles.dart';
import '../typography/app_typography.dart';

/// The theme with the OS "Bold text" setting applied (A20.1 P1-11).
///
/// **Flutter honours `MediaQuery.boldText` by merging
/// `TextStyle(fontWeight: FontWeight.bold)` into every `Text`
/// (`widgets/text.dart:722`), and on this app that was a complete no-op.** Both
/// faces are variable fonts and every rung carries a `wght` axis, which the
/// renderer consults *instead of* `fontWeight` once it is present — the same
/// fact `AppTypography.withWeight` exists for. A user who turned Bold text on
/// got exactly the pixels a user who had not.
///
/// So the setting is answered where the axis lives: every rung of the text
/// theme is re-set through `withWeight` at `w700`, and `AppTextStyles` is
/// rebuilt from the emboldened rungs so the named roles follow. `heroNumeral`
/// is already `w700` and keeps its derived cap-trim untouched — bold text
/// changes the weight of a rung, never its metrics.
///
/// Cached per base theme like `applyCompactScale`, and for the same reason:
/// the wrapper rebuilds whenever `MediaQuery` changes.
ThemeData applyBoldText(ThemeData base) {
  final cached = _boldTextCache[base];
  if (cached != null) return cached;

  final bold = _buildBoldText(base);
  _boldTextCache[base] = bold;

  return bold;
}

final Expando<ThemeData> _boldTextCache = Expando<ThemeData>('applyBoldText');

/// The weight Flutter itself would merge for `boldText`.
const FontWeight _boldTextWeight = FontWeight.w700;

TextStyle? _bold(TextStyle? style) =>
    style == null ? null : AppTypography.withWeight(style, _boldTextWeight);

ThemeData _buildBoldText(ThemeData base) {
  final texts = base.textTheme;
  final boldTexts = texts.copyWith(
    displayLarge: _bold(texts.displayLarge),
    displayMedium: _bold(texts.displayMedium),
    displaySmall: _bold(texts.displaySmall),
    headlineLarge: _bold(texts.headlineLarge),
    headlineMedium: _bold(texts.headlineMedium),
    headlineSmall: _bold(texts.headlineSmall),
    titleLarge: _bold(texts.titleLarge),
    titleMedium: _bold(texts.titleMedium),
    titleSmall: _bold(texts.titleSmall),
    bodyLarge: _bold(texts.bodyLarge),
    bodyMedium: _bold(texts.bodyMedium),
    bodySmall: _bold(texts.bodySmall),
    labelLarge: _bold(texts.labelLarge),
    labelMedium: _bold(texts.labelMedium),
    labelSmall: _bold(texts.labelSmall),
  );

  return base.copyWith(
    textTheme: boldTexts,
    extensions: <ThemeExtension<Object?>>[
      ...base.extensions.values.where((ext) => ext is! AppTextStyles),
      AppTextStyles.from(boldTexts),
    ],
  );
}
