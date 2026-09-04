import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Feature geometry declared as `const double` sits in the spacing guard's
/// blind spot (A20.1 P2-10): the guard sees inline literals, and a number
/// named once and used four times is invisible to it.
///
/// **The contract.** A `const double` in `lib/features/*/presentation/` is
/// either on the 4 dp grid, not a length (a ratio below 1, or a name ending
/// in Opacity / Alpha / Fraction / Factor / Fade), or carries an explicit
/// `// off-grid:` justification on the line above it. Sixteen declarations
/// were classified when the rule landed; the nine off-grid ones say why.
void main() {
  final decl = RegExp(
    r'^(?<indent>\s*)(?:static\s+)?const double (?<name>\w+) = (?<value>[0-9.]+);',
    multiLine: true,
  );
  final notALength = RegExp(r'(?:Opacity|Alpha|Fraction|Factor|Fade)$');

  List<String> offGrid(String source, String path) {
    final findings = <String>[];
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final m = decl.firstMatch(lines[i]);
      if (m == null) continue;
      final name = m.namedGroup('name')!;
      final value = double.parse(m.namedGroup('value')!);
      if (value < 1 || notALength.hasMatch(name)) continue;
      if (value % 4 == 0) continue;
      final above = i > 0 ? lines[i - 1] : '';
      if (above.contains('// off-grid:')) continue;
      findings.add('$path:${i + 1}: $name = $value');
    }
    return findings;
  }

  test('every off-grid feature length is justified', () {
    final findings = <String>[];
    for (final dir in Directory('lib/features').listSync()) {
      final presentation = Directory('${dir.path}/presentation');
      if (!presentation.existsSync()) continue;
      for (final file in presentation.listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        findings.addAll(offGrid(file.readAsStringSync(), file.path));
      }
    }
    expect(
      findings,
      isEmpty,
      reason:
          'a feature length off the 4 dp grid with no `// off-grid:` '
          'reason — token it, or say why:\n${findings.join('\n')}',
    );
  });

  test(
    'the scan flags an unjustified 18 and accepts a justified one (fault probe)',
    () {
      const bad = 'const double _flagIconSize = 18;\n';
      expect(offGrid(bad, 'probe.dart'), hasLength(1));
      const good =
          '// off-grid: between sm and md\nconst double _flagIconSize = 18;\n'
          'const double _stepHeight = 8;\n'
          'static const double dimmedOpacity = 0.7;\n'
          'const double _kMaxDragFade = 0.5;\n';
      expect(offGrid(good, 'probe.dart'), isEmpty);
    },
  );
}
