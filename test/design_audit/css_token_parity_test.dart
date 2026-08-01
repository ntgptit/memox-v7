import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_button_themes.dart';
import 'package:memox/core/theme/app_colors.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'css_tokens.dart';

/// **`design_system/tokens/*.css` is authoritative for token values; this is the
/// test that makes that sentence enforceable.**
///
/// Until now it was a statement in `docs/architecture.md` and nothing else. The
/// Dart tests that cover these numbers hand-copy them, deliberately — see the
/// header of `app_typography_test.dart` — so the pair that could silently
/// disagree was never Dart against its own test. It was Dart against the CSS.
/// Edit `colors.css` and every gate in this repo stays green.
///
/// Two halves, and the second is the one that lasts: **value parity**, each
/// token the app brought over resolving to what the CSS says today; and
/// **completeness**, every `--color-*` the CSS declares being either mapped here
/// or named in [_notBroughtOver] with a reason — so a token *added* to the kit
/// fails this file until someone decides about it.
///
/// Colours only. The scales — spacing, radius, motion, the type ramp — are in
/// `css_scale_parity_test.dart`, split off at the 400-line guard.
void main() {
  final ThemeData light = buildLightTheme();
  final ThemeData dark = buildDarkTheme();

  /// The CSS colour tokens the app has brought over, by scope.
  ///
  /// Keyed by the CSS name so the completeness check below can subtract this set
  /// from the file's own declarations.
  final colorParity = <String, (Color, Color)>{
    // --- surface ladder ---
    '--color-background': (AppColors.backgroundLight, AppColors.backgroundDark),
    '--color-surface': (AppColors.surfaceLight, AppColors.surfaceDark),
    '--color-surface-muted': (
      AppColors.surfaceMutedLight,
      AppColors.surfaceMutedDark,
    ),
    '--color-surface-elevated': (
      AppColors.surfaceElevatedLight,
      AppColors.surfaceElevatedDark,
    ),
    // --- text and lines ---
    '--color-text-primary': (
      AppColors.textPrimaryLight,
      AppColors.textPrimaryDark,
    ),
    '--color-text-secondary': (
      AppColors.textSecondaryLight,
      AppColors.textSecondaryDark,
    ),
    '--color-border-subtle': (
      AppColors.borderSubtleLight,
      AppColors.borderSubtleDark,
    ),
    '--color-focus-ring': (AppColors.focusRingLight, AppColors.focusRingDark),
    // --- brand and actions ---
    '--color-seed': (AppColors.seed, AppColors.seed),
    '--color-primary': (AppColors.primaryLight, AppColors.primaryDark),
    '--color-on-primary': (AppColors.onPrimaryLight, AppColors.onPrimaryDark),
    '--color-primary-accent': (
      AppColors.primaryAccentLight,
      AppColors.primaryAccentDark,
    ),
    '--color-primary-container': (
      AppColors.primaryContainerLight,
      AppColors.primaryContainerDark,
    ),
    '--color-on-primary-container': (
      AppColors.onPrimaryContainerLight,
      AppColors.onPrimaryContainerDark,
    ),
    '--color-secondary': (AppColors.secondaryLight, AppColors.secondaryDark),
    '--color-on-secondary': (
      AppColors.onSecondaryLight,
      AppColors.onSecondaryDark,
    ),
    '--color-secondary-container': (
      AppColors.secondaryContainerLight,
      AppColors.secondaryContainerDark,
    ),
    '--color-on-secondary-container': (
      AppColors.onSecondaryContainerLight,
      AppColors.onSecondaryContainerDark,
    ),
    '--color-tertiary': (AppColors.tertiaryLight, AppColors.tertiaryDark),
    '--color-on-tertiary': (
      AppColors.onTertiaryLight,
      AppColors.onTertiaryDark,
    ),
    '--color-tertiary-container': (
      AppColors.tertiaryContainerLight,
      AppColors.tertiaryContainerDark,
    ),
    '--color-on-tertiary-container': (
      AppColors.onTertiaryContainerLight,
      AppColors.onTertiaryContainerDark,
    ),
    '--color-secondary-action': (
      AppColors.secondaryActionLight,
      AppColors.secondaryActionDark,
    ),
    // --- meaning ---
    '--color-success': (AppColors.successLight, AppColors.successDark),
    '--color-warning': (AppColors.warningLight, AppColors.warningDark),
    '--color-danger': (AppColors.dangerLight, AppColors.dangerDark),
    '--color-info': (AppColors.infoLight, AppColors.infoDark),
    // `error` is `danger`, not a second red system — AD-05. The CSS says the
    // same thing by pointing both names at one literal.
    '--color-error': (AppColors.dangerLight, AppColors.dangerDark),
    '--color-on-error': (AppColors.onErrorLight, AppColors.onErrorDark),
    '--color-error-container': (
      AppColors.errorContainerLight,
      AppColors.errorContainerDark,
    ),
    '--color-on-error-container': (
      AppColors.onErrorContainerLight,
      AppColors.onErrorContainerDark,
    ),
    // --- progress and reward ---
    '--color-progress-track': (
      AppColors.progressTrackLight,
      AppColors.progressTrackDark,
    ),
    '--color-progress-fill': (
      AppColors.progressFillLight,
      AppColors.progressFillDark,
    ),
    '--color-progress-complete': (
      AppColors.successLight,
      AppColors.successDark,
    ),
    '--color-streak-container': (
      AppColors.streakContainerLight,
      AppColors.streakContainerDark,
    ),
    // --- Material surface container ladder ---
    '--color-surface-container-lowest': (
      AppColors.surfaceContainerLowestLight,
      AppColors.surfaceContainerLowestDark,
    ),
    '--color-surface-container-low': (
      AppColors.surfaceContainerLowLight,
      AppColors.surfaceContainerLowDark,
    ),
    '--color-surface-container': (
      AppColors.surfaceContainerLight,
      AppColors.surfaceContainerDark,
    ),
    '--color-surface-container-high': (
      AppColors.surfaceContainerHighLight,
      AppColors.surfaceContainerHighDark,
    ),
    '--color-surface-container-highest': (
      AppColors.surfaceContainerHighestLight,
      AppColors.surfaceContainerHighestDark,
    ),
    '--color-surface-dim': (
      AppColors.surfaceDimLight,
      AppColors.surfaceDimDark,
    ),
    '--color-surface-bright': (
      AppColors.surfaceBrightLight,
      AppColors.surfaceBrightDark,
    ),
    '--color-inverse-surface': (
      AppColors.inverseSurfaceLight,
      AppColors.inverseSurfaceDark,
    ),
    '--color-on-inverse-surface': (
      AppColors.onInverseSurfaceLight,
      AppColors.onInverseSurfaceDark,
    ),
    '--color-inverse-primary': (
      AppColors.inversePrimaryLight,
      AppColors.inversePrimaryDark,
    ),
    // --- chrome ---
    '--color-shadow': (AppColors.shadowLight, AppColors.shadowDark),
    '--color-scrim': (AppColors.scrimLight, AppColors.scrimDark),
    '--color-web-letterbox': (AppColors.webLetterbox, AppColors.webLetterbox),
  };

  group('colours match the kit', () {
    for (final entry in colorParity.entries) {
      test('${entry.key} in both modes', () {
        expect(
          CssTokens.color('colors.css', entry.key),
          entry.value.$1,
          reason: '${entry.key} light',
        );
        expect(
          CssTokens.color(
            'colors.css',
            entry.key,
            scope: '[data-theme="dark"]',
          ),
          entry.value.$2,
          reason: '${entry.key} dark',
        );
      });
    }

    test('the disabled foreground alpha is the kit\'s 0.38', () {
      // Stated as `rgb(R G B / 0.38)` rather than a hex, so it is read as a pair:
      // the ink it tints, and how much of it survives. Both halves matter —
      // `kDisabledForegroundAlpha` is what three component themes multiply by.
      for (final (String scope, Color ink) in <(String, Color)>[
        (':root', AppColors.textPrimaryLight),
        ('[data-theme="dark"]', AppColors.textPrimaryDark),
      ]) {
        final raw = CssTokens.require(
          'colors.css',
          '--color-on-disabled',
          scope: scope,
        );
        final match = RegExp(
          r'rgb\(\s*(\d+)\s+(\d+)\s+(\d+)\s*/\s*([\d.]+)\s*\)',
        ).firstMatch(raw);

        expect(match, isNotNull, reason: '--color-on-disabled is "$raw"');

        // **The alpha is exact; the ink is within one unit.** This is the only
        // token the kit restates in `rgb()` decimals rather than as
        // `var(--mx-ink-*)`, and dark came back one off the hex (`237 238 245`
        // against `#EDEDF6`) — a transcription artefact, not a second ink.
        for (final (String channel, int declared, double actual)
            in <(String, int, double)>[
              ('red', int.parse(match!.group(1)!), ink.r),
              ('green', int.parse(match.group(2)!), ink.g),
              ('blue', int.parse(match.group(3)!), ink.b),
            ]) {
          expect(
            (declared - actual * 255).abs(),
            lessThanOrEqualTo(1),
            reason: '--color-on-disabled $channel in $scope',
          );
        }

        // No tolerance here. The alpha is what three component themes multiply
        // by, so a drift of 0.01 is a decision, not a rounding.
        expect(double.parse(match.group(4)!), kDisabledForegroundAlpha);
      }
    });

    test('every colour token is mapped or explained', () {
      // The half that catches an *addition*. A new `--color-*` in the kit is a
      // decision the app has to make — bring it over, or say why not — and
      // without this it is a decision nobody is asked to make.
      final declared = <String>{
        ...CssTokens.names('colors.css'),
        ...CssTokens.names('colors.css', scope: '[data-theme="dark"]'),
      }.where((name) => name.startsWith('--color-')).toSet();

      final unaccounted =
          declared
              .where((name) => !colorParity.containsKey(name))
              .where((name) => !_notBroughtOver.containsKey(name))
              .where((name) => !_derived.containsKey(name))
              .toList()
            ..sort();

      expect(
        unaccounted,
        isEmpty,
        reason:
            'These exist in design_system/tokens/colors.css and the app has no '
            'position on them. Add a Dart counterpart and map it above, or add '
            'it to _notBroughtOver with the reason.\n${unaccounted.join('\n')}',
      );
    });

    test('nothing is explained away that the kit no longer declares', () {
      // The reverse. A deviation kept after the token it excused was deleted is
      // a comment describing a file that has moved on.
      final declared = <String>{
        ...CssTokens.names('colors.css'),
        ...CssTokens.names('colors.css', scope: '[data-theme="dark"]'),
      };

      for (final name in <String>[
        ..._notBroughtOver.keys,
        ..._derived.keys,
        ...colorParity.keys,
      ]) {
        expect(
          declared,
          contains(name),
          reason: '$name is claimed here but colors.css does not declare it',
        );
      }
    });
  });

  group('what the app derives still lands on the kit\'s value', () {
    test('the disabled surface stays within four units of the kit', () {
      // **A tolerance, not an equality, and `IMPORT_LEDGER.md` is where that
      // was decided.** CSS cannot blend at build time, so the kit carries a
      // literal where Dart carries `onSurface @ 12% over surface`; they land
      // four units apart at most, and deriving is what kept dark correct when
      // the surface ladder moved onto the page's hue. Wide enough for the
      // transcription gap, far too narrow for a token actually re-pointed.
      for (final (String scope, ColorScheme scheme) in <(String, ColorScheme)>[
        (':root', light.colorScheme),
        ('[data-theme="dark"]', dark.colorScheme),
      ]) {
        final derived = disabledSurfaceTint(scheme);
        final declared = CssTokens.color(
          'colors.css',
          '--color-disabled-surface',
          scope: scope,
        );

        for (final (String channel, double a, double b)
            in <(String, double, double)>[
              ('red', derived.r, declared.r),
              ('green', derived.g, declared.g),
              ('blue', derived.b, declared.b),
            ]) {
          expect(
            (a - b).abs() * 255,
            lessThanOrEqualTo(4),
            reason:
                '--color-disabled-surface $channel in $scope: the derivation '
                'and the kit have parted company by more than the '
                'transcription gap the ledger records',
          );
        }
      }
    });

    test('the semantic extension carries the kit\'s values', () {
      // The theme extension is what a widget actually reads, so parity at
      // `AppColors` is only half the claim.
      final semanticLight = light.extension<AppSemanticColors>()!;
      final semanticDark = dark.extension<AppSemanticColors>()!;

      expect(
        semanticLight.progressFill,
        CssTokens.color('colors.css', '--color-progress-fill'),
      );
      expect(
        semanticDark.progressFill,
        CssTokens.color(
          'colors.css',
          '--color-progress-fill',
          scope: '[data-theme="dark"]',
        ),
      );
      expect(
        semanticLight.streakContainer,
        CssTokens.color('colors.css', '--color-streak-container'),
      );
      expect(
        semanticDark.streakContainer,
        CssTokens.color(
          'colors.css',
          '--color-streak-container',
          scope: '[data-theme="dark"]',
        ),
      );
    });
  });
}

