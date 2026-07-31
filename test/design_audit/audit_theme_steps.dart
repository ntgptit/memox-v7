import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../support/color_math.dart';
import 'audit_color_math.dart';

/// The theme-derived half of the colour-system audit: what the built `ThemeData`
/// holds, what the numbers say about it, and whether each role is one family.
///
/// **A library, not a test file.** `flutter test` runs test files concurrently in
/// separate isolates, so an audit spread over four of them can render its report
/// from JSON another isolate is still writing. Every step is a function here and
/// `audit_test.dart` calls them in order, inside one file, where the ordering is
/// guaranteed.
///
/// Each function returns its data and writes nothing, so a caller that wants the
/// numbers does not have to touch the disk to get them.

final ThemeData auditLight = buildLightTheme();
final ThemeData auditDark = buildDarkTheme();
final Map<String, ThemeData> auditModes = <String, ThemeData>{
  'light': auditLight,
  'dark': auditDark,
};

final modes = <String, ThemeData>{
  'light': buildLightTheme(),
  'dark': buildDarkTheme(),
};

/// Every colour the theme exposes under a stable name.
///
/// `ColorScheme` is enumerated by hand because Dart has no reflection in a
/// test binary. A role added to Material and not listed here is invisible to
/// this audit, which is why the count is asserted at the end.
Map<String, Color> auditTokensOf(ThemeData theme) {
  final s = theme.colorScheme;
  final x = theme.extension<AppSemanticColors>()!;

  return <String, Color>{
    'colorScheme.primary': s.primary,
    'colorScheme.onPrimary': s.onPrimary,
    'colorScheme.primaryContainer': s.primaryContainer,
    'colorScheme.onPrimaryContainer': s.onPrimaryContainer,
    'colorScheme.secondary': s.secondary,
    'colorScheme.onSecondary': s.onSecondary,
    'colorScheme.secondaryContainer': s.secondaryContainer,
    'colorScheme.onSecondaryContainer': s.onSecondaryContainer,
    'colorScheme.tertiary': s.tertiary,
    'colorScheme.onTertiary': s.onTertiary,
    'colorScheme.tertiaryContainer': s.tertiaryContainer,
    'colorScheme.onTertiaryContainer': s.onTertiaryContainer,
    'colorScheme.error': s.error,
    'colorScheme.onError': s.onError,
    'colorScheme.errorContainer': s.errorContainer,
    'colorScheme.onErrorContainer': s.onErrorContainer,
    'colorScheme.surface': s.surface,
    'colorScheme.onSurface': s.onSurface,
    'colorScheme.onSurfaceVariant': s.onSurfaceVariant,
    'colorScheme.surfaceDim': s.surfaceDim,
    'colorScheme.surfaceBright': s.surfaceBright,
    'colorScheme.surfaceContainerLowest': s.surfaceContainerLowest,
    'colorScheme.surfaceContainerLow': s.surfaceContainerLow,
    'colorScheme.surfaceContainer': s.surfaceContainer,
    'colorScheme.surfaceContainerHigh': s.surfaceContainerHigh,
    'colorScheme.surfaceContainerHighest': s.surfaceContainerHighest,
    'colorScheme.outline': s.outline,
    'colorScheme.outlineVariant': s.outlineVariant,
    'colorScheme.inverseSurface': s.inverseSurface,
    'colorScheme.onInverseSurface': s.onInverseSurface,
    'colorScheme.inversePrimary': s.inversePrimary,
    'colorScheme.surfaceTint': s.surfaceTint,
    'colorScheme.shadow': s.shadow,
    'colorScheme.scrim': s.scrim,
    'theme.scaffoldBackgroundColor': theme.scaffoldBackgroundColor,
    'semantic.success': x.success,
    'semantic.warning': x.warning,
    'semantic.danger': x.danger,
    'semantic.info': x.info,
    'semantic.surfaceMuted': x.surfaceMuted,
    'semantic.surfaceElevated': x.surfaceElevated,
    'semantic.borderSubtle': x.borderSubtle,
    'semantic.focusRing': x.focusRing,
    'semantic.secondaryAction': x.secondaryAction,
    // Resolved component colours, not tokens. `background`, `actionFill`,
    // `actionLabel` and `outlineLabel` are arguments to the private theme
    // builder rather than fields on the extension, so the only place their
    // final value exists is here — in the widget themes they were passed to.
    // Auditing the arguments instead would audit intent, not what paints.
    'inputDecorationTheme.enabledBorder':
        theme.inputDecorationTheme.enabledBorder!.borderSide.color,
    'inputDecorationTheme.focusedBorder':
        theme.inputDecorationTheme.focusedBorder!.borderSide.color,
    'inputDecorationTheme.disabledBorder':
        theme.inputDecorationTheme.disabledBorder!.borderSide.color,
    'cardTheme.color': theme.cardTheme.color!,
    'dividerTheme.color': theme.dividerTheme.color ?? s.outlineVariant,
    'navigationBarTheme.backgroundColor':
        theme.navigationBarTheme.backgroundColor!,
    'navigationBarTheme.indicatorColor':
        theme.navigationBarTheme.indicatorColor!,
    'dialogTheme.backgroundColor': theme.dialogTheme.backgroundColor!,
    'bottomSheetTheme.backgroundColor': theme.bottomSheetTheme.backgroundColor!,
    'appBarTheme.backgroundColor': theme.appBarTheme.backgroundColor!,
  };
}

