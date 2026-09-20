import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';
import 'package:memox/core/theme/typography/app_typography.dart';

/// The type scale: GC-4's seven roles across the fifteen `TextTheme` slots
/// (`.superpowers/sdd/2026-09-17-memox-v3-foundations/global-constraints.md`),
/// pinned by hand so a retune has to come past this file on purpose.
void main() {
  final TextTheme texts = buildLightTheme().textTheme;

  void expectRole(
    String slot,
    TextStyle? style, {
    required double size,
    required FontWeight weight,
    required double height,
    required double tracking,
  }) {
    expect(style, isNotNull, reason: '$slot has no style');
    expect(style!.fontFamily, AppTypography.family, reason: '$slot family');
    expect(style.fontSize, size, reason: '$slot size');
    expect(style.fontWeight, weight, reason: '$slot weight');
    expect(style.height, closeTo(height, 0.0001), reason: '$slot leading');
    expect(style.letterSpacing, tracking, reason: '$slot tracking');
  }

  test('stat — 40 / 600 / 1.0 / -0.64', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('displayLarge', texts.displayLarge),
      ('displayMedium', texts.displayMedium),
    ]) {
      expectRole(
        slot,
        style,
        size: 40,
        weight: FontWeight.w600,
        height: 1.0,
        tracking: -0.64,
      );
    }
  });

  test('display — 32 / 800 / 1.1 / -0.64', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('displaySmall', texts.displaySmall),
      ('headlineLarge', texts.headlineLarge),
    ]) {
      expectRole(
        slot,
        style,
        size: 32,
        weight: FontWeight.w800,
        height: 1.1,
        tracking: -0.64,
      );
    }
  });

  test('headline — 24 / 700 / 1.2 / -0.64', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('headlineMedium', texts.headlineMedium),
      ('headlineSmall', texts.headlineSmall),
    ]) {
      expectRole(
        slot,
        style,
        size: 24,
        weight: FontWeight.w700,
        height: 1.2,
        tracking: -0.64,
      );
    }
  });

  test('title — 20 / 700 / 1.2 / -0.64 (the app-bar title)', () {
    expectRole(
      'titleLarge',
      texts.titleLarge,
      size: 20,
      weight: FontWeight.w700,
      height: 1.2,
      tracking: -0.64,
    );
  });

  test('body large — 16 / 500 / 1.5 / 0', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('titleMedium', texts.titleMedium),
      ('bodyLarge', texts.bodyLarge),
    ]) {
      expectRole(
        slot,
        style,
        size: 16,
        weight: FontWeight.w500,
        height: 1.5,
        tracking: 0,
      );
    }
  });

  test('body size at semibold — 14 / 600 / 1.5 / 0 (derived)', () {
    for (final (slot, style) in <(String, TextStyle?)>[
      ('titleSmall', texts.titleSmall),
      ('labelLarge', texts.labelLarge),
    ]) {
      expectRole(
        slot,
        style,
        size: 14,
        weight: FontWeight.w600,
        height: 1.5,
        tracking: 0,
      );
    }
  });

  test('body — 14 / 400 / 1.5 / 0', () {
    expectRole(
      'bodyMedium',
      texts.bodyMedium,
      size: 14,
      weight: FontWeight.w400,
      height: 1.5,
      tracking: 0,
    );
  });

  test('caption size at body weight — 12 / 400 / 1.4 / 0 (derived)', () {
    expectRole(
      'bodySmall',
      texts.bodySmall,
      size: 12,
      weight: FontWeight.w400,
      height: 1.4,
      tracking: 0,
    );
  });

  test('caption at the label tracking — 12 / 600 / 1.4 / 0.72 (derived)', () {
    expectRole(
      'labelMedium',
      texts.labelMedium,
      size: 12,
      weight: FontWeight.w600,
      height: 1.4,
      tracking: 0.72,
    );
  });

  test('caption — 12 / 600 / 1.4 / 1.2', () {
    expectRole(
      'labelSmall',
      texts.labelSmall,
      size: 12,
      weight: FontWeight.w600,
      height: 1.4,
      tracking: 1.2,
    );
  });

  test('the card prompt owns its metrics outside the scale', () {
    // 30/1.22/-0.5/w600, unchanged (R6) — a component style, not one of GC-4's
    // seven roles, so it does not move with them.
    final styles = buildLightTheme().extension<AppTextStyles>();

    expect(styles, isNotNull);
    expectRole(
      'cardPrompt',
      styles!.cardPrompt,
      size: AppTypography.cardPromptSize,
      weight: FontWeight.w600,
      height: AppTypography.cardPromptHeight,
      tracking: AppTypography.cardPromptTracking,
    );
  });

  test('the hero numeral is the stat rung, tabular and cap-trimmed (R6)', () {
    // No weight override: the stat rung is already 600, so restating it would
    // only pin the numeral against `applyBoldText`.
    final styles = buildLightTheme().extension<AppTextStyles>()!;
    expectRole(
      'heroNumeral',
      styles.heroNumeral,
      size: 40,
      weight: FontWeight.w600,
      height: AppTypography.heroNumeralCapTrim,
      tracking: -0.64,
    );
    expect(
      styles.heroNumeral.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('the stepper value is body-large, bold and tabular', () {
    final styles = buildLightTheme().extension<AppTextStyles>()!;
    expectRole(
      'stepperValue',
      styles.stepperValue,
      size: 16,
      weight: FontWeight.w700,
      height: 1.5,
      tracking: 0,
    );
    expect(
      styles.stepperValue.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('dark resolves the same scale as light', () {
    // Colour differs by theme; size never does. A scale that drifted between
    // modes would make every golden pair disagree for a reason nobody could see.
    final TextTheme dark = buildDarkTheme().textTheme;

    for (final (String name, TextStyle? a, TextStyle? b)
        in <(String, TextStyle?, TextStyle?)>[
          ('displayLarge', texts.displayLarge, dark.displayLarge),
          ('headlineMedium', texts.headlineMedium, dark.headlineMedium),
          ('titleLarge', texts.titleLarge, dark.titleLarge),
          ('titleMedium', texts.titleMedium, dark.titleMedium),
          ('bodyMedium', texts.bodyMedium, dark.bodyMedium),
          ('labelMedium', texts.labelMedium, dark.labelMedium),
        ]) {
      expect(b?.fontSize, a?.fontSize, reason: '$name size');
      expect(b?.fontWeight, a?.fontWeight, reason: '$name weight');
      expect(b?.height, a?.height, reason: '$name leading');
      expect(b?.letterSpacing, a?.letterSpacing, reason: '$name tracking');
    }
  });

  group('the weight registry (A20.1 P1-10)', () {
    // Every weight the built theme can reach, by the slot that reaches it.
    // Component themes re-weight rungs — a button label is w700 — so the
    // text theme alone is not the registry.
    Map<String, FontWeight> reachable(ThemeData theme) {
      final texts = theme.textTheme;
      final styles = theme.extension<AppTextStyles>()!;
      const states = <WidgetState>{};
      TextStyle? resolve(WidgetStateProperty<TextStyle?>? p) =>
          p?.resolve(states);
      final found = <String, TextStyle?>{
        'displayLarge': texts.displayLarge,
        'displayMedium': texts.displayMedium,
        'displaySmall': texts.displaySmall,
        'headlineLarge': texts.headlineLarge,
        'headlineMedium': texts.headlineMedium,
        'headlineSmall': texts.headlineSmall,
        'titleLarge': texts.titleLarge,
        'titleMedium': texts.titleMedium,
        'titleSmall': texts.titleSmall,
        'bodyLarge': texts.bodyLarge,
        'bodyMedium': texts.bodyMedium,
        'bodySmall': texts.bodySmall,
        'labelLarge': texts.labelLarge,
        'labelMedium': texts.labelMedium,
        'labelSmall': texts.labelSmall,
        'textStyles.heroNumeral': styles.heroNumeral,
        'textStyles.cardPrompt': styles.cardPrompt,
        'textStyles.sectionLabel': styles.sectionLabel,
        'textStyles.sectionLabelSmall': styles.sectionLabelSmall,
        'filledButton.textStyle': resolve(
          theme.filledButtonTheme.style?.textStyle,
        ),
        'outlinedButton.textStyle': resolve(
          theme.outlinedButtonTheme.style?.textStyle,
        ),
        'textButton.textStyle': resolve(theme.textButtonTheme.style?.textStyle),
        'elevatedButton.textStyle': resolve(
          theme.elevatedButtonTheme.style?.textStyle,
        ),
        'segmentedButton.textStyle': resolve(
          theme.segmentedButtonTheme.style?.textStyle,
        ),
        'chip.labelStyle': theme.chipTheme.labelStyle,
        'input.labelStyle': theme.inputDecorationTheme.labelStyle,
        'input.hintStyle': theme.inputDecorationTheme.hintStyle,
        'input.helperStyle': theme.inputDecorationTheme.helperStyle,
        'input.errorStyle': theme.inputDecorationTheme.errorStyle,
        'input.counterStyle': theme.inputDecorationTheme.counterStyle,
        'appBar.titleTextStyle': theme.appBarTheme.titleTextStyle,
        'appBar.toolbarTextStyle': theme.appBarTheme.toolbarTextStyle,
        'navigationBar.labelTextStyle': resolve(
          theme.navigationBarTheme.labelTextStyle,
        ),
        'navigationBar.labelTextStyle.selected': theme
            .navigationBarTheme
            .labelTextStyle
            ?.resolve(<WidgetState>{WidgetState.selected}),
        'dialog.titleTextStyle': theme.dialogTheme.titleTextStyle,
        'dialog.contentTextStyle': theme.dialogTheme.contentTextStyle,
        'snackBar.contentTextStyle': theme.snackBarTheme.contentTextStyle,
        'tooltip.textStyle': theme.tooltipTheme.textStyle,
        'listTile.titleTextStyle': theme.listTileTheme.titleTextStyle,
        'listTile.subtitleTextStyle': theme.listTileTheme.subtitleTextStyle,
        'listTile.leadingAndTrailingTextStyle':
            theme.listTileTheme.leadingAndTrailingTextStyle,
        'popupMenu.labelTextStyle': resolve(
          theme.popupMenuTheme.labelTextStyle,
        ),
        'tabBar.labelStyle': theme.tabBarTheme.labelStyle,
        'tabBar.unselectedLabelStyle': theme.tabBarTheme.unselectedLabelStyle,
        'datePicker.dayStyle': theme.datePickerTheme.dayStyle,
        'datePicker.headerHeadlineStyle':
            theme.datePickerTheme.headerHeadlineStyle,
        'timePicker.hourMinuteTextStyle':
            theme.timePickerTheme.hourMinuteTextStyle,
        'timePicker.dayPeriodTextStyle':
            theme.timePickerTheme.dayPeriodTextStyle,
      };
      return <String, FontWeight>{
        for (final entry in found.entries)
          if (entry.value?.fontWeight != null)
            entry.key: entry.value!.fontWeight!,
      };
    }

    /// The only sources allowed to reach `w700` or `w800`, each one named.
    ///
    /// The heavy slots are GC-4's heading roles: display (800), headline and
    /// title (700). The stat role is 600, so `displayLarge`, `displayMedium`
    /// and the hero numeral left this list when they became it.
    const boldAllowlist = <String>{
      // The display role (`app_typography.dart`).
      'displaySmall',
      'headlineLarge',
      // The headline role.
      'headlineMedium',
      'headlineSmall',
      // The title role.
      'titleLarge',
      // The dial reads the display role directly (`app_time_picker_theme.dart`).
      'timePicker.hourMinuteTextStyle',
      // `buttonLabelWeight` — every button family, one constant.
      'filledButton.textStyle',
      'outlinedButton.textStyle',
      'textButton.textStyle',
    };

    for (final (name, theme) in <(String, ThemeData)>[
      ('light', buildLightTheme()),
      ('dark', buildDarkTheme()),
      ('high contrast light', buildHighContrastLightTheme()),
      ('high contrast dark', buildHighContrastDarkTheme()),
    ]) {
      test(
        '$name reaches exactly the five weights, and every w700/w800 is named',
        () {
          final weights = reachable(theme);
          // {400, 500, 600, 700, 800} is GC-4's own choice, not an M3 default —
          // worth pinning as a set, unlike the specific slot values above.
          expect(weights.values.toSet(), <FontWeight>{
            FontWeight.w400,
            FontWeight.w500,
            FontWeight.w600,
            FontWeight.w700,
            FontWeight.w800,
          });
          final bold = <String>{
            for (final entry in weights.entries)
              if (entry.value == FontWeight.w700 ||
                  entry.value == FontWeight.w800)
                entry.key,
          };
          expect(
            bold.difference(boldAllowlist),
            isEmpty,
            reason: 'a w700/w800 source nobody named',
          );
          expect(
            boldAllowlist.difference(bold),
            isEmpty,
            reason: 'an allowlisted source that is no longer bold — prune it',
          );
        },
      );
    }

    Set<String> spellersOf(String literal) => Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .where((f) => f.readAsStringSync().contains(literal))
        .map((f) => f.uri.pathSegments.last)
        .toSet();

    test('the sources that may spell w700 are exactly the named ones', () {
      // The other half of the registry: the literal itself. `withWeight`
      // through a named constant is the only way a feature reaches bold.
      expect(spellersOf('FontWeight.w700'), <String>{
        'app_typography.dart', // the headline and title roles
        'app_button_themes.dart', // `buttonLabelWeight`
        'app_bold_text.dart', // the OS bold-text setting, every rung
        'app_text_styles.dart', // the Stepper's named value role
        'mx_filter_chip.dart', // the filter chip's count, `_countWeight`
      });
    });

    test('the only source that may spell w800 is the display role', () {
      expect(spellersOf('FontWeight.w800'), <String>{'app_typography.dart'});
    });
  });
}
