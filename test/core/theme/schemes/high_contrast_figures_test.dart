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
        // **Re-measured at M100.80, and the token moved, not the floor.**
        // `borderSubtle` was retuned lighter because almost every divider in
        // this app is drawn inside an `MxCard` — face #FFFFFF — while this
        // cell measures it against `scheme.surface`, the page ground. On white
        // the old value read 1.24 against the 1.14 recorded here, so the
        // figure this table was pinning was not the one anyone was looking at.
        //
        // The high-contrast row below is **unchanged**, which is the reason
        // this retune is safe: HC re-points the token to `onSurfaceVariant`
        // rather than deriving it from the base, so no accessibility floor
        // moves with it.
        expect(r(base.borderSubtle), isLight ? '1.08' : '1.32');
        expect(r(hc.borderSubtle), isLight ? '5.28' : '6.47');
        // Light re-measured at M100.48: the token was lightened from
        // `#6F727B` to `#7B7E88`, which is this cell moving 4.40 -> 3.71.
        // Dark is untouched. The floor assertions below are not.
        expect(r(base.borderControl), isLight ? '3.71' : '4.68');
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
