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

  /// Every ground an edge is drawn on in this app: a card, the page, and an
  /// inset tile. The third used to be the one `borderControl` alone did not
  /// clear, and that sentence outlived the palette by two milestones — it
  /// measures **3.39 / 3.50** there now. Re-measure before quoting it again.
  List<(String, Color)> groundsOf(ThemeData t) => <(String, Color)>[
    ('surface', t.colorScheme.surface),
    ('page', t.scaffoldBackgroundColor),
    ('muted tile', semanticOf(t).surfaceMuted),
  ];

  group('what high contrast changes', () {
    test('every border that identifies clears 3:1 on every ground', () {
      // **The exemption, and exactly how far it reaches.** WCAG 1.4.11 asks
      // 3:1 of the visual information required to *identify* a component or
      // to understand a graphic. A card is identified by its content and its
      // edge is decoration, which is the exemption the SC grants; a control's
      // boundary is not, because there the edge is the component.
      //
      // High contrast declines the exemption for the edges 1.4.11 protects —
      // `borderControl` and `borderAccent` — and **takes** it for the
      // decorative hairline. `borderSubtle` is therefore absent from this
      // list on purpose; `the decorative hairline is left at normal strength`
      // below is what holds it, from the other side.
      for (final entry in pairs.entries) {
        final hc = entry.value.$2;
        final semantic = semanticOf(hc);

        for (final border in <(String, Color)>[
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

    test('the decorative hairline is left at normal strength', () {
      // **Owner decision, 2026-09-11.** The hairline used to be re-pointed
      // here — first to `onSurfaceVariant`, then to `borderControl` — and the
      // owner reviewed both against the normal screen and rejected both: a
      // separator that announces itself is a rule ruled across the card, and
      // high contrast was turning every list into one.
      //
      // So the exemption is taken rather than declined for this one token.
      // What that costs is real and worth stating plainly: a user on high
      // contrast gets no stronger separator than anyone else. What it does
      // not cost is the SC — 1.4.11 protects the information that identifies
      // a component, and a row separator carries none; the rows are already
      // told apart by their content and their spacing.
      //
      // The strong edges are still strong: `borderControl`, `borderAccent`
      // and `outline` are asserted above.
      for (final entry in pairs.entries) {
        final (base, hc) = entry.value;

        expect(
          semanticOf(hc).borderSubtle,
          semanticOf(base).borderSubtle,
          reason:
              '${entry.key}: the hairline is being re-pointed again. Three '
              'recipes were reviewed on a rendered golden and this is the one '
              'that was chosen — moving it needs another review, not a patch.',
        );
        expect(
          hc.colorScheme.outlineVariant,
          base.colorScheme.outlineVariant,
          reason:
              '${entry.key}: the decorative Material role parted from the '
              'semantic hairline it is supposed to be',
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

    test('the Material boundary role moves with the semantic one', () {
      // `outline` is what an untended or third-party widget reads for a
      // component boundary. Left behind, one control keeps the normal edge on
      // a screen where every edge that identifies something got stronger.
      //
      // `outlineVariant` is deliberately not here: it is M3's *decorative*
      // hairline, it tracks `borderSubtle`, and both take the exemption.
      for (final entry in pairs.entries) {
        final hc = entry.value.$2;

        expect(
          contrast(hc.colorScheme.outline, hc.colorScheme.surface),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: outline was left at normal strength',
        );
      }
    });

    test('the hairline stays quieter than the edge that identifies', () {
      // **The ceiling this file never had.** High contrast pointed the
      // hairline at `onSurfaceVariant` — the secondary *label* ink — which
      // read at exactly `borderControl`'s strength, so the ladder was flat at
      // the bottom: the line that merely separates rows shouted as loudly as
      // the line that tells you where a control ends.
      //
      // A floor cannot see that. It asks whether a value is dark enough and
      // never whether it is too dark — the same door
      // `border_ladder_test.dart` was written to close for the normal themes,
      // left open on the one palette whose whole job is contrast. The
      // hairline takes the exemption now, so this holds by a wide margin; it
      // is kept because the failure it caught was a re-point creeping back up
      // to the strong token, and that is a one-line edit away in either
      // direction.
      for (final entry in pairs.entries) {
        final hc = entry.value.$2;
        final semantic = semanticOf(hc);
        final ground = hc.colorScheme.surface;

        expect(
          contrast(semantic.borderSubtle, ground),
          lessThan(contrast(semantic.borderControl, ground)),
          reason:
              '${entry.key}: the hairline that separates reads as loudly as '
              'the edge that identifies a component. The ladder is flat at the '
              'bottom, which is what made a deck-list divider read as a rule.',
        );
      }
    });

    test('the Material roles are the semantic ones, by construction', () {
      // `app_divider_theme.dart` claims "`outlineVariant` *is* `borderSubtle`
      // — the scheme maps the two onto one value". In high contrast that was
      // true by coincidence: two call sites independently re-pointed both to
      // `onSurfaceVariant`. The scheme reads the semantic palette now, so the
      // claim is structural and a future retune of one cannot leave the other
      // behind.
      for (final entry in pairs.entries) {
        final hc = entry.value.$2;
        final semantic = semanticOf(hc);

        expect(
          hc.colorScheme.outlineVariant,
          semantic.borderSubtle,
          reason: '${entry.key}: the decorative role parted from the hairline',
        );
        expect(
          hc.colorScheme.outline,
          semantic.borderControl,
          reason:
              '${entry.key}: the boundary role parted from the control edge',
        );
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
