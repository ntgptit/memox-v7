import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../design_audit/audit_color_math.dart';
import '../design_audit/color_usage_scan.dart';

/// **MX-VIS-002** — the colour-system rules the M4.10f audit found worth keeping.
///
/// The audit in `design_audit/` is a one-off measurement that produces a report.
/// This file is the part of it that runs forever: four properties that hold today
/// and would be regressions if they stopped holding. Everything the audit found
/// *broken* stays in `design_audit/migration_map.md` as a proposal — a rule that
/// fails on arrival is a red suite, not a standard.
///
/// **Why these four and not the others.** The audit's headline finding is that
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

  /// Where colour literals are supposed to live. Everywhere else, a literal is a
  /// second source of truth for a value the theme already owns.
  const declarationFiles = <String>{
    'lib/core/theme/app_colors.dart',
    'lib/core/theme/app_theme.dart',
    'lib/core/theme/app_semantic_colors.dart',
    'lib/core/theme/app_button_themes.dart',
  };

  /// The one literal outside those files that is allowed, with its reason.
  ///
  /// Not a general escape hatch: it is keyed to the file *and* the value, so
  /// adding a second literal there fails even though the file is listed. An
  /// allowance that covered a whole file would grow silently, which is the
  /// failure mode `deck_audit_allowances.dart` uses exact counts to avoid.
  const allowedLiterals = <String, String>{
    'lib/app/mobile_frame_widget.dart:0xFF1E1E1E':
        'The letterbox around the phone-sized frame on the web build. It is '
        'outside the app surface entirely — the user never sees it on '
        'Android, which is the release target (AD-04) — so it is chrome for '
        'the E2E channel rather than a colour of the product.',
  };

  test('R1 — no Material palette colour is used as an app colour', () {
    // `Colors.*` is a fixed palette with no relationship to this app's seed and
    // no notion of brightness: a `Colors.grey` renders identically in both modes
    // and cannot follow a theme change.
    final offenders = scanLib()
        .where((ColorSite site) => site.sourceKind == 'Colors-material')
        .where((ColorSite site) => site.tokenName != 'Colors.transparent')
        .map((ColorSite site) => '${site.file}:${site.line} ${site.expression}')
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'Use a token from AppColors or the ColorScheme. `Colors.transparent` '
          'is the sole exception: it is the absence of paint rather than a '
          'colour, and it is how Material 3 is told not to tint an elevated '
          'surface.\n${offenders.join('\n')}',
    );
  });

  test('R2 — colour literals live only where colours are declared', () {
    final offenders = <String>[];

    for (final site in scanLib()) {
      if (site.sourceKind != 'hardcoded-literal') continue;
      if (declarationFiles.contains(site.file)) continue;

      // A file that imports only `flutter/widgets.dart` has no `Theme.of` in
      // scope, so no token is reachable and a literal is the only thing that
      // can be written. Structural, so it stops applying by itself if someone
      // adds the Material import.
      if (!_reachesTheme(site.file)) continue;

      final value = RegExp(r'0x[0-9a-fA-F]{8}').firstMatch(site.expression);
      final key = '${site.file}:${value?.group(0) ?? site.expression}';
      if (allowedLiterals.containsKey(key)) continue;

      offenders.add('${site.file}:${site.line} ${site.expression}');
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A literal here is a value the theme cannot change and the other mode '
          'never sees. Move it into AppColors and read it from the '
          'theme.\n${offenders.join('\n')}',
    );
  });

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

  test('R7 — a fill or a border is a solid colour, never a translucent one', () {
    // A translucent `BorderSide` or fill composites against whatever is behind
    // it at paint time, so one token renders as two values — over a card and
    // over a sheet — and neither is the one anybody chose. The model asks for
    // `Color.alphaBlend(...)` resolved at build time.
    //
    // **Scoped to fill and border on purpose.** `overlayColor` must be
    // translucent: a ripple that is opaque hides the label it washes over.
    // Foreground and label colours are left out too — alpha on disabled text is
    // the Material idiom and the ground under a label is always its own surface,
    // so nothing is unresolved there.
    final offenders = scanLib()
        .where((ColorSite site) => site.sourceKind == 'opacity-modified-token')
        .where(
          (ColorSite site) =>
              site.elementKind == 'border' || site.elementKind == 'background',
        )
        .map((ColorSite site) => '${site.file}:${site.line} ${site.expression}')
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'Precompute these with Color.alphaBlend over the surface they sit '
          'on.\n${offenders.join('\n')}',
    );
  });

  test('R8 — a screen that cannot read the theme still answers to the mode', () {
    // The other half of V6. A file importing only `flutter/widgets.dart` has no
    // `Theme.of` to call, so R2 lets it hold literals — but "no theme" is not
    // "no dark mode". `ErrorScreenWidget` stands in for a widget that failed,
    // including above `MaterialApp`, and a fixed light palette there means a
    // dark-mode user gets a white flash at the worst possible moment.
    //
    // `PlatformDispatcher.platformBrightness` is the mechanism that survives
    // having no inherited widgets at all, so that is what this looks for.
    final offenders = <String>[];

    for (final site in scanLib()) {
      if (site.sourceKind != 'hardcoded-literal') continue;
      if (declarationFiles.contains(site.file)) continue;
      if (_reachesTheme(site.file)) continue;

      // Parsed, not searched. The first version of this used
      // `source.contains('platformBrightness')` and **passed its own fault
      // injection**: deleting the code left the word behind in the comment
      // explaining it, so the rule matched its own prose.
      if (referencesIdentifier(site.file, 'platformBrightness')) continue;

      offenders.add(
        '${site.file}:${site.line} ${site.expression} — mode-locked',
      );
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Read PlatformDispatcher.platformBrightness and pick between a const '
          'light and a const dark value.\n${offenders.join('\n')}',
    );
  });

  test('the scan the rules above depend on actually looked at something', () {
    // Every rule here is an `isEmpty` or a loop. A scanner returning nothing
    // passes all five and reads as conformance, which is the failure this
    // project has already shipped once — six `check_suffix` rules matched zero
    // files and passed for months.
    final sites = scanLib();

    expect(sites, hasLength(greaterThan(100)));
    expect(libDartFiles(), hasLength(greaterThan(100)));
    expect(
      sites.where((ColorSite s) => s.sourceKind == 'theme-token'),
      isNotEmpty,
      reason: 'no theme-token site found — the token matcher is broken',
    );
  });
}

/// Whether [relativePath] can reach a `ThemeData` at all.
bool _reachesTheme(String relativePath) {
  final matches = libDartFiles().where(
    (file) => file.path.replaceAll(r'\', '/').endsWith(relativePath),
  );
  if (matches.isEmpty) return true;

  return matches.first.readAsStringSync().contains(
    "import 'package:flutter/material.dart'",
  );
}
