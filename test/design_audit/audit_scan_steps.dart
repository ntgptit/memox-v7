import 'dart:io';

import 'package:flutter/material.dart';

import 'audit_color_math.dart';
import 'audit_theme_steps.dart';
import 'color_usage_scan.dart';
import 'token_resolver.dart';

/// The source-derived half of the colour-system audit: every colour site in
/// `lib/`, resolved and classified.
///
/// **A library, not a test file.** `flutter test` runs test files concurrently in
/// separate isolates, so an audit spread over four of them can render its report
/// from JSON another isolate is still writing. Every step is a function here and
/// `audit_test.dart` calls them in order, inside one file, where the ordering is
/// guaranteed.
///
/// Each function returns its data and writes nothing, so a caller that wants the
/// numbers does not have to touch the disk to get them.

final TokenResolver auditResolver = TokenResolver(
  light: auditLight,
  dark: auditDark,
);

/// Step 2: one record per colour-bearing expression.
Map<String, Object?> buildUsageInventory() {
  final sites = scanLib();

  final records = <Map<String, Object?>>[];
  for (final site in sites) {
    final resolved = auditResolver.resolve(site);
    records.add(<String, Object?>{
      ...site.toJson(),
      'resolved_value_light': resolved.light,
      'resolved_value_dark': resolved.dark,
    });
  }

  final byKind = <String, int>{};
  final bySource = <String, int>{};
  for (final record in records) {
    byKind.update(
      record['element_kind']! as String,
      (int n) => n + 1,
      ifAbsent: () => 1,
    );
    bySource.update(
      record['source_kind']! as String,
      (int n) => n + 1,
      ifAbsent: () => 1,
    );
  }

  return <String, Object?>{
    'generatedBy': 'test/design_audit/audit_test.dart',
    'scannedFiles': libDartFiles().length,
    'totalSites': records.length,
    'byElementKind': byKind,
    'bySourceKind': bySource,
    'sites': records,
  };
}

