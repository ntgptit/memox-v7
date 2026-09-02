import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../design_audit/audit_color_math.dart';

/// **MX-VIS-002** — the colour-system rules the M4.10f audit found worth keeping.
///
/// The audit in `design_audit/` is a one-off measurement that produces a report.
/// This file is the part of it that runs forever: four properties that hold today
/// and would be regressions if they stopped holding. Everything the audit found
/// *broken* stays in `design_audit/migration_map.md` as a proposal — a rule that
/// fails on arrival is a red suite, not a standard.
///
/// **The value half.** The source-scanning rules — what `lib/` may write — live
/// in `color_source_rules_test.dart`; the two were split at the 400-line guard.
///
/// **Why these and not everything the audit found.** The audit's headline finding is that
/// light `surface` is pure `#FFFFFF` with no trace of the seed. Turning that into
/// a rule would fail on the first run, and fixing it is a visible design decision
/// with a measured cost (the card-to-page step shrinks from 1.090:1 to 1.064:1).
/// That belongs to a person, not to a gate. What is below is the conformance the
/// app already has and can lose by accident.
///
/// The scanner is shared with the audit rather than reimplemented: two AST walks
/// looking for the same thing would be two answers to one question.
void main() {
  final light = buildLightTheme();
  final dark = buildDarkTheme();
  final seed = light.colorScheme.primary;

  test('R3 — every role is one hue, not a hand-picked set', () {
    // V2 and V4 from the audit, held at zero. A role whose container was picked
    // by eye drifts off its fill's hue, and the drift is invisible until the two
    // appear side by side.
    const maximumRoleSpread = 5.0;

    for (final mode in <String, ThemeData>{
      'light': light,
      'dark': dark,
    }.entries) {
      final scheme = mode.value.colorScheme;
      final families = <String, List<Color>>{
        'primary': <Color>[scheme.primary, scheme.primaryContainer],
        'secondary': <Color>[scheme.secondary, scheme.secondaryContainer],
        'tertiary': <Color>[scheme.tertiary, scheme.tertiaryContainer],
        'error': <Color>[
          scheme.error,
          scheme.errorContainer,
          mode.value.extension<AppSemanticColors>()!.danger,
        ],
      };

      for (final family in families.entries) {
        for (var i = 1; i < family.value.length; i++) {
          final distance = hueDistance(family.value.first, family.value[i]);

          expect(
            distance,
            isNotNull,
            reason:
                '${mode.key} ${family.key}: a member has no hue at all, so the '
                'family cannot be generated from one',
          );
          expect(
            distance,
            lessThanOrEqualTo(maximumRoleSpread),
            reason:
                '${mode.key} ${family.key}: member $i is '
                '${distance?.round()} degrees from the fill '
                '(${hex(family.value.first)} vs ${hex(family.value[i])}). A '
                'role must come from one hue through one generator.',
          );
        }
      }
    }
  });

  test('R4 — the neutral family does not drift further from the seed', () {
    // The audit measured light's widest neutral at 24 degrees off the seed and
    // dark's at 11. This holds that line rather than demanding it improve: the
    // improvement is a proposal in the migration map, and a ceiling here is what
    // stops the next hand-picked grey from widening the gap again.
    //
    // Neutrals with **no** hue are skipped, not passed. Five light tokens are
    // pure white and that is the audit's headline V1 — recording it here as a
    // silent pass would be worse than not checking.
    const maximumNeutralDrift = 25.0;

    for (final mode in <String, ThemeData>{
      'light': light,
      'dark': dark,
    }.entries) {
      final scheme = mode.value.colorScheme;
      final semantic = mode.value.extension<AppSemanticColors>()!;
      final neutrals = <String, Color>{
        'onSurface': scheme.onSurface,
        'onSurfaceVariant': scheme.onSurfaceVariant,
        'outline': scheme.outline,
        'outlineVariant': scheme.outlineVariant,
        'surfaceContainerHighest': scheme.surfaceContainerHighest,
        'scaffoldBackground': mode.value.scaffoldBackgroundColor,
        'surfaceMuted': semantic.surfaceMuted,
        'borderSubtle': semantic.borderSubtle,
      };

      for (final neutral in neutrals.entries) {
        final distance = hueDistance(neutral.value, seed);
        if (distance == null) continue;

        expect(
          distance,
          lessThanOrEqualTo(maximumNeutralDrift),
          reason:
              '${mode.key} ${neutral.key} (${hex(neutral.value)}) is '
              '${distance.round()} degrees from the seed ${hex(seed)}. Neutrals '
              'must read as one family; past this they read as two greys.',
        );
      }
    }
  });

  test('R9 — every neutral carries a trace of the seed', () {
    // **The audit's largest finding, promoted from a proposal to a rule at
    // M4.10i because it now passes.** Light `surface` was pure `#FFFFFF` — no
    // hue at all — along with `surfaceBright`, `surfaceContainerLowest`,
    // `surfaceElevated` and the card, dialog and sheet backgrounds that follow
    // it. The page was tinted and the thing sitting on the page was not, which
    // is why light read as a different palette from dark.
    //
    // A pure neutral is not a neutral that happens to have no hue: it is one
    // that cannot move when the seed does. That is what makes this worth a gate
    // rather than a note.
    //
    // The tint costs lightness, and the cost was paid elsewhere rather than
    // waived — see `app_elevation.dart` for the shadow alpha that was re-solved,
    // and `app_palette_test.dart` for the ladder step that gave way.
    for (final mode in <String, ThemeData>{
      'light': light,
      'dark': dark,
    }.entries) {
      final scheme = mode.value.colorScheme;
      final semantic = mode.value.extension<AppSemanticColors>()!;
      final neutrals = <String, Color>{
        'surface': scheme.surface,
        'surfaceBright': scheme.surfaceBright,
        'surfaceDim': scheme.surfaceDim,
        'surfaceContainerLowest': scheme.surfaceContainerLowest,
        'surfaceContainerLow': scheme.surfaceContainerLow,
        'surfaceContainer': scheme.surfaceContainer,
        'surfaceContainerHigh': scheme.surfaceContainerHigh,
        'surfaceContainerHighest': scheme.surfaceContainerHighest,
        'onSurface': scheme.onSurface,
        'onSurfaceVariant': scheme.onSurfaceVariant,
        'outline': scheme.outline,
        'outlineVariant': scheme.outlineVariant,
        'shadow': scheme.shadow,
        'scrim': scheme.scrim,
        'scaffoldBackground': mode.value.scaffoldBackgroundColor,
        'surfaceMuted': semantic.surfaceMuted,
        'surfaceElevated': semantic.surfaceElevated,
        'borderSubtle': semantic.borderSubtle,
      };

      // **The light paper is exempt since M100.27, by owner decision.** The
      // card is Tokyo's `#FFFFFF` verbatim, and the three roles that are the
      // card under Material's names follow it. A rule cannot ask for a tint
      // the owner has ruled out; what R9 still guards is every *other* light
      // neutral and the whole of dark.
      if (mode.key == 'light') {
        for (final paper in <String>[
          'surface',
          'surfaceBright',
          'surfaceContainerLowest',
          'surfaceElevated',
        ]) {
          neutrals.remove(paper);
        }
      }

      for (final neutral in neutrals.entries) {
        expect(
          hueOf(neutral.value),
          isNotNull,
          reason:
              '${mode.key} ${neutral.key} is ${hex(neutral.value)} — a pure '
              'neutral with no hue. Derive it from the seed: '
              'Color.alphaBlend(seed.withValues(alpha: small), base).',
        );
      }
    }
  });

  test('R5 — a token is opaque in both modes or translucent in both', () {
    // The half of V6 that holds today. A token opaque in one mode and
    // translucent in the other composites against a different backdrop per mode,
    // so one name produces two behaviours and only one of them was designed.
    for (final pair in <String, (Color, Color)>{
      'inputDecorationTheme.enabledBorder': (
        light.inputDecorationTheme.enabledBorder!.borderSide.color,
        dark.inputDecorationTheme.enabledBorder!.borderSide.color,
      ),
      'inputDecorationTheme.disabledBorder': (
        light.inputDecorationTheme.disabledBorder!.borderSide.color,
        dark.inputDecorationTheme.disabledBorder!.borderSide.color,
      ),
      'colorScheme.surface': (
        light.colorScheme.surface,
        dark.colorScheme.surface,
      ),
      'colorScheme.outline': (
        light.colorScheme.outline,
        dark.colorScheme.outline,
      ),
      'semantic.borderSubtle': (
        light.extension<AppSemanticColors>()!.borderSubtle,
        dark.extension<AppSemanticColors>()!.borderSubtle,
      ),
    }.entries) {
      final (lightValue, darkValue) = pair.value;

      expect(
        lightValue.a == 1.0,
        darkValue.a == 1.0,
        reason:
            '${pair.key}: light is ${hex(lightValue)} and dark is '
            '${hex(darkValue)}. One is translucent and the other is not.',
      );
    }
  });

  test('R6 — the shadow tokens are built the same way in both modes', () {
    // **Promoted from a report finding to a rule by a product decision.** While
    // nothing painted a shadow this was latent: light's `shadow` carried the seed
    // (`#0B0C18`, hue 235) and dark's was pure `#000000`, and neither was drawn.
    // The app is now to have real elevation, so the asymmetry becomes visible the
    // moment it is switched on — one mode dropping a seed-tinted shadow and the
    // other a flat black one.
    for (final token in <String, (Color, Color)>{
      'colorScheme.shadow': (light.colorScheme.shadow, dark.colorScheme.shadow),
      'colorScheme.scrim': (light.colorScheme.scrim, dark.colorScheme.scrim),
    }.entries) {
      final (lightValue, darkValue) = token.value;

      for (final mode in <String, Color>{
        'light': lightValue,
        'dark': darkValue,
      }.entries) {
        expect(
          hueOf(mode.value),
          isNotNull,
          reason:
              '${token.key} in ${mode.key} is ${hex(mode.value)} — a pure '
              'neutral with no hue. A shadow that carries no trace of the seed '
              'cannot move with it, and the other mode already does.',
        );
      }
    }
  });
}
