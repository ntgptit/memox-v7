import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_colors.dart';
import 'package:memox/core/theme/app_material_roles.dart';
import 'package:memox/core/theme/app_interaction_states.dart';

import 'css_tokens.dart';
import 'package:memox/core/theme/app_surface_colors.dart';
import 'package:memox/core/theme/app_border_colors.dart';

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
/// Colours only, and only the ones the app **copied**. The scales — spacing,
/// radius, motion, the type ramp — are in `css_scale_parity_test.dart`; the
/// tokens Dart *derives* rather than copies are in `css_derived_parity_test
/// .dart`. Both split off at the 400-line guard, and the second split along the
/// line [_derived] already drew: "equal to the kit" is the wrong question for a
/// derivation, so those tokens were never checked the way this file checks.
void main() {
  /// The CSS colour tokens the app has brought over, by scope.
  ///
  /// Keyed by the CSS name so the completeness check below can subtract this set
  /// from the file's own declarations.
  final colorParity = <String, (Color, Color)>{
    // --- surface ladder ---
    '--color-background': (
      AppSurfaceColors.backgroundLight,
      AppSurfaceColors.backgroundDark,
    ),
    '--color-surface': (
      AppSurfaceColors.surfaceLight,
      AppSurfaceColors.surfaceDark,
    ),
    '--color-surface-muted': (
      AppSurfaceColors.surfaceMutedLight,
      AppSurfaceColors.surfaceMutedDark,
    ),
    '--color-border-option': (
      AppBorderColors.borderOptionLight,
      AppBorderColors.borderOptionDark,
    ),
    '--color-border-divider': (
      AppBorderColors.borderDividerLight,
      AppBorderColors.borderDividerDark,
    ),
    '--color-border-selected': (
      AppBorderColors.borderSelectedLight,
      AppBorderColors.borderSelectedDark,
    ),
    '--color-surface-emphasis': (
      AppSurfaceColors.surfaceEmphasisLight,
      AppSurfaceColors.surfaceEmphasisDark,
    ),
    '--color-surface-selected': (
      AppSurfaceColors.surfaceSelectedLight,
      AppSurfaceColors.surfaceSelectedDark,
    ),
    '--color-surface-elevated': (
      AppSurfaceColors.surfaceElevatedLight,
      AppSurfaceColors.surfaceElevatedDark,
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
      AppBorderColors.borderSubtleLight,
      AppBorderColors.borderSubtleDark,
    ),
    '--color-focus-ring': (AppColors.primaryLight, AppColors.primaryDark),
    // --- brand and actions ---
    '--color-seed': (AppColors.seed, AppColors.seed),
    '--color-primary': (AppColors.primaryLight, AppColors.primaryDark),
    '--color-on-primary': (AppColors.onPrimaryLight, AppColors.onPrimaryDark),
    '--color-primary-accent': (
      AppColors.primaryInkLight,
      AppColors.primaryInkDark,
    ),
    '--color-primary-container': (
      AppMaterialRoles.primaryContainerLight,
      AppMaterialRoles.primaryContainerDark,
    ),
    '--color-on-primary-container': (
      AppMaterialRoles.onPrimaryContainerLight,
      AppMaterialRoles.onPrimaryContainerDark,
    ),
    '--color-secondary': (
      AppMaterialRoles.secondaryLight,
      AppMaterialRoles.secondaryDark,
    ),
    '--color-on-secondary': (
      AppMaterialRoles.onSecondaryLight,
      AppMaterialRoles.onSecondaryDark,
    ),
    '--color-secondary-container': (
      AppMaterialRoles.secondaryContainerLight,
      AppMaterialRoles.secondaryContainerDark,
    ),
    '--color-on-secondary-container': (
      AppMaterialRoles.onSecondaryContainerLight,
      AppMaterialRoles.onSecondaryContainerDark,
    ),
    '--color-tertiary': (
      AppMaterialRoles.tertiaryLight,
      AppMaterialRoles.tertiaryDark,
    ),
    '--color-on-tertiary': (
      AppMaterialRoles.onTertiaryLight,
      AppMaterialRoles.onTertiaryDark,
    ),
    '--color-tertiary-container': (
      AppMaterialRoles.tertiaryContainerLight,
      AppMaterialRoles.tertiaryContainerDark,
    ),
    '--color-on-tertiary-container': (
      AppMaterialRoles.onTertiaryContainerLight,
      AppMaterialRoles.onTertiaryContainerDark,
    ),
    // --- meaning ---
    '--color-success': (AppColors.successLight, AppColors.successDark),
    '--color-warning': (AppColors.warningLight, AppColors.warningDark),
    '--color-danger': (AppColors.dangerLight, AppColors.dangerDark),
    '--color-info': (AppColors.infoLight, AppColors.infoDark),
    // The status containers (M100.21). `danger` has none because `error`
    // already carries this family's container — the same reason the fill map
    // above points two names at one literal.
    '--color-success-container': (
      AppColors.successContainerLight,
      AppColors.successContainerDark,
    ),
    '--color-on-success-container': (
      AppColors.onSuccessContainerLight,
      AppColors.onSuccessContainerDark,
    ),
    '--color-warning-container': (
      AppColors.warningContainerLight,
      AppColors.warningContainerDark,
    ),
    '--color-on-warning-container': (
      AppColors.onWarningContainerLight,
      AppColors.onWarningContainerDark,
    ),
    '--color-info-container': (
      AppColors.infoContainerLight,
      AppColors.infoContainerDark,
    ),
    '--color-on-info-container': (
      AppColors.onInfoContainerLight,
      AppColors.onInfoContainerDark,
    ),
    // `error` is `danger`, not a second red system — AD-05. The CSS says the
    // same thing by pointing both names at one literal.
    '--color-error': (AppColors.dangerLight, AppColors.dangerDark),
    '--color-on-error': (
      AppMaterialRoles.onErrorLight,
      AppMaterialRoles.onErrorDark,
    ),
    '--color-error-container': (
      AppMaterialRoles.errorContainerLight,
      AppMaterialRoles.errorContainerDark,
    ),
    '--color-on-error-container': (
      AppMaterialRoles.onErrorContainerLight,
      AppMaterialRoles.onErrorContainerDark,
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
      AppMaterialRoles.surfaceContainerLowestLight,
      AppMaterialRoles.surfaceContainerLowestDark,
    ),
    '--color-surface-container-low': (
      AppMaterialRoles.surfaceContainerLowLight,
      AppMaterialRoles.surfaceContainerLowDark,
    ),
    '--color-surface-container': (
      AppMaterialRoles.surfaceContainerLight,
      AppMaterialRoles.surfaceContainerDark,
    ),
    '--color-surface-container-high': (
      AppMaterialRoles.surfaceContainerHighLight,
      AppMaterialRoles.surfaceContainerHighDark,
    ),
    '--color-surface-container-highest': (
      AppMaterialRoles.surfaceContainerHighestLight,
      AppMaterialRoles.surfaceContainerHighestDark,
    ),
    '--color-surface-dim': (
      AppMaterialRoles.surfaceDimLight,
      AppMaterialRoles.surfaceDimDark,
    ),
    '--color-surface-bright': (
      AppMaterialRoles.surfaceBrightLight,
      AppMaterialRoles.surfaceBrightDark,
    ),
    '--color-inverse-surface': (
      AppMaterialRoles.inverseSurfaceLight,
      AppMaterialRoles.inverseSurfaceDark,
    ),
    '--color-on-inverse-surface': (
      AppMaterialRoles.onInverseSurfaceLight,
      AppMaterialRoles.onInverseSurfaceDark,
    ),
    '--color-inverse-primary': (
      AppMaterialRoles.inversePrimaryLight,
      AppMaterialRoles.inversePrimaryDark,
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
      // `AppStateOpacity.disabledContent` is what the disabled ink is made of.
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

        // No tolerance here. The alpha is what `AppColors.onDisabled*` is
        // built from, so a drift of 0.01 is a decision, not a rounding.
        expect(double.parse(match.group(4)!), AppStateOpacity.disabledContent);
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
}

/// CSS colour tokens the app deliberately has not brought over, and why.
///
/// Keyed by token so [_notBroughtOver] shrinks by itself: the completeness test
/// fails if a name here stops being declared in the kit, which is what stops a
/// reason outliving the thing it excused.
const Map<String, String> _notBroughtOver = <String, String>{
  '--color-secondary-action':
      'The label of a secondary (outlined) action. The app carried it as '
      '`AppColors.secondaryAction*` so that an outlined button standing beside '
      'the study verdicts would not add a third hue to that decision — a '
      'hierarchy argument, and a real one. It was still a second name for a '
      'slot Material already fills: `_OutlinedButtonDefaultsM3.foregroundColor` '
      'is `primary`, and since M100.18 inverted the dark tone that role reads '
      '7.27:1 light and 10.01:1 dark on a card. M100.22 gave the slot back to '
      'the role and dropped the token; if the study screen needs a quieter '
      'action it is `primary` that moves, not the button.',
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
