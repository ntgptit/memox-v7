import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The companion assertion `no_raw_loading_indicator` cannot make itself
/// (A20.1 §9, assertion 4).
///
/// A file-level `exclude:` says "this file may build a progress indicator";
/// it does not say "and only a determinate one". So every construction in
/// every excluded file is walked here, and each must name a non-null
/// `value:` — a loading spinner added to an excluded file fails this test
/// instead of inheriting the exemption.
void main() {
  const rules =
      'code-verification-guard-v2/registries/projects/memox-v7/rules/'
      'memox-design-system-rules.yaml';
  const ruleId = 'memox_v7.design_system.no_raw_loading_indicator';

  List<String> excludedFiles() {
    final yaml = File(rules).readAsStringSync();
    final start = yaml.indexOf('- id: $ruleId');
    expect(start, greaterThan(-1), reason: 'the rule is gone');
    final end = yaml.indexOf('\n  - id:', start + 1);
    final block = yaml.substring(start, end < 0 ? yaml.length : end);
    final exclude = RegExp(r"^\s+- '([^']+)'", multiLine: true)
        .allMatches(block.substring(block.indexOf('exclude:')))
        .map((m) => m.group(1)!)
        .takeWhile((g) => !g.startsWith('^'))
        .toList();
    return exclude;
  }

  /// Every `…ProgressIndicator(` construction in [source], with its argument
  /// list — a balanced-paren walk, comments stripped first.
  List<String> constructions(String source) {
    final stripped = source
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
    final found = <String>[];
    final pattern = RegExp(
      r'\b(?:Circular|Linear)ProgressIndicator(?:\.adaptive)?\s*\(',
    );
    for (final match in pattern.allMatches(stripped)) {
      var depth = 0;
      var i = match.end - 1;
      for (; i < stripped.length; i++) {
        final c = stripped[i];
        if (c == '(') depth++;
        if (c == ')') {
          depth--;
          if (depth == 0) break;
        }
      }
      found.add(stripped.substring(match.start, i + 1));
    }
    return found;
  }

  test('the exclude list names only determinate progress files', () {
    final files = excludedFiles();
    expect(files, isNotEmpty, reason: 'the ring lost its exemption');

    for (final glob in files) {
      final matches = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) => f.path
                .replaceAll(r'\', '/')
                .endsWith(glob.replaceFirst('**/', '')),
          )
          .toList();
      expect(matches, isNotEmpty, reason: '$glob matches no file');

      for (final file in matches) {
        final calls = constructions(file.readAsStringSync());
        expect(calls, isNotEmpty, reason: '${file.path}: excluded for nothing');
        for (final call in calls) {
          expect(
            RegExp(r'\bvalue\s*:\s*(?!null\b)').hasMatch(call),
            isTrue,
            reason:
                '${file.path}: an indeterminate indicator inherits the '
                'determinate exemption — use MxLoadingState:\n$call',
          );
          // A20.1 §24 #19: the exemption is from the *loading* owner, not
          // from having a name. A determinate ring still says what it is.
          expect(
            RegExp(r'\bsemanticsLabel\s*:').hasMatch(call),
            isTrue,
            reason: '${file.path}: a progress indicator with no name:\n$call',
          );
        }
      }
    }
  });

  test('the walk sees an indeterminate spinner (fault probe)', () {
    final calls = constructions('''
Positioned.fill(child: CircularProgressIndicator(value: fraction, strokeWidth: 6)),
// CircularProgressIndicator() in a comment is prose
child: const CircularProgressIndicator(),
''');
    expect(calls, hasLength(2));
    expect(RegExp(r'\bvalue\s*:').hasMatch(calls.first), isTrue);
    expect(RegExp(r'\bvalue\s*:').hasMatch(calls.last), isFalse);
  });
}
