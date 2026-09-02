import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

import 'audit_color_math.dart';
import 'audit_theme_steps.dart';

/// The role half of the theme audit: V2 and V4 evidence.
///
/// Split from `audit_theme_steps.dart` at the 400-line guard, on a seam the two
/// halves already had. That file asks what the *neutrals* are; this one asks
/// whether each accent forms a family. They share the built themes and nothing
/// else.

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
