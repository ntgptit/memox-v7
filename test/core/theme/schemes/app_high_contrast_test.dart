import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';
import '../../../support/theme_probe.dart';

/// The themes `MaterialApp` reaches for when the platform reports
/// `MediaQuery.highContrast`.
///
/// **Two halves, and the second is the one that will catch something.** The
/// first says the borders got stronger, which is the feature. The second says
/// everything else stayed identical — and that is the half a future edit
/// breaks, because a high-contrast theme is built from the same seam as the
/// normal one and a change made at one call site and not the other looks like
/// nothing at all in a diff.
void main() {
  final pairs = <String, (ThemeData, ThemeData)>{
    'light': (buildLightTheme(), buildHighContrastLightTheme()),
    'dark': (buildDarkTheme(), buildHighContrastDarkTheme()),
  };

  /// WCAG 1.4.11 — what a border has to reach to identify a component.
  const graphic = 3.0;

  AppSemanticColors semanticOf(ThemeData t) =>
      t.extension<AppSemanticColors>()!;

  /// Every ground a hairline is drawn on in this app: a card, the page, and an
  /// inset tile. The third is the one `borderControl` alone does not clear.
  List<(String, Color)> groundsOf(ThemeData t) => <(String, Color)>[
    ('surface', t.colorScheme.surface),
    ('page', t.scaffoldBackgroundColor),
    ('muted tile', semanticOf(t).surfaceMuted),
  ];

  group('what high contrast changes', () {
    test('every border clears 3:1 on every ground', () {
      // The normal theme cannot do this and is not asked to: a card is
      // identified by its content and its edge is decoration, which is the
      // exemption WCAG grants. High contrast is the mode where the exemption
      // is declined.
      for (final entry in pairs.entries) {
        final hc = entry.value.$2;
        final semantic = semanticOf(hc);

        for (final border in <(String, Color)>[
          ('borderSubtle', semantic.borderSubtle),
          ('borderControl', semantic.borderControl),
          ('borderAccent', semantic.borderAccent),
        ]) {
          for (final ground in groundsOf(hc)) {
            expect(
              contrast(border.$2, ground.$2),
              greaterThanOrEqualTo(graphic),
              reason:
                  '${entry.key}: ${border.$1} on ${ground.$1} is still under '
                  'the floor in high contrast',
            );
          }
        }
      }
    });

    test('the normal theme is the one that could not, and still cannot', () {
      // Pins the premise. If the base palette ever gets strong enough on its
      // own, this fails and the whole file becomes dead weight worth deleting
      // rather than a guard worth keeping.
      for (final entry in pairs.entries) {
        final base = entry.value.$1;

        expect(
          contrast(semanticOf(base).borderSubtle, base.colorScheme.surface),
          lessThan(graphic),
          reason:
              '${entry.key}: the normal hairline now clears 3:1, so high '
              'contrast has nothing left to fix',
        );
      }
    });

    test('disabled ink becomes legible without becoming enabled', () {
      // The one swap that trades something away. Both bounds matter: under
      // 3:1 nobody can read it, and at `onSurface` nobody can tell it apart
      // from an enabled control.
      for (final entry in pairs.entries) {
        final hc = entry.value.$2;
        final ground = hc.colorScheme.surface;
        final disabled = Color.alphaBlend(semanticOf(hc).onDisabled, ground);

        expect(
          contrast(disabled, ground),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: disabled ink is still under the floor',
        );
        expect(
          contrast(disabled, ground),
          lessThan(contrast(hc.colorScheme.onSurface, ground)),
          reason: '${entry.key}: disabled ink reads as strongly as enabled ink',
        );
      }
    });

    test('the Material border roles move with the semantic ones', () {
      // `outline` and `outlineVariant` are what an untended or third-party
      // widget reads. Left behind, one control keeps the normal hairline on a
      // screen where everything around it got stronger.
      for (final entry in pairs.entries) {
        final hc = entry.value.$2;

        for (final role in <(String, Color)>[
          ('outline', hc.colorScheme.outline),
          ('outlineVariant', hc.colorScheme.outlineVariant),
        ]) {
          expect(
            contrast(role.$2, hc.colorScheme.surface),
            greaterThanOrEqualTo(graphic),
            reason: '${entry.key}: ${role.$1} was left at normal strength',
          );
        }
      }
    });
  });

  group('what high contrast must not change', () {
    test('the brand, the page and the surface ladder are untouched', () {
      // High contrast is a legibility setting, not a second design.
      for (final entry in pairs.entries) {
        final (base, hc) = entry.value;

        expect(hc.colorScheme.primary, base.colorScheme.primary);
        expect(hc.colorScheme.onPrimary, base.colorScheme.onPrimary);
        expect(hc.colorScheme.surface, base.colorScheme.surface);
        expect(hc.scaffoldBackgroundColor, base.scaffoldBackgroundColor);
        expect(semanticOf(hc).surfaceMuted, semanticOf(base).surfaceMuted);
        expect(
          semanticOf(hc).surfaceEmphasis,
          semanticOf(base).surfaceEmphasis,
        );
      }
    });

    test('the four semantic colours are untouched', () {
      for (final entry in pairs.entries) {
        final (base, hc) = entry.value;

        expect(semanticOf(hc).success, semanticOf(base).success);
        expect(semanticOf(hc).warning, semanticOf(base).warning);
        expect(semanticOf(hc).danger, semanticOf(base).danger);
        expect(semanticOf(hc).info, semanticOf(base).info);
      }
    });

    test('the filled button paints the same fill and label', () {
      // The four arguments `_light` and `_dark` carry are written once each,
      // and this is what says so from the outside: build them at two call
      // sites and one of the two goes stale unnoticed.
      for (final entry in pairs.entries) {
        final (base, hc) = entry.value;

        expect(
          filledButtonFill(hc),
          filledButtonFill(base),
          reason: '${entry.key}: the high-contrast CTA drifted off the brand',
        );
        expect(outlinedButtonLabel(hc), outlinedButtonLabel(base));
      }
    });

    test('brightness still matches the theme it stands in for', () {
      expect(buildHighContrastLightTheme().brightness, Brightness.light);
      expect(buildHighContrastDarkTheme().brightness, Brightness.dark);
    });
  });

  test('the themes are built once, like the other two', () {
    // Same reason as `app_theme_identity_test.dart`: a fresh ThemeData is
    // never `==` to the last one, so an unmemoised builder would re-notify
    // every `Theme.of` dependent on each `MemoxApp` rebuild.
    expect(
      identical(buildHighContrastLightTheme(), buildHighContrastLightTheme()),
      isTrue,
    );
    expect(
      identical(buildHighContrastDarkTheme(), buildHighContrastDarkTheme()),
      isTrue,
    );
  });
}
