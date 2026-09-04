import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The restyle a regex cannot follow (A20.1 §9, P1-07 d).
///
/// `no_text_restyle` watches four receiver spellings. A local binding —
/// `final TextStyle text = context.texts.bodyMedium!;` then
/// `text.copyWith(color: …)` — has a bare identifier at the `.copyWith`, and
/// no receiver pattern can reach it. This two-pass scan can: bind every local
/// whose initialiser is a text style, then flag every `.copyWith(` on a bound
/// name. Expected 0 today (`mx_search_field.dart:139` migrated with the
/// other 23); it stays as the ratchet that stops the next one.
void main() {
  final bind = RegExp(
    r'\bfinal\s+(?:TextStyle\??\s+)?(\w+)\s*=\s*([^;]*?\b(?:texts|textStyles|textTheme)\.[^;]*);',
  );

  List<String> aliasRestyles(String source, String path) {
    final stripped = source
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
    final names = bind.allMatches(stripped).map((m) => m.group(1)!).toSet();
    final findings = <String>[];
    for (final name in names) {
      final use = RegExp('\\b${RegExp.escape(name)}\\s*\\.copyWith\\s*\\(');
      for (final m in use.allMatches(stripped)) {
        final line = stripped.substring(0, m.start).split('\n').length;
        findings.add('$path:$line: $name.copyWith(');
      }
    }
    return findings;
  }

  test('no text style is restyled through a local alias', () {
    final findings = <String>[];
    for (final dir in <String>['lib/features', 'lib/shared/widgets']) {
      for (final file in Directory(dir).listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        findings.addAll(aliasRestyles(file.readAsStringSync(), file.path));
      }
    }
    expect(
      findings,
      isEmpty,
      reason:
          'a bound text style is restyled past the guard — use .inked:\n'
          '${findings.join('\n')}',
    );
  });

  test('the scan sees a synthetic alias (fault probe)', () {
    const bad = '''
final TextStyle text = context.texts.bodyMedium!;
final TextStyle hint = text.copyWith(color: colors.onSurfaceVariant);
''';
    expect(aliasRestyles(bad, 'probe.dart'), hasLength(1));
    const good = '''
final TextStyle text = context.texts.bodyMedium!;
final TextStyle hint = text.inked(context, AppInk.quiet);
final themed = ChipTheme.of(context).labelStyle;
final other = themed.copyWith(fontSize: 12);
''';
    expect(aliasRestyles(good, 'probe.dart'), isEmpty);
  });
}
