import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/schemes/app_high_contrast.dart';

import '../../../support/color_math.dart';

/// The high-contrast palette's own figures, measured rather than recorded.
///
/// **A20.1 P2-11.** `app_high_contrast.dart` argued its one real trade —
/// raising `onDisabled` to 62% — on a table whose cells were carried from an
/// earlier palette: it said 4.88:1 where the composite measures 3.81:1. The
/// decision still holds (3.81 clears the 3:1 floor), but a decision taken on a
/// number 28% optimistic is not a decision, so every cell is measured here and
/// the doc table is required to say what this test says.
void main() {
  /// Contrast of [ink] over [ground], composited first: the inks carry alpha.
  double over(Color ink, Color ground) =>
      contrast(Color.alphaBlend(ink, ground), ground);

  for (final (String mode, ThemeData theme) in <(String, ThemeData)>[
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    group(mode, () {
      final scheme = theme.colorScheme;
      final base = theme.extension<AppSemanticColors>()!;
      final hc = highContrastSemantics(base, scheme);
      final surface = scheme.surface;
      final isLight = mode == 'light';

      test('the doc table is the measurement (2 dp)', () {
        String r(Color c) => over(c, surface).toStringAsFixed(2);
        expect(r(base.borderSubtle), isLight ? '1.14' : '1.41');
        expect(r(hc.borderSubtle), isLight ? '5.28' : '6.47');
        expect(r(base.borderControl), isLight ? '4.40' : '4.68');
        expect(r(hc.borderControl), isLight ? '5.28' : '6.47');
        expect(r(base.borderAccent), isLight ? '1.80' : '3.88');
        expect(r(hc.borderAccent), isLight ? '5.67' : '11.27');
        expect(r(base.onDisabled), isLight ? '2.11' : '2.62');
        expect(r(hc.onDisabled), isLight ? '3.81' : '5.12');
        expect(
          contrast(scheme.onSurface, surface).toStringAsFixed(2),
          isLight ? '11.50' : '12.01',
        );
      });

      test('every re-pointed token clears 3:1 on the page', () {
        // The floor the palette sets for itself: WCAG 1.4.11 for the edges,
        // and the same 3:1 chosen for the disabled ink although SC 1.4.3
        // exempts it. Not lowered here, and not raised on a wrong number.
        for (final (String name, Color token) in <(String, Color)>[
          ('borderSubtle', hc.borderSubtle),
          ('borderControl', hc.borderControl),
          ('borderAccent', hc.borderAccent),
          ('onDisabled', hc.onDisabled),
        ]) {
          expect(
            over(token, surface),
            greaterThanOrEqualTo(3),
            reason: '$mode $name',
          );
        }
      });

      test('the raised disabled ink still recedes below the primary ink', () {
        expect(
          over(hc.onDisabled, surface),
          lessThan(contrast(scheme.onSurface, surface) / 2),
        );
      });
    });
  }

  test('the alpha the trade is built on', () {
    expect(highContrastDisabledAlpha, 0.62);
  });
}