/// CSS colour tokens the app deliberately has not brought over, and why.
///
/// Keyed by token so [_notBroughtOver] shrinks by itself: the completeness test
/// fails if a name here stops being declared in the kit, which is what stops a
/// reason outliving the thing it excused.
const Map<String, String> _notBroughtOver = <String, String>{
  '--color-streak':
      'The streak *label* colour, for a streak display that does not exist. '
      'Measured on its own container at 11px semibold it reads 3.12:1, under '
      'the 4.5 small text needs, so the due chip derives '
      '`onStreakContainerLight` instead — same hue to within 1.2 degrees at '
      '6.38:1. Dark needs no correction and `onStreakContainerDark` is this '
      'value unchanged. See AppColors, "Due chip".',
};

/// CSS colour tokens the app resolves by computing rather than by copying.
///
/// Each has its own test above, because "equal to the kit" is the wrong question
/// for a derivation — the right one is whether the derivation still lands where
/// the kit says. Listed here so the completeness check counts them as accounted
/// for rather than as tokens nobody has looked at.
const Map<String, String> _derived = <String, String>{
  '--color-disabled-surface':
      'Dart blends `onSurface @ 12%` over `surface` instead of hardcoding the '
      'literal, so the value follows the surface ladder when it moves. See '
      'design_system/IMPORT_LEDGER.md.',
  '--color-on-disabled':
      'Applied as `kDisabledForegroundAlpha` on the mode\'s own ink, which is '
      'exactly what the `rgb(... / 0.38)` form states.',
};