/// Tokens the model calls **neutral** — the ones that must carry a trace of the
/// seed rather than being a grey of their own.
///
/// Text is in here because the model names muted text as a neutral. `onSurface`
/// and `onSurfaceVariant` are therefore judged by hue, not by contrast; their
/// contrast is already asserted in `app_theme_test.dart`.
const neutrals = <String>{
  'colorScheme.surface',
  'colorScheme.onSurface',
  'colorScheme.onSurfaceVariant',
  'colorScheme.surfaceDim',
  'colorScheme.surfaceBright',
  'colorScheme.surfaceContainerLowest',
  'colorScheme.surfaceContainerLow',
  'colorScheme.surfaceContainer',
  'colorScheme.surfaceContainerHigh',
  'colorScheme.surfaceContainerHighest',
  'colorScheme.outline',
  'colorScheme.outlineVariant',
  'colorScheme.shadow',
  'colorScheme.scrim',
  'theme.scaffoldBackgroundColor',
  'semantic.surfaceMuted',
  'semantic.surfaceElevated',
  'semantic.borderSubtle',
  'inputDecorationTheme.enabledBorder',
  'inputDecorationTheme.disabledBorder',
  'cardTheme.color',
  'dividerTheme.color',
  'navigationBarTheme.backgroundColor',
  'dialogTheme.backgroundColor',
  'bottomSheetTheme.backgroundColor',
  'appBarTheme.backgroundColor',
};

