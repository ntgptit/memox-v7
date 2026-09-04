import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A20.1 P3-01 — a contract note made mechanical.
///
/// `lib/` holds no keyboard primitive. That is correct for an Android-only
/// release target (AD-04): there is no hardware keyboard to design for, and
/// a shortcut nobody can press is a code path nobody tests. The absence is a
/// decision, and this test is where the decision is written down — the day
/// a desktop or web surface ships, it is the test to delete, not to work
/// around.
void main() {
  test('lib/ contains no keyboard primitive', () {
    const primitives = <String>[
      'Shortcuts(',
      'CallbackShortcuts(',
      'LogicalKeyboardKey.',
      'SingleActivator(',
      'KeyboardListener(',
      'onKeyEvent:',
    ];
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final primitive in primitives) {
        if (source.contains(primitive)) {
          offenders.add('${file.path}: $primitive');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
