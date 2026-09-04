import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The glyph register, the half a scan can see (A20.1 P2-19, A13 §7.2).
void main() {
  String features() {
    final buffer = StringBuffer();
    for (final file in Directory('lib/features').listSync(recursive: true)) {
      if (file is File && file.path.endsWith('.dart')) {
        buffer.writeln(
          file.readAsStringSync().replaceAll(
            RegExp(r'^\s*//.*$', multiLine: true),
            '',
          ),
        );
      }
    }
    return buffer.toString();
  }

  test('the rounded family is not a drawing style here', () {
    expect(RegExp(r'Icons\.\w+_rounded\b').allMatches(features()), isEmpty);
  });

  test('retired spellings do not come back', () {
    final source = features();
    for (final retired in <String>[
      'Icons.ios_share',
      'Icons.label_outline',
      'Icons.outlined_flag',
      'Icons.history_outlined',
      'Icons.restore_outlined',
    ]) {
      expect(source, isNot(contains(retired)), reason: retired);
    }
  });

  test('circle_outlined means "not started" and nothing else', () {
    final source = features();
    final uses = RegExp(r'Icons\.circle_outlined').allMatches(source).length;
    expect(uses, 1, reason: 'the New filter is its one home');
  });
}
