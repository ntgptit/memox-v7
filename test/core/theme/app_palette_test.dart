import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';
import '../../support/theme_probe.dart';

/// The structural rules of **A2 Quizlet Navy Indigo**.
///
/// Readability lives in `app_theme_test.dart`; this file asserts the things a
/// contrast check cannot see — that the ladder climbs, that only the page is
/// allowed to be strongly navy, that the semantic hues stay inside their budget.
/// Every value is read from `ThemeData`, never from `AppColors`, so the subject
/// is what a screen will paint rather than what the palette intended.
void main() {
  final light = buildLightTheme();
  final dark = buildDarkTheme();
  final lightSemantic = light.extension<AppSemanticColors>()!;
  final darkSemantic = dark.extension<AppSemanticColors>()!;

  group('surface ladder', () {
    test('each tier is a visible step above the one below', () {
      // 3 L* is roughly where a step across a large flat field stops being
      // visible. Asserting the ORDER and the STEP, not the values, so a future
      // palette can move all four without this test dictating the colours.
      //
      // **Light asks for less, since M4.10i, and for a reason rather than a
      // concession.** This number was set at M3.5b when neither mode had a
      // shadow and the ladder was the entire hierarchy. Light has one now, and
      // its card also carries a seed tint that costs 1.31 L* of lightness — a
      // tint the audit's largest finding required. Holding light to a ladder
      // built for a mode with no other cue would mean choosing between a card
      // that relates to the seed and a card that sits on the page.
      //
      // What stops this being a quiet loosening: the *total* lift of a card off
      // its page is asserted separately in `app_theme_test.dart` and has not
      // moved — 7.75 L* in light against 7.70 in dark. The ladder gave some up
      // and the shadow took it on.
      const minimumStep = <String, double>{'dark': 3.0, 'light': 2.0};
      final ladders = <String, List<(String, Color)>>{
        'dark': <(String, Color)>[
          ('page', dark.scaffoldBackgroundColor),
          ('card', dark.colorScheme.surface),
          ('tile', darkSemantic.surfaceMuted),
          ('raised', darkSemantic.surfaceElevated),
        ],
        // Light inverts it: white is the ceiling, so the card is the top and
        // the inset tile sits below the page rather than above it.
        'light': <(String, Color)>[
          ('tile', lightSemantic.surfaceMuted),
          ('page', light.scaffoldBackgroundColor),
          ('card', light.colorScheme.surface),
        ],
      };

      for (final ladder in ladders.entries) {
        final tiers = ladder.value;

        for (var i = 1; i < tiers.length; i++) {
          final step =
              lightnessStar(tiers[i].$2) - lightnessStar(tiers[i - 1].$2);

          expect(
            step,
            greaterThanOrEqualTo(minimumStep[ladder.key]!),
            reason:
                '${ladder.key}: ${tiers[i - 1].$1} -> ${tiers[i].$1} is flat',
          );
        }
      }
    });

    test('the dark card does not dissolve into the page', () {
      // The specific failure of the baseline: a navy card on a navy page, told
      // apart only by its border. The flashcard is the one thing a review
      // screen exists to show, so it has to read as an object without one.
      expect(
        lightnessStar(dark.colorScheme.surface) -
            lightnessStar(dark.scaffoldBackgroundColor),
        greaterThanOrEqualTo(6.0),
      );
    });

    test('the action separates from the card it sits on', () {
      for (final entry in <String, ThemeData>{
        'light': light,
        'dark': dark,
      }.entries) {
        expect(
          contrast(
            filledButtonFill(entry.value),
            entry.value.colorScheme.surface,
          ),
          greaterThanOrEqualTo(1.5),
          reason: '${entry.key}: the button disappears into the card',
        );
      }
    });
  });

  group('only the page is strongly navy', () {
    test('every dark surface drops well below the page saturation', () {
      // The page is the one component allowed a saturated navy. Once card,
      // tile and input carry the same saturation there is no hierarchy left to
      // spend — everything is equally coloured, so nothing is emphasised.
      const share = 0.6;
      final pageSaturation = saturation(dark.scaffoldBackgroundColor);
      final ceiling = pageSaturation * share;

      for (final surface in <(String, Color)>[
        ('card', dark.colorScheme.surface),
        ('tile', darkSemantic.surfaceMuted),
        ('raised', darkSemantic.surfaceElevated),
        ('border', darkSemantic.borderSubtle),
      ]) {
        expect(
          saturation(surface.$2),
          lessThanOrEqualTo(ceiling),
          reason: '${surface.$1} is nearly as navy as the page',
        );
      }
    });

    test('the light canvas carries no lavender tint', () {
      // Measured as raw chroma, not saturation: four steps off pure white reads
      // as 22% saturation and 1.6% chroma, and only one of those numbers says
      // anything about whether a tint is visible.
      const maximumTint = 0.06;

      for (final surface in <(String, Color)>[
        ('page', light.scaffoldBackgroundColor),
        ('tile', lightSemantic.surfaceMuted),
        ('border', lightSemantic.borderSubtle),
        ('input', light.inputDecorationTheme.enabledBorder!.borderSide.color),
      ]) {
        expect(
          chroma(surface.$2),
          lessThanOrEqualTo(maximumTint),
          reason: 'light ${surface.$1} is tinted',
        );
      }
    });
  });

  group('primary', () {
    test('light and dark primary are the same brand colour', () {
      const sameFamily = 12.0;

      expect(
        (hue(light.colorScheme.primary)! - hue(dark.colorScheme.primary)!)
            .abs(),
        lessThanOrEqualTo(sameFamily),
      );
    });

    test('no dark role is bright enough to read as a light source', () {
      // **Surfaces only, and `primary` left on purpose (M100.18).** A
      // luminance cap is a fill-tone instrument: it asks "is this dark enough
      // to sit under white", which is the right question for a tone-40 fill
      // and the wrong one for the tone-80 role M3 puts in a dark scheme. The
      // rule this test was protecting — the CTA must never out-shout the card
      // — is a *relationship*, and `the action never out-shouts the card
      // content` below asserts it directly.
      //
      // The surfaces stay: the previous palette passed on `primary` alone and
      // still glared, because the top of the ladder is what an elevated widget
      // actually paints and nothing was looking at it.
      final scheme = dark.colorScheme;

      for (final role in <(String, Color)>[
        ('surfaceContainerHighest', scheme.surfaceContainerHighest),
        ('surfaceBright', scheme.surfaceBright),
      ]) {
        expect(
          luminance(role.$2),
          lessThan(0.20),
          reason: '${role.$1} glares against a deep navy page',
        );
      }
    });

    test('the action never out-shouts the card content', () {
      // "Primary must not be more prominent than the flashcard", made
      // measurable: the brightest thing against the page has to be the text on
      // the card, not the button under it.
      for (final entry in <String, ThemeData>{
        'light': light,
        'dark': dark,
      }.entries) {
        final page = entry.value.scaffoldBackgroundColor;

        expect(
          contrast(filledButtonFill(entry.value), page),
          lessThan(contrast(entry.value.colorScheme.onSurface, page)),
          reason: '${entry.key}: the CTA is the loudest thing on the page',
        );
      }
    });
  });

  group('secondary action', () {
    // **This group asserted the opposite until M100.22, and the inversion is
    // the point rather than a relaxation.** It pinned that the outlined
    // button's label is *not* `primary` and carries no hue, because
    // `AppColors.secondaryAction*` existed to keep a third colour away from the
    // study verdicts. That token was a second name for a slot
    // `_OutlinedButtonDefaultsM3.foregroundColor` already fills, so the pin
    // was holding a substitution in place: any agent restoring the canonical
    // role would have been failed by the suite for doing the right thing.
    test('is the canonical M3 role, not a substitute token', () {
      for (final entry in <String, ThemeData>{
        'light': light,
        'dark': dark,
      }.entries) {
        expect(
          outlinedButtonLabel(entry.value),
          entry.value.colorScheme.primary,
          reason:
              '${entry.key}: _OutlinedButtonDefaultsM3 names `primary` here',
        );
      }
    });

    test('reads on every ground an outlined button sits on', () {
      // The hierarchy argument the retired token was built on is still owed an
      // answer, and this is where it is owed: on the role, not on the button.
      for (final entry in <String, ThemeData>{
        'light': light,
        'dark': dark,
      }.entries) {
        final theme = entry.value;
        final label = outlinedButtonLabel(theme);

        for (final ground in <String, Color>{
          'surface': theme.colorScheme.surface,
          'page': theme.scaffoldBackgroundColor,
          'surfaceContainer': theme.colorScheme.surfaceContainer,
        }.entries) {
          expect(
            contrast(label, ground.value),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}: label on ${ground.key}',
          );
        }
      }
    });

    test('borrows no semantic colour', () {
      for (final entry in <String, ThemeData>{
        'light': light,
        'dark': dark,
      }.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;

        expect(
          <Color>[
            semantic.success,
            semantic.warning,
            semantic.danger,
            semantic.info,
          ],
          isNot(contains(outlinedButtonLabel(entry.value))),
          reason: entry.key,
        );
      }
    });
  });

  group('semantic chroma budget', () {
    test('info stays the quietest, and nothing is fully saturated', () {
      // Not equal on purpose. Four hues all at full saturation is how a study
      // tool starts looking like a game.
      //
      // **This replaced a rule that the palette outgrew at M4.10p.** Until then
      // it also asserted `danger` was the loudest, and with the old values it
      // was — light 0.676 against warning's 0.612. Adopting the design system's
      // semantic colours inverted that: light is now warning 0.801, success
      // 0.766, danger 0.634.
      //
      // The interesting part is where the disagreement lives. The design
      // system's own readme says "danger carries the most saturation, info the
      // least", so its prose and its hex values contradict each other; this repo
      // is not the party that disagrees. Values are what the project owner made
      // authoritative, so the values won, and the half of the rule they did not
      // break is kept rather than the whole rule being deleted:
      //
      //   - `info` is still the quietest in both modes, and the design agrees.
      //   - Nothing approaches full saturation. The ceiling is 0.85 rather than
      //     the old 0.70 because dark `danger` now measures 0.814 — high enough
      //     that the old number would only be re-raised on the next palette
      //     change, and low enough to still catch a raw `#FF0000`.
      //   - The four are still spread, so "deliberately unequal" keeps a test.
      const ceiling = 0.85;
      const minimumSpread = 1.5;

      for (final entry in <String, AppSemanticColors>{
        'light': lightSemantic,
        'dark': darkSemantic,
      }.entries) {
        final semantic = entry.value;
        final budget = <String, double>{
          'danger': saturation(semantic.danger),
          'success': saturation(semantic.success),
          'warning': saturation(semantic.warning),
          'info': saturation(semantic.info),
        };
        final values = budget.values.toList();

        final loudest = values.reduce((a, b) => a > b ? a : b);
        final quietest = values.reduce((a, b) => a < b ? a : b);

        expect(
          budget['info'],
          quietest,
          reason: '${entry.key}: info is not the quietest',
        );
        expect(
          loudest,
          lessThanOrEqualTo(ceiling),
          reason: '${entry.key}: a semantic colour is over budget',
        );
        expect(
          loudest / quietest,
          greaterThanOrEqualTo(minimumSpread),
          reason:
              '${entry.key}: the four semantics are too close to be a budget',
        );
      }
    });
  });
}
