import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A20.1 P1-09 — the accessor extension the guard's patterns are written
/// against is audited here, in both directions.
///
/// `ThemeContextX` is what 367 call sites reach the theme through, and every
/// restyle rule in the guard names its accessors. A sixth accessor nobody
/// listed is how a restyle spelling escapes the guard (A20 P1-02 repeated).
void main() {
  const extensionPath =
      'lib/core/theme/extensions/theme_context_extension.dart';
  const rulesPath =
      'code-verification-guard-v2/registries/projects/memox-v7/rules/'
      'memox-design-system-rules.yaml';

  /// Accessors that return a scheme rather than a style. A `.copyWith(` on a
  /// `ColorScheme` is not a restyle, and the colour rules ban the literal a
  /// caller might write instead — there is no spelling to catch on the read.
  const exempted = <String, String>{
    'colors':
        'returns ColorScheme; the colour rules guard the literal, not '
        'the read',
    'semanticColors': 'returns AppSemanticColors; same',
  };

  Set<String> publicGetters() {
    final source = File(extensionPath).readAsStringSync();
    return RegExp(
      r'^\s+[A-Za-z][A-Za-z0-9<>?, ]*\s+get\s+([a-z][A-Za-z0-9]*)',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toSet();
  }

  test(
    'every public accessor is in a guard pattern or exempted with a reason',
    () {
      final rules = File(rulesPath).readAsStringSync();
      final getters = publicGetters();
      expect(getters, isNotEmpty);

      for (final name in getters) {
        if (exempted.containsKey(name)) continue;
        expect(
          rules,
          contains('\\b$name'),
          reason:
              '`$name` is read through ThemeContextX and no guard pattern '
              'names it — a restyle through it would escape',
        );
      }
    },
  );

  test(
    'every accessor a pattern names still exists, and exemptions do too',
    () {
      final rules = File(rulesPath).readAsStringSync();
      final getters = publicGetters();

      final named = RegExp(r'\\b([a-z][A-Za-z0-9]*)(?:\[!\?\]\??|\\\.)')
          .allMatches(rules)
          .map((m) => m.group(1)!)
          .where(getters.contains)
          .toSet();
      expect(
        named,
        containsAll(<String>['texts', 'textStyles', 'inputHintStyle']),
        reason: 'the three style accessors must each be named by a pattern',
      );
      for (final name in exempted.keys) {
        expect(getters, contains(name), reason: 'stale exemption: $name');
      }
    },
  );
}
