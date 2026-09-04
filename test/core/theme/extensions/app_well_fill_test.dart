import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/extensions/app_well_fill.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';

/// A20.1 P2-07 — the metric well's fill is a name, and the constructor has no
/// colour left to pass.
void main() {
  test('the well takes no open colour', () {
    // Structural closure: the scan in `shared_api_closure_test.dart` cannot
    // list this file (its allowlist admits only a component's own enums), so
    // the closure is pinned on the source itself.
    final source = File(
      'lib/shared/widgets/mx_metric_well.dart',
    ).readAsStringSync();
    final constructor = RegExp(
      r'const MxMetricWell\(\{[^}]*\}\)',
      dotAll: true,
    ).firstMatch(source)!.group(0)!;
    expect(constructor, isNot(contains('Color')));
    expect(source, isNot(contains('Color? ')));
    expect(source, contains('final AppWellFill fill;'));
  });

  for (final (name, theme) in <(String, ThemeData)>[
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    testWidgets('every fill resolves to its semantic token, $name', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final semantic = context.semanticColors;
      expect(AppWellFill.muted.resolve(context), semantic.surfaceMuted);
      expect(AppWellFill.due.resolve(context), semantic.dueContainer);
      expect(AppWellFill.streak.resolve(context), semantic.streakContainer);
      expect(AppWellFill.danger.resolve(context), semantic.dangerContainer);
      expect(AppWellFill.values, hasLength(4));
    });
  }
}
