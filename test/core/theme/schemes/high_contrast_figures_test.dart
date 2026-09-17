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
        // **Re-measured against the v3 palette (colors_and_type.css,
        // 2026-09-17) — every cell below moved with it, not just this one.**
        // `borderSubtle` is still the plain hairline, unboosted by high
        // contrast (see the next assertion), so this is v3's `outlineVariant`
        // over the v3 page rather than a re-tune of its own.
        expect(r(base.borderSubtle), isLight ? '1.53' : '1.58');
        // **Still no swap** (M100.82, owner review, unaffected by v3). High
        // contrast takes WCAG 1.4.11's decorative exemption for this one
        // token, so the two cells stay equal and that equality is the record
        // of the decision.
        expect(r(hc.borderSubtle), r(base.borderSubtle));
        // v3 moved `outline` (GC-1), which is `borderControl`.
        expect(r(base.borderControl), isLight ? '3.44' : '3.75');
        expect(r(hc.borderControl), isLight ? '7.20' : '8.50');
        // v3 moved `primary` (GC-1), which is `borderAccent`'s base hue.
        expect(r(base.borderAccent), isLight ? '1.31' : '2.04');
        expect(r(hc.borderAccent), isLight ? '4.39' : '7.39');
        // v3 moved `onSurface` (GC-1), which `onDisabled` is struck from.
        expect(r(base.onDisabled), isLight ? '2.39' : '3.11');
        expect(r(hc.onDisabled), isLight ? '4.91' : '6.42');
        expect(
          contrast(scheme.onSurface, surface).toStringAsFixed(2),
          isLight ? '16.72' : '15.59',
        );
      });

      test('every re-pointed token clears 3:1 on the page', () {
        // The floor the palette sets for itself: WCAG 1.4.11 for the edges,
        // and the same 3:1 chosen for the disabled ink although SC 1.4.3
        // exempts it. Not lowered here, and not raised on a wrong number.
        //
        // `borderSubtle` left this list at M100.82 because it stopped being a
        // re-pointed token — it is the normal hairline in both palettes now,
        // and it is `app_high_contrast_test.dart` that holds it there.
        for (final (String name, Color token) in <(String, Color)>[
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

  // The alpha the trade is built on used to be pinned here as a bare
  // `expect(highContrastDisabledAlpha, 0.62)`. Removed when Design System V1
  // was unlocked: it asserted one tuning number and nothing about the trade.
  // What the trade actually has to satisfy is measured above and still is —
  // `onDisabled` clears the 3:1 floor over its ground and stays below half the
  // primary ink's contrast — and those hold at whatever alpha a retune picks.
}