/// Step 1: every theme colour, with its distance from each seed hypothesis.
Map<String, Object?> buildTokenDump() {
  final out = <String, Object?>{
    'generatedBy': 'test/design_audit/audit_test.dart',
    'note':
        'Values are what the built ThemeData holds, not what AppColors '
        'declares. ColorScheme.fromSeed fills roles this app then overrides.',
  };

  // **Two seed hypotheses, reported separately**, because the audit brief and
  // the code disagree about which one the neutrals should track. The brief
  // names a `#0B1220` dark-surface family; this app's dark page is `#0A082D`
  // and its declared seed is `AppColors.seed`, which is `primaryLight`. Picking
  // one silently would hide that disagreement, so both are measured.
  final seedFromPrimary = auditModes['light']!.colorScheme.primary;
  final seedFromDarkSurface = auditModes['dark']!.scaffoldBackgroundColor;

  out['seedHypotheses'] = <String, Object?>{
    'declaredSeed_colorSchemePrimaryLight': <String, Object?>{
      'hex': hex(seedFromPrimary),
      'hue': hueOf(seedFromPrimary),
      'note': 'AppColors.seed is AppColors.primaryLight',
    },
    'darkSurfaceFamily_scaffoldBackgroundDark': <String, Object?>{
      'hex': hex(seedFromDarkSurface),
      'hue': hueOf(seedFromDarkSurface),
      'note':
          'The audit brief names #0B1220 for this family. The app ships '
          '#0A082D. Reported as found, not as briefed.',
    },
    'hueDeltaBetweenHypotheses': hueDistance(
      seedFromPrimary,
      seedFromDarkSurface,
    ),
  };

  for (final mode in auditModes.entries) {
    final tokens = auditTokensOf(mode.value);
    final rows = <String, Object?>{};

    for (final token in tokens.entries) {
      final isNeutral = neutrals.contains(token.key);

      rows[token.key] = <String, Object?>{
        'hex': hex(token.value),
        'opaque': token.value.a == 1.0,
        'hue': hueOf(token.value),
        'saturation': saturation(token.value),
        'chroma': chroma(token.value),
        'lightnessStar': lightnessStar(token.value),
        'classifiedAs': isNeutral ? 'neutral' : 'role-or-on-color',
        if (isNeutral) ...<String, Object?>{
          'hueDistanceFromDeclaredSeed': hueDistance(
            token.value,
            seedFromPrimary,
          ),
          'hueDistanceFromDarkSurfaceFamily': hueDistance(
            token.value,
            seedFromDarkSurface,
          ),
          // Null hue on a neutral is the V1 signal: a true grey carries no
          // trace of any seed, so there is no distance to report and that
          // absence is the finding.
          'carriesNoHue': hueOf(token.value) == null,
        },
      };
    }

    out[mode.key] = rows;
  }

  return out;
}

/// Step 4: the perceptual checks the brief asks for.
Map<String, Object?> buildPerceptualChecks() {
  final out = <String, Object?>{
    'generatedBy': 'test/design_audit/audit_test.dart',
  };

  for (final mode in auditModes.entries) {
    final theme = mode.value;
    final s = theme.colorScheme;
    final x = theme.extension<AppSemanticColors>()!;

    // Border prominence, against the ground each border is actually drawn on.
    // Two grounds per border because both are real: `MxCard`'s border sits on
    // the card it outlines *and* against the page around it, and a value that
    // reads as an edge on one can read as a frame on the other.
    final borders = <String, Color>{
      'semantic.borderSubtle': x.borderSubtle,
      'colorScheme.outline': s.outline,
      'colorScheme.outlineVariant': s.outlineVariant,
    };
    final grounds = <String, Color>{
      'card (colorScheme.surface)': s.surface,
      'page (scaffoldBackgroundColor)': theme.scaffoldBackgroundColor,
      'muted tile (semantic.surfaceMuted)': x.surfaceMuted,
    };

    final prominence = <String, Object?>{};
    for (final border in borders.entries) {
      for (final ground in grounds.entries) {
        final ratio = contrast(border.value, ground.value);
        prominence['${border.key} on ${ground.key}'] = <String, Object?>{
          'ratio': ratio,
          // The brief's band. Below the floor the border is not there; above
          // the ceiling it stops defining an edge and starts drawing a frame.
          'verdict': ratio < 1.06
              ? 'invisible'
              : ratio > 1.6
              ? 'too-heavy'
              : 'in-band',
        };
      }
    }

    final bg = theme.scaffoldBackgroundColor;
    final surface = s.surface;

    out[mode.key] = <String, Object?>{
      'borderProminence': prominence,
      'backgroundTint': <String, Object?>{
        'page': <String, Object?>{
          'hex': hex(bg),
          'hue': hueOf(bg),
          'saturation': saturation(bg),
          'chroma': chroma(bg),
          'isPureNeutral': hueOf(bg) == null,
        },
        'surface': <String, Object?>{
          'hex': hex(surface),
          'hue': hueOf(surface),
          'saturation': saturation(surface),
          'chroma': chroma(surface),
          'isPureNeutral': hueOf(surface) == null,
        },
      },
      'neutralFamilyCoherence': <String, Object?>{
        for (final entry in <String, Color>{
          'page': bg,
          'surface': surface,
          'surfaceMuted': x.surfaceMuted,
          'borderSubtle': x.borderSubtle,
          'onSurfaceVariant': s.onSurfaceVariant,
        }.entries)
          entry.key: <String, Object?>{
            'hex': hex(entry.value),
            'hue': hueOf(entry.value),
            'chroma': chroma(entry.value),
          },
      },
      // The whole of the depth model, stated as one number per mode so the
      // asymmetry check in the report is arithmetic rather than opinion.
      'depthMechanism': <String, Object?>{
        'surfaceVsPage': contrast(surface, bg),
        'borderVsSurface': contrast(x.borderSubtle, surface),
        'borderVsPage': contrast(x.borderSubtle, bg),
        'usesShadow': false,
        'shadowNote':
            'cardTheme.elevation is 0 and MxCard paints no BoxShadow; depth '
            'is border-only in both modes by design.',
      },
    };
  }

  return out;
}

