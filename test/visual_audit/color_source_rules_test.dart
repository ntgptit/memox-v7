import 'package:flutter_test/flutter_test.dart';

import '../design_audit/color_rule_scope.dart';
import '../design_audit/color_usage_scan.dart';

/// **MX-VIS-002, source half** — what `lib/` is allowed to write.
///
/// Split from `color_system_rules_test.dart` at the 400-line guard, on the seam
/// that file already had. Those rules read the built `ThemeData` and ask whether
/// the *values* are coherent; these parse `lib/` and ask whether the code is
/// allowed to name a colour at all. They share the scanner and nothing else.
void main() {
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

  test('R7 — a fill or a border is a solid colour, never a translucent one', () {
    // A translucent `BorderSide` or fill composites against whatever is behind
    // it at paint time, so one token renders as two values — over a card and
    // over a sheet — and neither is the one anybody chose. The model asks for
    // `Color.alphaBlend(...)` resolved at build time.
    //
    // **Scoped to fill and border on purpose**, and that scope now lives in
    // `isTranslucentFillViolation` rather than in this expression, because the
    // audit generator asked the same question and answered it differently. See
    // that function for the whole argument, and
    // `color_system_agreement_test.dart` for what stops them parting again.
    final offenders = scanLib()
        .where(isTranslucentFillViolation)
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
