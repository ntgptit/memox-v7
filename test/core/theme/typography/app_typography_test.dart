import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/typography/app_typography.dart';

/// The type scale, pinned against `design_system/tokens/typography.css`.
///
/// **This test exists because the scale was an accident.** Until now
/// `app_typography.dart` set family and weight and left every size to Material
/// 3's defaults. Those defaults happen to equal the design's tokens, so the app
/// and the kit agreed — by coincidence, not by declaration. An SDK bump moves
/// Material's scale, and nothing in the project would have failed: not analyze,
/// not a widget test, and not a golden, because a golden compares the app to
/// itself rather than to the design.
///
/// So the numbers below are copied from the CSS by hand, deliberately. A test
/// that read them from the same source the code reads would only prove the code
/// is self-consistent; what is worth proving is that it matches a document
/// nobody can change from inside Dart.
///
/// `height` is Flutter's multiplier and the CSS states a leading, so each
/// expectation writes the division out. Where the design states a ratio rather
/// than a leading — the card prompt's 1.22, body-md's 1.45 — the ratio is used
/// directly.
void main() {
  final TextTheme texts = buildLightTheme().textTheme;

  /// One rung: the CSS token, then what Flutter must resolve.
  void expectStep(
    String token,
    TextStyle? style, {
    required double size,
    required double height,
    required double tracking,
    required String family,
  }) {
    expect(style, isNotNull, reason: '$token has no style at all');
    expect(style!.fontSize, size, reason: '$token size');
    expect(style.height, closeTo(height, 0.0001), reason: '$token leading');
    expect(style.letterSpacing, tracking, reason: '$token tracking');
    expect(style.fontFamily, family, reason: '$token family');
  }

  const String display = AppTypography.displayFamily;
  const String body = AppTypography.bodyFamily;

  group('the display face carries the scale above title', () {
    test('display-lg / md / sm', () {
      expectStep(
        'display-lg',
        texts.displayLarge,
        size: 57,
        height: 64 / 57,
        tracking: 0,
        family: display,
      );
      expectStep(
        'display-md',
        texts.displayMedium,
        size: 45,
        height: 52 / 45,
        tracking: 0,
        family: display,
      );
      expectStep(
        'display-sm',
        texts.displaySmall,
        size: 36,
        height: 44 / 36,
        tracking: 0,
        family: display,
      );
    });

    test('headline-lg / the card prompt / headline-sm', () {
      expectStep(
        'headline-lg',
        texts.headlineLarge,
        size: 32,
        height: 40 / 32,
        tracking: 0,
        family: display,
      );
      // The Material 3 metric, held since the card prompt moved to its own
      // `AppTextStyles.cardPrompt` slot — this pin now prevents the rung from
      // quietly carrying a component's metrics again.
      expectStep(
        'headline-md',
        texts.headlineMedium,
        size: 28,
        height: 36 / 28,
        tracking: 0,
        family: display,
      );
      expectStep(
        'headline-sm',
        texts.headlineSmall,
        size: 24,
        height: 32 / 24,
        tracking: 0,
        family: display,
      );
    });

    test('the card prompt owns its metrics outside the scale', () {
      // The one deliberately large style: 30/1.22/-0.5, now an
      // `AppTextStyles` slot rather than a rung a bystander can inherit.
      final styles = buildLightTheme().extension<AppTextStyles>();

      expect(styles, isNotNull);
      expectStep(
        'card-prompt',
        styles!.cardPrompt,
        size: AppTypography.cardPromptSize,
        height: AppTypography.cardPromptHeight,
        tracking: AppTypography.cardPromptTracking,
        family: display,
      );
    });

    test('title-lg is the app-bar title', () {
      expectStep(
        'title-lg',
        texts.titleLarge,
        size: 22,
        height: 28 / 22,
        tracking: 0,
        family: display,
      );
    });
  });

  group('the body face carries title-md down', () {
    test('title-md / title-sm', () {
      expectStep(
        'title-md',
        texts.titleMedium,
        size: 16,
        height: 24 / 16,
        tracking: 0.15,
        family: body,
      );
      expectStep(
        'title-sm',
        texts.titleSmall,
        size: 14,
        height: 20 / 14,
        tracking: 0.1,
        family: body,
      );
    });

    test('body-lg / md / sm', () {
      expectStep(
        'body-lg',
        texts.bodyLarge,
        size: 16,
        height: 24 / 16,
        tracking: 0.5,
        family: body,
      );
      // A ratio rather than a leading: 1.45 keeps a two-line empty-state
      // message readable without looking airy.
      expectStep(
        'body-md',
        texts.bodyMedium,
        size: 14,
        height: 1.45,
        tracking: 0.25,
        family: body,
      );
      expectStep(
        'body-sm',
        texts.bodySmall,
        size: 12,
        height: 16 / 12,
        tracking: 0.4,
        family: body,
      );
    });

    test('label-lg / md / sm', () {
      expectStep(
        'label-lg',
        texts.labelLarge,
        size: 14,
        height: 20 / 14,
        tracking: 0.1,
        family: body,
      );
      expectStep(
        'label-md',
        texts.labelMedium,
        size: 12,
        height: 16 / 12,
        tracking: 0.5,
        family: body,
      );
      expectStep(
        'label-sm',
        texts.labelSmall,
        size: 11,
        height: 16 / 11,
        tracking: 0.5,
        family: body,
      );
    });
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
      expect(b?.height, a?.height, reason: '$name leading');
      expect(b?.letterSpacing, a?.letterSpacing, reason: '$name tracking');
    }
  });

  group('the weights the app spends', () {
    /// Every weight the text theme itself declares.
    Set<FontWeight> themeWeights() {
      final theme = AppTypography.buildTextTheme(ThemeData.light().textTheme);

      return <FontWeight>{
        for (final style in <TextStyle?>[
          theme.displayLarge,
          theme.displayMedium,
          theme.displaySmall,
          theme.headlineLarge,
          theme.headlineMedium,
          theme.headlineSmall,
          theme.titleLarge,
          theme.titleMedium,
          theme.titleSmall,
          theme.bodyLarge,
          theme.bodyMedium,
          theme.bodySmall,
          theme.labelLarge,
          theme.labelMedium,
          theme.labelSmall,
        ])
          if (style?.fontWeight != null) style!.fontWeight!,
      };
    }

    test('the scale itself spends three', () {
      // 400 body, 500 and 600 for emphasis. `w700` belongs to the two display
      // rungs (57 and 45), which no screen in the app currently uses.
      expect(
        themeWeights(),
        containsAll(<FontWeight>[
          FontWeight.w400,
          FontWeight.w500,
          FontWeight.w600,
        ]),
      );
    });

    test('the hero numeral is the one weight a feature adds, and it is named', () {
      // `deck_list_root.md` §6 scored the deck list ❌ for four weights and had
      // to hedge — the code said `w700` at a call site and nothing said why, so
      // a deliberate exception and an accident read the same from outside.
      //
      // This asserts the exception is still exactly one, still the heaviest
      // thing on the screen, and still heavier than the rung it overrides. A
      // fifth weight has to come past this test and the note beside the
      // constant.
      expect(AppTypography.heroNumeralWeight, FontWeight.w700);

      final theme = AppTypography.buildTextTheme(ThemeData.light().textTheme);
      expect(
        theme.headlineLarge?.fontWeight,
        FontWeight.w600,
        reason:
            'the numeral overrides this rung; if it stops being w600 the '
            'exception may no longer be one',
      );
      expect(
        AppTypography.heroNumeralWeight.value,
        greaterThan(theme.headlineLarge!.fontWeight!.value),
        reason: 'an exception that is not heavier buys nothing',
      );
    });
  });
}
