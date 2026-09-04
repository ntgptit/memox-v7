import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A spacing token names a gap on one axis. The same token as the *size* of a
/// box — both axes of one `Container`, an `Icon`'s `size:`, a `SizedBox.square`
/// `dimension:` — is a dimension wearing a gap's name, and dimensions live in
/// `AppSizing` / `AppIconSize` (A20.1 P2-12).
///
/// **Why a test and not a guard pattern.** `SizedBox(height: AppSpacing.md)`
/// is the app's idiom for a vertical gap and appears hundreds of times; a rule
/// on `height: AppSpacing.` alone would ban the design system's own spacer. The
/// tell is *both* axes, or a size slot that is never a gap — and "both axes"
/// spans lines, which a line regex cannot see.
void main() {
  test('no spacing token is used as a dimension in lib/', () {
    final pairs = RegExp(
      r'width:\s*AppSpacing\.\w+[^\n]*\n\s*height:\s*AppSpacing\.\w+',
    );
    final sizes = RegExp(r'\b(?:size|dimension):\s*AppSpacing\.\w+');
    final findings = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = _withoutComments(file.readAsStringSync());
      for (final match in pairs.allMatches(source)) {
        findings.add(
          '${file.path}: ${match.group(0)!.split('\n').first.trim()} + height',
        );
      }
      for (final match in sizes.allMatches(source)) {
        findings.add('${file.path}: ${match.group(0)}');
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          'a spacing token is a gap; a box sized by one is a dimension — use '
          'AppSizing / AppIconSize:\n${findings.join('\n')}',
    );
  });

  test('the scan sees a synthetic violation (fault probe)', () {
    const bad = '''
Container(
  width: AppSpacing.xxl,
  height: AppSpacing.xxl,
)
Icon(Icons.add, size: AppSpacing.lg)
''';
    expect(
      RegExp(
        r'width:\s*AppSpacing\.\w+[^\n]*\n\s*height:\s*AppSpacing\.\w+',
      ).hasMatch(bad),
      isTrue,
    );
    expect(
      RegExp(r'\b(?:size|dimension):\s*AppSpacing\.\w+').hasMatch(bad),
      isTrue,
    );
    // And the spacer idiom stays legal.
    expect(
      RegExp(
        r'width:\s*AppSpacing\.\w+[^\n]*\n\s*height:\s*AppSpacing\.\w+',
      ).hasMatch('const SizedBox(height: AppSpacing.md)'),
      isFalse,
    );
  });
}

String _withoutComments(String source) => source
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