/// V2 and V4 evidence: does each role come from one hue through one generator?
Map<String, Object?> buildRoleFamilies() {
  // V2 and V4 ask whether each role's fill / onFill / container / border came
  // from one hue. Answered on the tokens rather than on the call sites: a
  // component that reads `semantic.danger` is correct by construction, and the
  // question is whether `danger`'s own family holds together.
  final rows = <String, Object?>{};

  for (final mode in auditModes.entries) {
    final s = mode.value.colorScheme;
    final x = mode.value.extension<AppSemanticColors>()!;

    final roles = <String, Map<String, Color>>{
      'primary': <String, Color>{
        'fill': s.primary,
        'onFill': s.onPrimary,
        'container': s.primaryContainer,
        'onContainer': s.onPrimaryContainer,
      },
      'error/danger': <String, Color>{
        'fill': s.error,
        'onFill': s.onError,
        'container': s.errorContainer,
        'onContainer': s.onErrorContainer,
        'semanticDanger': x.danger,
      },
      'success': <String, Color>{'fill': x.success},
      'warning': <String, Color>{'fill': x.warning},
      'info': <String, Color>{'fill': x.info},
    };

    rows[mode.key] = <String, Object?>{
      for (final role in roles.entries)
        role.key: <String, Object?>{
          'members': <String, Object?>{
            for (final member in role.value.entries)
              member.key: <String, Object?>{
                'hex': hex(member.value),
                'hue': hueOf(member.value),
              },
          },
          // The V4 signal. `on*` colours are excluded from the spread because
          // they are legitimately the opposite end of the ramp and would
          // dominate the number without saying anything about the family.
          'hueSpreadExcludingOnColors': hueSpread(<Color>[
            for (final member in role.value.entries)
              if (!member.key.startsWith('on')) member.value,
          ]),
          'hasContainerPair': role.value.containsKey('container'),
          'hasBorderToken': false,
          'hasFocusToken': role.key == 'primary',
        },
    };
  }

  return <String, Object?>{
    'generatedBy': 'test/design_audit/audit_test.dart',
    'note':
        'hasBorderToken and hasFocusToken record what the target model asks '
        'for, not what a role needs today. A false is a gap in the model, '
        'not necessarily a defect on screen.',
    'roles': rows,
  };
}

/// The widest hue gap in a set, or null when any member is a true neutral.
double? hueSpread(List<Color> colors) {
  final hues = <double>[];
  for (final color in colors) {
    final hue = hueOf(color);
    if (hue == null) return null;
    hues.add(hue);
  }
  if (hues.length < 2) return 0;

  var widest = 0.0;
  for (var i = 0; i < hues.length; i++) {
    for (var j = i + 1; j < hues.length; j++) {
      final raw = (hues[i] - hues[j]).abs();
      final distance = raw > 180 ? 360 - raw : raw;
      if (distance > widest) widest = distance;
    }
  }

  return widest;
}
