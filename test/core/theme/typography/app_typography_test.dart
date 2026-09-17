import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/typography/app_typography.dart';
import 'dart:io';

/// The type scale: which face each rung resolves, and that the two modes
/// resolve the same scale.
///
/// **It used to pin every metric, and that stopped being a check.** The test
/// was written when `app_typography.dart` set family and weight and left every
/// size to Material 3's defaults: the defaults happened to equal the design's
/// tokens, so an SDK bump could have moved the scale with nothing failing. The
/// numbers were therefore copied by hand out of a CSS kit — a document nobody
/// could change from inside Dart — so the test measured the code against the
/// design rather than against itself.
///
/// Both halves of that argument are gone. The CSS kit was removed at M100.83,
/// and `app_typography.dart` now declares every size and leading explicitly, so
/// the literals here had become a second copy of the token file: they could no
/// longer catch an SDK bump, and the only thing left that could turn them red
/// was someone retuning the scale on purpose. Design System V1 was unlocked on
/// 2026-09-17 and that is legitimate work, so the metric pins went with it.
///
/// What is asserted now holds at any scale: every rung resolves a style, each
/// rung is on the right face, light and dark agree, and `cardPrompt` reads its
/// own `AppTypography` tokens rather than inheriting a rung's.
void main() {
  final TextTheme texts = buildLightTheme().textTheme;

  /// One rung: which face it must resolve, and — only where a *token* names
  /// the metric — that the slot actually resolves that token.
  ///
  /// `size`, `height` and `tracking` are optional since Design System V1 was
  /// unlocked. Passing a bare number here re-freezes the rung, so the rungs
  /// pass nothing; `AppTextStyles.cardPrompt` still passes its three
  /// `AppTypography` constants, because that check is "the slot reads the
  /// token", which holds at whatever the token becomes.
  void expectStep(
    String token,
    TextStyle? style, {
    required String family,
    double? size,
    double? height,
    double? tracking,
  }) {
    expect(style, isNotNull, reason: '$token has no style at all');
    expect(style!.fontFamily, family, reason: '$token family');

    if (size != null) {
      expect(style.fontSize, size, reason: '$token size');
    }
    if (height != null) {
      expect(style.height, closeTo(height, 0.0001), reason: '$token leading');
    }
    if (tracking != null) {
      expect(style.letterSpacing, tracking, reason: '$token tracking');
    }
  }

  const String display = AppTypography.displayFamily;
  const String body = AppTypography.bodyFamily;

  group('the display face carries the scale above title', () {
    test('display-lg / md / sm', () {
      expectStep('display-lg', texts.displayLarge, family: display);
      expectStep('display-md', texts.displayMedium, family: display);
      expectStep('display-sm', texts.displaySmall, family: display);
    });

    test('headline-lg / the card prompt / headline-sm', () {
      expectStep('headline-lg', texts.headlineLarge, family: display);
      // headline-md carried the card prompt's metrics until the prompt moved
      // to its own `AppTextStyles.cardPrompt` slot. That separation is what
      // the card-prompt test below still holds; the rung's own size is the
      // scale's business.
      expectStep('headline-md', texts.headlineMedium, family: display);
      expectStep('headline-sm', texts.headlineSmall, family: display);
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
      expectStep('title-lg', texts.titleLarge, family: display);
    });
  });

  group('the body face carries title-md down', () {
    test('title-md / title-sm', () {
      expectStep('title-md', texts.titleMedium, family: body);
      expectStep('title-sm', texts.titleSmall, family: body);
    });

    test('body-lg / md / sm', () {
      expectStep('body-lg', texts.bodyLarge, family: body);
      expectStep('body-md', texts.bodyMedium, family: body);
      expectStep('body-sm', texts.bodySmall, family: body);
    });

    test('label-lg / md / sm', () {
      expectStep('label-lg', texts.labelLarge, family: body);
      expectStep('label-md', texts.labelMedium, family: body);
      expectStep('label-sm', texts.labelSmall, family: body);
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

    test('the scale spends more than one weight', () {
      // Which weights it spends — 400 body, 500 and 600 for emphasis — used to
      // be pinned here. That was the V1 scale's choice and it went when Design
      // System V1 was unlocked. A scale that resolves one weight everywhere has
      // no emphasis at all, which is a defect at any values; that is the claim
      // left standing. The registry below is what names every heavy source.
      expect(themeWeights().length, greaterThan(1));
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
      // The two weights themselves (w700 for the numeral, w600 for the rung it
      // overrides) used to be pinned here. They went when Design System V1 was
      // unlocked: what makes the exception an exception is the relation below,
      // and that holds at whatever the two weigh.
      final theme = AppTypography.buildTextTheme(ThemeData.light().textTheme);
      expect(
        AppTypography.heroNumeralWeight.value,
        greaterThan(theme.headlineLarge!.fontWeight!.value),
        reason: 'an exception that is not heavier buys nothing',
      );
    });
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

    /// The only sources allowed to reach `w700`, each one named.
    const boldAllowlist = <String>{
      // The two display rungs (`app_typography.dart`).
      'displayLarge',
      'displayMedium',
      // `AppTypography.heroNumeralWeight` — the deck hero's numeral.
      'textStyles.heroNumeral',
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
        '$name reaches exactly the four weights, and every w700 is named',
        () {
          final weights = reachable(theme);
          // The set used to be pinned as exactly {w400, w500, w600, w700}.
          // That was the V1 scale's own choice of weights, and it went when
          // Design System V1 was unlocked. The allowlist below is the part
          // that was ever a rule: a heavy weight reachable from a source
          // nobody named is an accident, whatever the scale weighs.
          final bold = <String>{
            for (final entry in weights.entries)
              if (entry.value == FontWeight.w700) entry.key,
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
        },
      );
    }

    test('the sources that may spell w700 are exactly the named ones', () {
      // The other half of the registry: the literal itself. `withWeight`
      // through a named constant is the only way a feature reaches bold.
      final spellers = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
          .where((f) => f.readAsStringSync().contains('FontWeight.w700'))
          .map((f) => f.uri.pathSegments.last)
          .toSet();
      expect(spellers, <String>{
        'app_typography.dart', // the display rungs and `heroNumeralWeight`
        'app_button_themes.dart', // `buttonLabelWeight`
        'app_bold_text.dart', // the OS bold-text setting, every rung
      });
    });
  });
}
