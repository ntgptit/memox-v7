import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';

void main() {
  // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.6.
  test('op-glass is 0.84 and the glass blur is 18 sigma', () {
    expect(AppEffects.glassOpacity, 0.84);
    expect(AppEffects.glassBlurSigma, 18);
  });

  test('the state layer does not own glass', () {
    for (final FileSystemEntity file in Directory(
      'lib/core/theme/states',
    ).listSync()) {
      expect(
        File(file.path).readAsStringSync(),
        isNot(contains('AppEffects')),
        reason: file.path,
      );
    }
  });
}
