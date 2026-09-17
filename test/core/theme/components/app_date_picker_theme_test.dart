import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

/// The date picker's day resolver, in `_DatePickerDefaultsM3`'s order
/// (A20.1 P2-16).
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };
  const selectedDisabled = <WidgetState>{
    WidgetState.selected,
    WidgetState.disabled,
  };

  test(
    'a selected day that is disabled keeps the ink its fill was chosen for',
    () {
      for (final entry in themes.entries) {
        final t = entry.value;
        final picker = t.datePickerTheme;
        final Color fill = picker.dayBackgroundColor!.resolve(
          selectedDisabled,
        )!;
        final Color ink = picker.dayForegroundColor!.resolve(selectedDisabled)!;

        expect(fill, t.colorScheme.primary, reason: entry.key);
        expect(ink, t.colorScheme.onPrimary, reason: entry.key);
        expect(
          contrast(Color.alphaBlend(ink, fill), fill),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: the selected day is unreadable when disabled',
        );
      }
    },
  );

  test('a disabled day that is not selected takes the disabled ink', () {
    for (final entry in themes.entries) {
      final picker = entry.value.datePickerTheme;
      expect(
        picker.dayForegroundColor!.resolve(const <WidgetState>{
          WidgetState.disabled,
        }),
        isNot(entry.value.colorScheme.onSurface),
        reason: entry.key,
      );
    }
  });
}
