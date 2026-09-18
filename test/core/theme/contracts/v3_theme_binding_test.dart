import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_derived_colors.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/schemes/app_color_scheme.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';

/// Pins the v3 theme binding's ROUTING, DISPOSITION and COVERAGE — never a
/// value. Values are pinned once each, by the mechanism's own test
/// (`app_semantic_colors_test.dart`, `app_derived_colors_test.dart`,
/// `app_decorations_test.dart`, `app_effects_test.dart`, `app_stroke_test.dart`,
/// `app_interaction_states_test.dart`); repeating a hex here would give one
/// fact two owners.
///
/// docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §3, §9
/// step 8, §14, §15.1.
///
/// **A blind `\bname\b` scan over `lib/core/theme` produces two false
/// positives that have nothing to do with this task**, which is why every
/// "did this name become a field" check below is shape-anchored on a Dart
/// declaration instead of a bare word:
///
/// * `AppWellFill.streak` (`extensions/app_well_fill.dart`, pre-dating this
///   branch) is an unrelated enum value under the PRESERVE_ONLY word `streak`.
/// * `AppColors.seed` (`foundations/app_colors.dart`) is the palette's
///   pre-v3 generation seed, kept only for a design-system parity test — not
///   the registry's `seed`, the per-deck COMPONENT_INPUT into `IconTile`.
///
/// Both are real, current, legitimate code; a scan that flagged them would be
/// reporting a mismatch that source has no better answer to.
void main() {
  final String semanticColorsSource = File(
    'lib/core/theme/foundations/app_semantic_colors.dart',
  ).readAsStringSync();

  /// Every `final Color x;` field `AppSemanticColors` declares — the BIND_NOW
  /// `MEMOX_SEMANTIC_COLOR` mechanism, and the one place a stray field for an
  /// M3_ALIAS or a COMPONENT_INPUT/NONE name would land.
  final Set<String> semanticColorFields = RegExp(
    r'final Color (\w+);',
  ).allMatches(semanticColorsSource).map((Match m) => m.group(1)!).toSet();

  group('routing by kind (spec §3, §9 step 8)', () {
    test(
      'BIND_NOW MEMOX_SEMANTIC_COLOR: the seven are fields on AppSemanticColors',
      () {
        const List<String> bindNow = <String>[
          'mastery',
          'statusNew',
          'statusLearning',
          'statusReviewing',
          'statusMastered',
          'errorFill',
          'onErrorFill',
        ];
        for (final String name in bindNow) {
          expect(semanticColorFields, contains(name), reason: name);
        }
      },
    );

    test('M3_ALIAS gains no field of its own', () {
      for (final String name in <String>[
        'bg',
        'surfaceRaised',
        'textSecondary',
      ]) {
        expect(semanticColorFields, isNot(contains(name)), reason: name);
      }
    });

    test('COMPONENT_INPUT and NONE never became a theme field', () {
      for (final String name in <String>['accent', 'seed', 'transparent']) {
        expect(semanticColorFields, isNot(contains(name)), reason: name);
      }
    });

    test('PRESERVE_ONLY gains no field, constant or function anywhere under '
        'lib/core/theme', () {
      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity in Directory(
        'lib/core/theme',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final String source = _withoutComments(entity.readAsStringSync());
        for (final String name in _preserveOnlyNames) {
          if (_declaresColorSymbol(source, name)) {
            offenders.add('${entity.path}: $name');
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });

  group('name collisions, asserted so nobody reads one as the other', () {
    // Owner ruling 2026-09-18 (delta matrix C1b): a collision, not an alias.
    // Legacy `surfaceMuted` pre-dates #569 and resolves `surfaceContainer`;
    // v3's `surface-muted` resolves `surfaceContainerLow` — a different role
    // with a different value, kept apart on purpose.
    test(
      'surfaceMuted (legacy) is surfaceContainer, never v3 surface-muted',
      () {
        for (final ThemeData theme in <ThemeData>[
          buildLightTheme(),
          buildDarkTheme(),
        ]) {
          final AppSemanticColors semantic = theme
              .extension<AppSemanticColors>()!;
          expect(semantic.surfaceMuted, theme.colorScheme.surfaceContainer);
          expect(
            semantic.surfaceMuted,
            isNot(theme.colorScheme.surfaceContainerLow),
          );
        }
      },
    );

    // Delta matrix C1a: kept as a compatibility alias, not a second source of
    // truth. Canonical routing for `progress-track` stays
    // `ColorScheme.surfaceContainerHigh` directly (see the §15.1 map below);
    // this field is retirement debt with no call site of its own today.
    test('progressTrack is a compatibility alias of surfaceContainerHigh', () {
      for (final ThemeData theme in <ThemeData>[
        buildLightTheme(),
        buildDarkTheme(),
      ]) {
        final AppSemanticColors semantic = theme
            .extension<AppSemanticColors>()!;
        expect(semantic.progressTrack, theme.colorScheme.surfaceContainerHigh);
      }
    });
  });

  test('effect tokens stay outside the state layer', () {
    for (final FileSystemEntity entity in Directory(
      'lib/core/theme/states',
    ).listSync()) {
      if (entity is! File) continue;
      expect(
        entity.readAsStringSync(),
        isNot(contains('AppEffects')),
        reason: entity.path,
      );
    }
  });

  test('inverseSurface / onInverseSurface are the one invariant pair — '
      'asserted, not inferred', () {
    expect(lightColorScheme.inverseSurface, darkColorScheme.inverseSurface);
    expect(lightColorScheme.onInverseSurface, darkColorScheme.onInverseSurface);
  });

  test('spec §15.1 lists exactly 40 DIRECT consumer roles', () {
    // 37 table rows; one bundles the four status-* roles into a single row,
    // so the count is over distinct ROLES (36 + 4 = 40), not rows. A role
    // the spec adds later must grow one of the two maps below or this fails.
    expect(_directColorRoles.length + _directMagnitudeRoles.length, 40);
  });

  for (final (String label, ThemeData Function() build)
      in <(String, ThemeData Function())>[
        ('light', buildLightTheme),
        ('dark', buildDarkTheme),
      ]) {
    group('$label · every §15.1 DIRECT role resolves off the common theme', () {
      final ThemeData theme = build();

      for (final MapEntry<String, Color? Function(ThemeData)> entry
          in _directColorRoles.entries) {
        test(entry.key, () {
          if (entry.key == 'shadow-soft' && label == 'dark') {
            // The registry states dark shadow-soft as none. Resolving to
            // nothing IS the correct routing here, not a missing binding.
            expect(
              AppDecorations.cardWhisperShadow(theme.colorScheme),
              isEmpty,
            );
            return;
          }

          final Color? color = entry.value(theme);
          expect(color, isNotNull, reason: '${entry.key} did not resolve');

          if (entry.key == 'transparent') {
            // NONE — no theme value at all, so there is no alpha floor.
            expect(color, Colors.transparent);
            return;
          }

          expect(
            color!.a,
            greaterThan(0),
            reason: '${entry.key} resolved with zero alpha',
          );
        });
      }

      for (final MapEntry<String, double> entry
          in _directMagnitudeRoles.entries) {
        test(entry.key, () {
          expect(entry.value, greaterThan(0), reason: entry.key);
        });
      }
    });
  }
}

// --- PRESERVE_ONLY scan -----------------------------------------------------

/// 16 of the registry's 19 PRESERVE_ONLY names (spec §5.1–§5.5) — every one
/// that could plausibly land as a colour- or opacity-bearing symbol somewhere
/// under `lib/core/theme` (MEMOX_SEMANTIC_COLOR, M3_ALIAS, DERIVED_COLOR,
/// DECORATION and STATE_TOKEN shaped entries).
///
/// **Three, and only three, are deliberately absent: `success`, `warning`
/// and `danger`.** They are pre-existing repository fields that keep their
/// names (owner ruling 2026-09-18); scanning for them would report every
/// call site that already, correctly, uses one — the false positive this
/// file's other checks are built to avoid, not a gap in this one. Every other
/// PRESERVE_ONLY name is checked below; one missing with no comment here
/// would be a forgotten name, not a second deliberate exclusion.
const List<String> _preserveOnlyNames = <String>[
  'onWarning',
  'streak',
  'onStreak',
  'masteryFixed',
  'onDanger',
  'textMuted',
  'badgeBg',
  'textPrimary',
  'primarySoft',
  'primaryBorder',
  'dangerBorder',
  'successSoft',
  'warningSoft',
  'shadowNone',
  'borderStrong',
  'opHover',
];

/// Comments stripped the way `theme_layering_test.dart` already does it, so
/// this file's own doc comment — which names every one of these words — can
/// never forge a match.
String _withoutComments(String source) => source
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .replaceAll(RegExp('//.*'), '');

/// Whether [source] DECLARES [name] as a colour-bearing field, constant or
/// function — never merely mentions the word. See the file header for why a
/// bare `\bname\b` scan is the wrong tool here.
bool _declaresColorSymbol(String source, String name) => <String>[
  'final\\s+Color\\??\\s+$name\\b',
  'static\\s+const\\s+Color\\??\\s+$name\\b',
  'static\\s+const\\s+double\\s+$name\\b',
  'Color\\??\\s+get\\s+$name\\b',
  'static\\s+Color\\s+$name\\s*\\(',
  'static\\s+List<BoxShadow>\\s+$name\\s*\\(',
  'static\\s+BorderSide\\s+$name\\s*\\(',
].any((String shape) => RegExp(shape).hasMatch(source));

// --- spec §15.1 — DIRECT consumer roles -------------------------------------

/// A shadow list reduces to its first (only) coat's colour, and to `null`
/// when the registry paints none — dark `shadow-soft`.
Color? _firstShadowColor(List<BoxShadow> shadows) =>
    shadows.isEmpty ? null : shadows.first.color;

/// Every DIRECT role from spec §15.1 that resolves to a colour, keyed by the
/// registry's own name and read off the built theme through the mechanism
/// its KIND names (§5.1–§5.4). 37 entries — the 3 magnitude roles below
/// (§5.5, §5.6) make up the rest of the 40 counted above.
final Map<String, Color? Function(ThemeData)>
_directColorRoles = <String, Color? Function(ThemeData)>{
  // M3_COLOR — straight ColorScheme reads (17).
  'error': (ThemeData t) => t.colorScheme.error,
  'inversePrimary': (ThemeData t) => t.colorScheme.inversePrimary,
  'inverseSurface': (ThemeData t) => t.colorScheme.inverseSurface,
  'onInverseSurface': (ThemeData t) => t.colorScheme.onInverseSurface,
  'onPrimary': (ThemeData t) => t.colorScheme.onPrimary,
  'onSurface': (ThemeData t) => t.colorScheme.onSurface,
  'onSurfaceVariant': (ThemeData t) => t.colorScheme.onSurfaceVariant,
  'outline': (ThemeData t) => t.colorScheme.outline,
  'outlineVariant': (ThemeData t) => t.colorScheme.outlineVariant,
  'primary': (ThemeData t) => t.colorScheme.primary,
  'scrim': (ThemeData t) => t.colorScheme.scrim,
  'surface': (ThemeData t) => t.colorScheme.surface,
  'surfaceBright': (ThemeData t) => t.colorScheme.surfaceBright,
  'surfaceContainer': (ThemeData t) => t.colorScheme.surfaceContainer,
  'surfaceContainerHigh': (ThemeData t) => t.colorScheme.surfaceContainerHigh,
  'surfaceContainerHighest': (ThemeData t) =>
      t.colorScheme.surfaceContainerHighest,
  'surfaceContainerLowest': (ThemeData t) =>
      t.colorScheme.surfaceContainerLowest,

  // M3_ALIAS — its ColorScheme target; no field of its own (5).
  'bg': (ThemeData t) => t.colorScheme.surface,
  'progress-track': (ThemeData t) => t.colorScheme.surfaceContainerHigh,
  'surface-muted': (ThemeData t) => t.colorScheme.surfaceContainerLow,
  'surface-raised': (ThemeData t) => t.colorScheme.surfaceContainerLowest,
  'text-secondary': (ThemeData t) => t.colorScheme.onSurfaceVariant,

  // MEMOX_SEMANTIC_COLOR — AppSemanticColors (6).
  'error-fill': (ThemeData t) => t.extension<AppSemanticColors>()!.errorFill,
  'on-error-fill': (ThemeData t) =>
      t.extension<AppSemanticColors>()!.onErrorFill,
  'status-learning': (ThemeData t) =>
      t.extension<AppSemanticColors>()!.statusLearning,
  'status-mastered': (ThemeData t) =>
      t.extension<AppSemanticColors>()!.statusMastered,
  'status-new': (ThemeData t) => t.extension<AppSemanticColors>()!.statusNew,
  'status-reviewing': (ThemeData t) =>
      t.extension<AppSemanticColors>()!.statusReviewing,

  // DERIVED_COLOR — AppDerivedColors, each a function of the scheme (3).
  'chrome-glass': (ThemeData t) => AppDerivedColors.chromeGlass(t.colorScheme),
  'danger-soft': (ThemeData t) => AppDerivedColors.dangerSoft(t.colorScheme),
  'surface-hero': (ThemeData t) => AppDerivedColors.surfaceHero(t.colorScheme),

  // DECORATION — a shadow reduces to its first coat's colour; the
  // hairline edge to its own colour (5).
  'border-ghost': (ThemeData t) =>
      AppDecorations.hairlineEdge(t.colorScheme).color,
  'shadow-card': (ThemeData t) =>
      _firstShadowColor(AppDecorations.overlayShadow(t.colorScheme)),
  'shadow-chrome': (ThemeData t) =>
      _firstShadowColor(AppDecorations.chromeShadow(t.colorScheme)),
  'shadow-fab': (ThemeData t) =>
      _firstShadowColor(AppDecorations.fabShadow(t.colorScheme)),
  'shadow-soft': (ThemeData t) =>
      _firstShadowColor(AppDecorations.cardWhisperShadow(t.colorScheme)),

  // NONE — no theme value at all; excluded from the alpha floor (1).
  'transparent': (ThemeData t) => Colors.transparent,
};

/// The three DIRECT roles that are a magnitude, not a colour (STATE_TOKEN
/// §5.5, EFFECT_TOKEN §5.6) — "resolves" means the constant is reachable and
/// positive, not that it carries an alpha.
final Map<String, double> _directMagnitudeRoles = <String, double>{
  'op-disabled': AppStateOpacity.disabled,
  'op-press': AppStateOpacity.pressed,
  'glass-blur': AppEffects.glassBlurSigma,
};
