import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

/// Disabled selection controls keep their boolean, and the radio has an
/// interaction rung — A20.1 P2-15, read against `_CheckboxDefaultsM3` and
/// `_RadioDefaultsM3` at Flutter 3.44.8.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };
  const disabledOn = <WidgetState>{WidgetState.disabled, WidgetState.selected};
  const disabledOff = <WidgetState>{WidgetState.disabled};

  group('checkbox, disabled', () {
    test(
      'a ticked box fills with the disabled ink and cuts the tick in the page colour',
      () {
        for (final entry in themes.entries) {
          final t = entry.value;
          final scheme = t.colorScheme;
          final fill = t.checkboxTheme.fillColor!.resolve(disabledOn)!;
          final tick = t.checkboxTheme.checkColor!.resolve(disabledOn)!;

          expect(
            fill.a,
            lessThan(1),
            reason: '${entry.key}: the fill is the 38% ink, not a surface',
          );
          expect(
            tick,
            scheme.surface,
            reason: '${entry.key}: M3 cuts the tick in surface',
          );
          // Composited over the card, the tick still reads against its box.
          final box = Color.alphaBlend(fill, scheme.surfaceContainerLow);
          expect(contrast(tick, box), greaterThan(1.5), reason: entry.key);
        }
      },
    );

    test('a ticked box has no edge; an empty one keeps the disabled ring', () {
      for (final entry in themes.entries) {
        final side = entry.value.checkboxTheme.side! as WidgetStateBorderSide;
        expect(side.resolve(disabledOn), BorderSide.none, reason: entry.key);
        final ring = side.resolve(disabledOff)!;
        expect(ring.width, greaterThan(0), reason: entry.key);
        expect(
          ring.color.a,
          lessThan(1),
          reason: '${entry.key}: the ring is the disabled ink',
        );
      }
    });

    test('ticked and empty are two different pictures', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        final on = t.checkboxTheme.fillColor!.resolve(disabledOn)!;
        final off = t.checkboxTheme.fillColor!.resolve(disabledOff)!;
        expect(on, isNot(off), reason: '${entry.key}: the boolean is lost');
      }
    });
  });

  group('radio', () {
    test('an unselected ring darkens under press, hover and focus', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        final fill = t.radioTheme.fillColor!;
        final resting = fill.resolve(const <WidgetState>{});
        expect(resting, t.colorScheme.onSurfaceVariant, reason: entry.key);
        for (final state in <WidgetState>[
          WidgetState.pressed,
          WidgetState.hovered,
          WidgetState.focused,
        ]) {
          expect(
            fill.resolve(<WidgetState>{state}),
            t.colorScheme.onSurface,
            reason: '${entry.key}: $state has no rung',
          );
        }
        // Selected stays on its role under every interaction.
        for (final state in <WidgetState>[
          WidgetState.pressed,
          WidgetState.hovered,
          WidgetState.focused,
        ]) {
          expect(
            fill.resolve(<WidgetState>{WidgetState.selected, state}),
            t.colorScheme.primary,
            reason: '${entry.key}: selected + $state left primary',
          );
        }
      }
    });
  });
}