/// Step 3: scope classification and violation detection.
Map<String, Object?> buildViolations() {
  final sites = scanLib();
  final violations = <Map<String, Object?>>[];

  void flag(
    ColorSite site,
    String code,
    String severity,
    String why,
    String target,
  ) {
    final resolved = auditResolver.resolve(site);
    violations.add(<String, Object?>{
      'code': code,
      'severity': severity,
      'file': site.file,
      'line': site.line,
      'widget_context': site.widgetContext,
      'element_kind': site.elementKind,
      'source_kind': site.sourceKind,
      'expression': site.expression,
      'resolved_value_light': resolved.light,
      'resolved_value_dark': resolved.dark,
      'why': why,
      'proposed_target_token': target,
    });
  }

  // `app_colors.dart` is where literals are *supposed* to live, and
  // `app_theme.dart` is where they are assembled into roles. A literal there is
  // the single source of truth the model asks for, not a duplicate of it.
  const declarationSites = <String>{
    'lib/core/theme/app_colors.dart',
    'lib/core/theme/app_theme.dart',
    'lib/core/theme/app_semantic_colors.dart',
    'lib/core/theme/app_button_themes.dart',
    'lib/core/theme/app_elevation.dart',
    'lib/core/theme/app_overlay_themes.dart',
    // The state layers. Translucent by definition — an overlay's job is to
    // composite over whatever surface the control happens to sit on, so there
    // is no fixed ground to precompute against. Exactly the exemption a shadow
    // and a scrim already have, and the V5 rule below names `overlayColor` as
    // the case it means. The three sites here used to live in
    // `app_button_themes.dart`, which is on this list for the same reason.
    'lib/core/theme/app_interaction_states.dart',
  };

  for (final site in sites) {
    final isDeclaration = declarationSites.contains(site.file);

    // ---- V6: a literal in a file that cannot reach the theme --------------
    // Structural, not an exception list. A file importing only
    // `package:flutter/widgets.dart` has no `Theme.of` to call, so a token is
    // unreachable there and a literal is the only thing that can be written.
    // That is not a duplicate source of truth (V3) — it is a mode-locked
    // colour (V6), and the difference decides whether the fix is "use the
    // token" or "there is no token to use".
    if (site.sourceKind == 'hardcoded-literal' &&
        !isDeclaration &&
        !_reachesTheme(site.file) &&
        // ...and does not answer to the platform brightness by hand. A file
        // with no theme can still read `PlatformDispatcher` and pick between a
        // light and a dark constant, which is what MX-VIS-002 rule R8 asks for.
        // Without this clause the audit would keep reporting the fix as the
        // defect.
        !referencesIdentifier(site.file, 'platformBrightness')) {
      flag(
        site,
        'V6',
        '\u{1F7E1}',
        'This file imports flutter/widgets.dart only, so no ThemeData is in '
            'scope and the value cannot follow the mode. It renders the same '
            'in light and dark by construction.',
        'a const pair chosen by PlatformDispatcher.platformBrightness',
      );
      continue;
    }

    // ---- V3: a literal in a widget, where a token already exists ----------
    if (site.sourceKind == 'hardcoded-literal' && !isDeclaration) {
      final resolved = auditResolver.resolve(site);
      final match = RegExp(r'0x([0-9a-fA-F]{8})').firstMatch(site.expression);
      final value = match == null
          ? null
          : Color(int.parse(match.group(1)!, radix: 16));

      String nearest = 'no token within ΔE-ish range — needs a new one';
      if (value != null) {
        for (final entry in auditResolver.lightTable.entries) {
          if (hex(entry.value) == hex(value)) {
            nearest = entry.key;
            break;
          }
        }
      }

      // A literal in a file that cannot read the theme but *does* answer to
      // the platform brightness is a **mirror**, not a duplicate of convenience:
      // it restates a token because no other mechanism reaches it, and it moves
      // with the mode. Real V3 — same value, token available — is a different
      // problem and a different severity.
      final isUnavoidableMirror =
          !_reachesTheme(site.file) &&
          referencesIdentifier(site.file, 'platformBrightness');

      flag(
        site,
        'V3',
        isUnavoidableMirror ? '🟢' : '🟡',
        isUnavoidableMirror
            ? 'Mirrors $nearest because this file has no ThemeData in scope. It '
                  'follows the mode by reading PlatformDispatcher, so it is a '
                  'copy that cannot drift silently — but it is still a copy, and '
                  'changing the token will not change it.'
            : 'A colour literal outside the palette file. It renders the same '
                  'value in both modes, so it is also a latent V6: '
                  '${resolved.light}.',
        nearest,
      );
      continue;
    }

    // ---- V1: a material grey/white/black used as a neutral ----------------
    if (site.sourceKind == 'Colors-material') {
      final token = site.tokenName ?? 'Colors.?';
      if (token == 'Colors.transparent') {
        // Transparent is the absence of paint, not a neutral with no hue. The
        // three uses are `surfaceTintColor`, which is how Material 3 is told
        // *not* to tint an elevated surface — the tint is what would be off-model.
        continue;
      }
      flag(
        site,
        'V1',
        '🔴',
        'A Material palette colour used directly. It carries no trace of the '
            'seed and cannot follow a mode change.',
        'a seed-derived neutral in AppColors',
      );
      continue;
    }

    // ---- V5: translucency applied at the paint site -----------------------
    // Shadows and scrims are exempt, and not as a courtesy: both *are*
    // translucent washes over whatever is behind them, and an opaque one is a
    // block of colour rather than a shadow or a barrier. Same exemption
    // `overlayColor` gets — some paint has no ground to be precomputed against,
    // because the ground is whatever screen is underneath.
    if (site.sourceKind == 'opacity-modified-token' &&
        site.elementKind != 'shadow' &&
        site.elementKind != 'scrim' &&
        !isDeclaration) {
      flag(
        site,
        'V5',
        '🟢',
        'A translucent colour composites against whatever is behind it at '
            'paint time, so one token renders as two values.',
        'a precomputed blendOver(...) constant',
      );
      continue;
    }
  }

  // ---- V5 inside the theme, which is where it actually is -----------------
  // Declared separately because the loop above exempts declaration sites for
  // V3, and blanket-exempting them would hide the real ones.
  for (final site in sites) {
    if (site.sourceKind != 'opacity-modified-token') continue;
    if (!declarationSites.contains(site.file)) continue;
    if (site.elementKind != 'border' && site.elementKind != 'background') {
      continue;
    }
    flag(
      site,
      'V5',
      '🟢',
      'Translucency in a theme slot rather than a precomputed solid. The '
          'model asks for Color.alphaBlend(...) resolved at build time.',
      'a precomputed blendOver(...) constant',
    );
  }

  // ---- V1 / V6 on the tokens themselves -----------------------------------
  // Site-level scanning cannot see these: a token is off-model because of the
  // value it holds, not because of where it is used.
  final seed = auditLight.colorScheme.primary;

  // Every neutral the dump classifies as one, not a sample. A short list here
  // was the first pass's mistake: it reported three V1s where there are eight,
  // and reported no V6 at all.
  const neutralTokens = <String>[
    'colorScheme.surface',
    'colorScheme.onSurface',
    'colorScheme.onSurfaceVariant',
    'colorScheme.surfaceContainerHighest',
    'colorScheme.outline',
    'colorScheme.outlineVariant',
    'colorScheme.shadow',
    'colorScheme.scrim',
    'semantic.surfaceMuted',
    'semantic.surfaceElevated',
    'semantic.borderSubtle',
  ];

  void addTokenViolation(
    String code,
    String severity,
    String token,
    String expression,
    String why,
    String target,
  ) {
    violations.add(<String, Object?>{
      'code': code,
      'severity': severity,
      'file': 'lib/core/theme/app_colors.dart',
      'line': 0,
      'widget_context': 'AppColors',
      'element_kind': 'token',
      'source_kind': 'shared-constant',
      'expression': expression,
      'resolved_value_light': hex(auditResolver.lightTable[token]!),
      'resolved_value_dark': hex(auditResolver.darkTable[token]!),
      'why': why,
      'proposed_target_token': target,
    });
  }

  for (final token in neutralTokens) {
    final lightHue = hueOf(auditResolver.lightTable[token]!);
    final darkHue = hueOf(auditResolver.darkTable[token]!);

    for (final mode in <String, double?>{
      'light': lightHue,
      'dark': darkHue,
    }.entries) {
      if (mode.value != null) continue;
      addTokenViolation(
        'V1',
        '\u{1F534}',
        token,
        '$token (${mode.key})',
        'A pure neutral: no hue at all, so it carries no trace of the seed '
            'and cannot move with it.',
        'blendOver(seed, base, small alpha) - see migration_map.md',
      );
    }

    // V6 in its purest form: the token exists in both modes but only one of
    // them is built the same way. A shadow that carries the seed in light and
    // is pure black in dark is two mechanisms wearing one name.
    if ((lightHue == null) != (darkHue == null)) {
      addTokenViolation(
        'V6',
        '\u{1F534}',
        token,
        '$token (mechanism differs by mode)',
        'One mode derives this neutral from a hue and the other does not, so '
            'the two modes cannot drift together.',
        'derive both from the seed, or neither',
      );
    }

    // The other asymmetry the model names: a token opaque in one mode and
    // translucent in the other composites differently per mode.
    if ((auditResolver.lightTable[token]!.a == 1.0) !=
        (auditResolver.darkTable[token]!.a == 1.0)) {
      addTokenViolation(
        'V6',
        '\u{1F7E1}',
        token,
        '$token (opacity differs by mode)',
        'Opaque in one mode and translucent in the other.',
        'a precomputed blendOver(...) in both modes',
      );
    }
  }

  // Hue drift inside the neutral family. Not a code of its own in the model,
  // but it is the number that says whether "derived from seed" is true in
  // practice, so it is recorded as the lowest-severity V1 when a neutral
  // wanders further from the seed than the family's own spread.
  const maximumNeutralDrift = 20.0;
  for (final token in neutralTokens) {
    for (final mode in <String, Map<String, Color>>{
      'light': auditResolver.lightTable,
      'dark': auditResolver.darkTable,
    }.entries) {
      final distance = hueDistance(mode.value[token]!, seed);
      if (distance == null || distance <= maximumNeutralDrift) continue;
      addTokenViolation(
        'V1',
        '\u{1F7E2}',
        token,
        '$token (${mode.key}) is ${distance.round()} degrees from the seed hue',
        'It carries a hue, but not the seed. A neutral family spread this '
            'wide reads as two greys rather than one.',
        'regenerate from the seed at the same lightness',
      );
    }
  }

  return <String, Object?>{
    'generatedBy': 'test/design_audit/audit_test.dart',
    'seedUsedForHueChecks': hex(seed),
    'totalViolations': violations.length,
    'byCode': <String, int>{
      for (final code in <String>['V1', 'V2', 'V3', 'V4', 'V5', 'V6'])
        code: violations.where((v) => v['code'] == code).length,
    },
    'violations': violations,
  };
}

/// Whether [relativePath] can reach a `ThemeData` at all.
///
/// Import-based rather than a maintained list of exceptions: a file that does
/// not import Material has no `Theme.of` in scope, and that is a fact about the
/// file rather than a judgement about it. If someone later adds the Material
/// import, this stops exempting the file automatically.
bool _reachesTheme(String relativePath) {
  final file = File(relativePath);
  if (!file.existsSync()) return true;

  return file.readAsStringSync().contains(
    "import 'package:flutter/material.dart'",
  );
}
