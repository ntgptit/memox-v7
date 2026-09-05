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

/// One style re-weighted through `wght`.
///
/// **A state-resolved style keeps its resolver.** `hintStyle` is a
/// `WidgetStateTextStyle` — `onSurfaceVariant` at rest, `onDisabled` when the
/// field is disabled. Re-weighting its resting resolution alone froze the hint
/// at full ink on a disabled field (corrective pass 2, Codex review on #462);
/// the resolver is wrapped instead, so every state it answers is re-weighted.
TextStyle? _bold(TextStyle? style) {
  if (style == null) return null;
  if (style is WidgetStateTextStyle) {
    return WidgetStateTextStyle.resolveWith(
      (states) =>
          AppTypography.withWeight(style.resolve(states), _boldTextWeight),
    );
  }
  return AppTypography.withWeight(style, _boldTextWeight);
}

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

  // **Component themes carry their own copies of these styles** (A20.1
  // P1-11, corrective pass). Every slot below was built from the text theme
  // at theme-build time, so re-weighting the text theme alone left a list
  // tile, a hint, a menu row and a dialog title at their resting weight —
  // the OS setting visibly moved body text and nothing around it. Each slot
  // the app's theme sets is re-weighted through the same `wght` path; a slot
  // the theme leaves null stays null.
  return base.copyWith(
    textTheme: boldTexts,
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: _bold(base.appBarTheme.titleTextStyle),
      toolbarTextStyle: _bold(base.appBarTheme.toolbarTextStyle),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      titleTextStyle: _bold(base.listTileTheme.titleTextStyle),
      subtitleTextStyle: _bold(base.listTileTheme.subtitleTextStyle),
      leadingAndTrailingTextStyle: _bold(
        base.listTileTheme.leadingAndTrailingTextStyle,
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      labelTextStyle: _boldStates(base.navigationBarTheme.labelTextStyle),
    ),
    bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
      selectedLabelStyle: _bold(
        base.bottomNavigationBarTheme.selectedLabelStyle,
      ),
      unselectedLabelStyle: _bold(
        base.bottomNavigationBarTheme.unselectedLabelStyle,
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      labelStyle: _bold(base.inputDecorationTheme.labelStyle),
      floatingLabelStyle: _bold(base.inputDecorationTheme.floatingLabelStyle),
      helperStyle: _bold(base.inputDecorationTheme.helperStyle),
      hintStyle: _bold(base.inputDecorationTheme.hintStyle),
      errorStyle: _bold(base.inputDecorationTheme.errorStyle),
      prefixStyle: _bold(base.inputDecorationTheme.prefixStyle),
      suffixStyle: _bold(base.inputDecorationTheme.suffixStyle),
      counterStyle: _bold(base.inputDecorationTheme.counterStyle),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      textStyle: _bold(base.popupMenuTheme.textStyle),
      labelTextStyle: _boldStates(base.popupMenuTheme.labelTextStyle),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      titleTextStyle: _bold(base.dialogTheme.titleTextStyle),
      contentTextStyle: _bold(base.dialogTheme.contentTextStyle),
    ),
    datePickerTheme: base.datePickerTheme.copyWith(
      dayStyle: _bold(base.datePickerTheme.dayStyle),
      yearStyle: _bold(base.datePickerTheme.yearStyle),
      weekdayStyle: _bold(base.datePickerTheme.weekdayStyle),
      headerHeadlineStyle: _bold(base.datePickerTheme.headerHeadlineStyle),
      headerHelpStyle: _bold(base.datePickerTheme.headerHelpStyle),
      rangePickerHeaderHeadlineStyle: _bold(
        base.datePickerTheme.rangePickerHeaderHeadlineStyle,
      ),
      rangePickerHeaderHelpStyle: _bold(
        base.datePickerTheme.rangePickerHeaderHelpStyle,
      ),
    ),
    timePickerTheme: base.timePickerTheme.copyWith(
      hourMinuteTextStyle: _bold(base.timePickerTheme.hourMinuteTextStyle),
      dayPeriodTextStyle: _bold(base.timePickerTheme.dayPeriodTextStyle),
      dialTextStyle: _bold(base.timePickerTheme.dialTextStyle),
      helpTextStyle: _bold(base.timePickerTheme.helpTextStyle),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      valueIndicatorTextStyle: _bold(base.sliderTheme.valueIndicatorTextStyle),
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      contentTextStyle: _bold(base.snackBarTheme.contentTextStyle),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: _bold(base.chipTheme.labelStyle),
      secondaryLabelStyle: _bold(base.chipTheme.secondaryLabelStyle),
    ),
    tooltipTheme: base.tooltipTheme.copyWith(
      textStyle: _bold(base.tooltipTheme.textStyle),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      labelStyle: _bold(base.tabBarTheme.labelStyle),
      unselectedLabelStyle: _bold(base.tabBarTheme.unselectedLabelStyle),
    ),
    dropdownMenuTheme: base.dropdownMenuTheme.copyWith(
      textStyle: _bold(base.dropdownMenuTheme.textStyle),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _boldButton(base.elevatedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _boldButton(base.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _boldButton(base.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _boldButton(base.textButtonTheme.style),
    ),
    segmentedButtonTheme: base.segmentedButtonTheme.copyWith(
      style: _boldButton(base.segmentedButtonTheme.style),
    ),
    extensions: <ThemeExtension<Object?>>[
      ...base.extensions.values.where((ext) => ext is! AppTextStyles),
      AppTextStyles.from(boldTexts),
    ],
  );
}

/// A state-resolved slot re-weighted per state: the resting, selected and
/// disabled styles each go through `wght` rather than only the default.
WidgetStateProperty<TextStyle?>? _boldStates(
  WidgetStateProperty<TextStyle?>? property,
) => property == null
    ? null
    : WidgetStateProperty.resolveWith(
        (states) => _bold(property.resolve(states)),
      );

ButtonStyle? _boldButton(ButtonStyle? style) =>
    style?.copyWith(textStyle: _boldStates(style.textStyle));
