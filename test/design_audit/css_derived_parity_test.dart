import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/components/app_button_themes.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'css_tokens.dart';

/// The kit's tokens the app resolves by **computing**, not by copying.
///
/// **A derivation cannot be checked the way a copy is.** `css_token_parity_test
/// .dart` asks whether a constant equals the kit's value; ask that of a blend
/// and it fails for a reason that is not a bug — CSS has no build-time blend, so
/// the kit carries a literal where Dart carries `onSurface @ 12% over surface`.
/// The right question is whether the derivation still *lands* where the kit
/// says, and that is what these tests ask. The `_derived` map in the token file
/// names each one, so the completeness check there counts them as accounted for
/// rather than as tokens nobody has looked at.
void main() {
  final ThemeData light = buildLightTheme();
  final ThemeData dark = buildDarkTheme();

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
