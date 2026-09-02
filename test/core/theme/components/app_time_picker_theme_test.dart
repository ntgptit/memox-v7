import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

/// The time picker, which is the one dialog in the app that does not read
/// `dialogTheme`.
///
/// **The first group asserts sameness, not correctness.** Every value there is
/// already decided — `dialogTheme` spends paragraphs on why a dialog is
/// `elevation: 0` with a hairline — and the only thing that could go wrong is
/// this component quietly keeping Material's own answer while the rest of the
/// app moved. So the assertions compare the two themes to each other rather
/// than to a constant: change `dialogTheme` and this either follows or fails.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  group('agrees with every other dialog', () {
    test('background, elevation and corner are the dialog theme own', () {
      for (final entry in themes.entries) {
        final picker = entry.value.timePickerTheme;
        final dialog = entry.value.dialogTheme;

        expect(
          picker.backgroundColor,
          dialog.backgroundColor,
          reason: '${entry.key}: the time picker sits on a different surface',
        );
        expect(
          picker.elevation,
          dialog.elevation,
          reason:
              '${entry.key}: the time picker carries a shadow AD-14 does not '
              'admit — Material default here is 6',
        );
        expect(
          picker.shape,
          dialog.shape,
          reason:
              '${entry.key}: the time picker has its own corner and edge — '
              'Material default here is a 28px radius with no border',
        );
      }
    });

    test('the corner is the app own card radius, not Material 28', () {
      // Belt and braces on the test above: if a future edit moved *both*
      // dialog and picker onto Material's shape, the comparison would still
      // pass. This is the value that must not drift.
      for (final entry in themes.entries) {
        final shape =
            entry.value.timePickerTheme.shape! as RoundedRectangleBorder;

        expect(
          shape.borderRadius,
          BorderRadius.circular(AppRadius.lg),
          reason: '${entry.key}: not the app card radius',
        );
        expect(entry.value.timePickerTheme.elevation, AppElevation.none);
      }
    });
  });

  group('what the picker actually paints', () {
    /// A number the user reads, at title size or larger.
    const text = 4.5;

    /// Anything that identifies a control or its state.
    const graphic = 3.0;

    Color resolve(Color? c, Set<WidgetState> states) =>
        WidgetStateProperty.resolveAs<Color>(c!, states);

    test('the selected hour reads on its own fill', () {
      // `_TimePickerDefaultsM3` inks the selected field with
      // `onPrimaryContainer` on a `primaryContainer` fill — the container's own
      // pair. This checks the pairing still reads; which roles they are is
      // pinned in `m3_role_contract_test.dart`.
      for (final entry in themes.entries) {
        final t = entry.value.timePickerTheme;
        const on = <WidgetState>{WidgetState.selected};

        expect(
          contrast(
            resolve(t.hourMinuteTextColor, on),
            resolve(t.hourMinuteColor, on),
          ),
          greaterThanOrEqualTo(text),
          reason: '${entry.key}: the selected hour is unreadable on its fill',
        );
      }
    });

    test('the resting hour reads on its own fill', () {
      for (final entry in themes.entries) {
        final t = entry.value.timePickerTheme;

        expect(
          contrast(
            resolve(t.hourMinuteTextColor, const {}),
            resolve(t.hourMinuteColor, const {}),
          ),
          greaterThanOrEqualTo(text),
          reason: '${entry.key}: the resting hour is unreadable on its fill',
        );
      }
    });

    test('the dial numbers read on the face, and on the hand', () {
      for (final entry in themes.entries) {
        final t = entry.value.timePickerTheme;

        expect(
          contrast(resolve(t.dialTextColor, const {}), t.dialBackgroundColor!),
          greaterThanOrEqualTo(text),
          reason: '${entry.key}: the dial numbers vanish into the face',
        );
        expect(
          contrast(
            resolve(t.dialTextColor, const {WidgetState.selected}),
            t.dialHandColor!,
          ),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the number under the hand is unreadable',
        );
      }
    });

    test('the AM/PM edge is the 3:1 border, not the hairline', () {
      // The day period toggle is a pair of empty boxes: exactly the case
      // `borderControl` was measured for.
      for (final entry in themes.entries) {
        final t = entry.value;

        expect(
          contrast(
            t.timePickerTheme.dayPeriodBorderSide!.color,
            t.colorScheme.surface,
          ),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the AM/PM boxes have no visible edge',
        );
      }
    });
  });
}
