import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';

/// The handoff's type roles (`docs/design-system/handoff/memox-flutter-handoff.json`
/// → Foundations · Typography), pinned by hand. The numbers are copied from the
/// handoff, not read from `AppTypography`: a test that read the code's own
/// constants would only prove the code agrees with itself.
///
/// The slot → role table is D1 in `tokyo-component-mapping.md` §9.
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
    expect(style!.fontSize, size, reason: '$slot size');
    expect(style.fontWeight, weight, reason: '$slot weight');
    expect(style.height, closeTo(height, 0.0001), reason: '$slot leading');
    expect(style.letterSpacing, tracking, reason: '$slot tracking');
    expect(style.fontFamily, 'PlusJakartaSans', reason: '$slot family');
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

  test('title — 20 / 700 / 1.2 / -0.64', () {
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

  test('body size at semibold — 14 / 600 / 1.5 / 0 (derived, D1)', () {
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

  test('caption family — 12px is the floor for every slot', () {
    expectRole(
      'bodySmall',
      texts.bodySmall,
      size: 12,
      weight: FontWeight.w400,
      height: 1.4,
      tracking: 0,
    );
    expectRole(
      'labelMedium',
      texts.labelMedium,
      size: 12,
      weight: FontWeight.w600,
      height: 1.4,
      tracking: 0.72,
    );
    expectRole(
      'labelSmall',
      texts.labelSmall,
      size: 12,
      weight: FontWeight.w600,
      height: 1.4,
      tracking: 1.2,
    );
  });

  test('no slot renders below the 12px floor', () {
    for (final style in <TextStyle?>[
      texts.displayLarge,
      texts.displayMedium,
      texts.displaySmall,
      texts.headlineLarge,
      texts.headlineMedium,
      texts.headlineSmall,
      texts.titleLarge,
      texts.titleMedium,
      texts.titleSmall,
      texts.bodyLarge,
      texts.bodyMedium,
      texts.bodySmall,
      texts.labelLarge,
      texts.labelMedium,
      texts.labelSmall,
    ]) {
      expect(style!.fontSize, greaterThanOrEqualTo(12));
    }
  });

  test('dark resolves the same scale as light', () {
    final TextTheme dark = buildDarkTheme().textTheme;
    expect(dark.displayLarge?.fontSize, texts.displayLarge?.fontSize);
    expect(dark.titleLarge?.letterSpacing, texts.titleLarge?.letterSpacing);
    expect(dark.labelSmall?.height, texts.labelSmall?.height);
  });

  test('the component styles speak the same roles', () {
    final styles = buildLightTheme().extension<AppTextStyles>()!;

    expect(styles.heroNumeral.fontSize, 40, reason: 'stat role');
    expect(styles.heroNumeral.fontWeight, FontWeight.w600);
    expect(styles.cardPrompt.fontSize, 32, reason: 'D13');
    expect(styles.cardPrompt.fontWeight, FontWeight.w700);
    expect(styles.cardPrompt.letterSpacing, -0.64);
    expect(styles.sectionLabel.letterSpacing, 1.2, reason: 'ls-section');
    expect(styles.listHeading.letterSpacing, 0.72, reason: 'ls-label');
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
    /// The heavy slots are D1's heading roles (`tokyo-component-mapping.md`
    /// §9): display (800), headline and title (700). The stat role is 600, so
    /// `displayLarge`, `displayMedium` and the hero numeral left this list
    /// when they became it (M100.89).
    const boldAllowlist = <String>{
      // The display role (`app_typography.dart`).
      'displaySmall',
      'headlineLarge',
      // The headline role.
      'headlineMedium',
      'headlineSmall',
      // The title role.
      'titleLarge',
      // `AppTypography.cardPromptWeight` — the headline's weight (D13).
      'textStyles.cardPrompt',
      // The time picker's dial figures read `displaySmall`.
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
      test('$name reaches exactly the five weights, and every w700 and w800 is '
          'named', () {
        final weights = reachable(theme);
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
          reason: 'a w700 source nobody named',
        );
        expect(
          boldAllowlist.difference(bold),
          isEmpty,
          reason: 'an allowlisted source that is no longer bold — prune it',
        );
      });
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
        'app_typography.dart', // the heading roles and `cardPromptWeight`
        'app_button_themes.dart', // `buttonLabelWeight`
        'app_bold_text.dart', // the OS bold-text setting, every rung
      });
    });

    test('the only source that may spell w800 is the display role', () {
      expect(spellersOf('FontWeight.w800'), <String>{'app_typography.dart'});
    });
  });
}
