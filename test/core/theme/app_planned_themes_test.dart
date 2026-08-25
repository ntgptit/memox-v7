import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_elevation.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';

/// The four themes declared ahead of a renderer, plus the overflow menu.
///
/// **What these can and cannot check.** No screen renders them, so there is no
/// golden and no layout to assert. What there *is* — and what the admission
/// test in `app_planned_themes.dart` turns on — is that every colour they use
/// was already decided and already measured. So each test below either compares
/// a slot to the app's existing answer for the same question, or measures the
/// pair the component will actually paint. A value that cannot be checked that
/// way is a value that failed the admission test and should not be in the file.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  /// A number the user reads.
  const text = 4.5;

  /// Anything that identifies a control or its state.
  const graphic = 3.0;

  AppSemanticColors semanticOf(ThemeData t) =>
      t.extension<AppSemanticColors>()!;

  Color resolve(WidgetStateProperty<Color?>? p, Set<WidgetState> s) =>
      p!.resolve(s)!;

  group('date picker', () {
    test('is the same paper as every other dialog', () {
      // Same reason as the time picker: `_DatePickerDefaultsM3.backgroundColor`
      // is `surfaceContainerHigh` and the dialog carries Material's elevation,
      // so an unthemed date picker is the one surface with a shadow.
      for (final entry in themes.entries) {
        final picker = entry.value.datePickerTheme;
        final dialog = entry.value.dialogTheme;

        expect(picker.backgroundColor, dialog.backgroundColor);
        expect(picker.shape, dialog.shape);
        expect(picker.elevation, AppElevation.none);
      }
    });

    test('a selected day reads on its own fill', () {
      for (final entry in themes.entries) {
        final t = entry.value.datePickerTheme;
        const on = <WidgetState>{WidgetState.selected};

        expect(
          contrast(
            resolve(t.dayForegroundColor, on),
            resolve(t.dayBackgroundColor, on),
          ),
          greaterThanOrEqualTo(text),
          reason: '${entry.key}: the selected day is unreadable',
        );
      }
    });

    test("today's ring reads on the surface it is drawn on", () {
      // A ring rather than a fill is M3's answer, and it only works if the
      // ring itself clears the graphic floor — otherwise today is unmarked.
      for (final entry in themes.entries) {
        expect(
          contrast(
            entry.value.datePickerTheme.todayBorder!.color,
            entry.value.colorScheme.surface,
          ),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: today is not marked',
        );
      }
    });
  });

  group('segmented button', () {
    test('the active segment wears the app selected pair, not M3 own', () {
      // M3 uses `secondaryContainer` / `onSecondaryContainer`. The owner's
      // review moved this app's active state to the brand container, and the
      // navigation bar already renders it — a third answer here would make one
      // question look different on three screens.
      for (final entry in themes.entries) {
        final t = entry.value;
        const on = <WidgetState>{WidgetState.selected};
        final style = t.segmentedButtonTheme.style!;

        expect(
          style.backgroundColor!.resolve(on),
          t.navigationBarTheme.indicatorColor,
          reason: '${entry.key}: the active segment left the house pair',
        );
        expect(
          contrast(
            style.foregroundColor!.resolve(on)!,
            style.backgroundColor!.resolve(on)!,
          ),
          greaterThanOrEqualTo(text),
          reason: '${entry.key}: the active label is unreadable on its fill',
        );
      }
    });

    test('a resting segment is identified by its edge', () {
      for (final entry in themes.entries) {
        final side = entry.value.segmentedButtonTheme.style!.side!.resolve(
          const <WidgetState>{},
        )!;

        expect(
          contrast(side.color, entry.value.colorScheme.surface),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the segment group has no visible edge',
        );
      }
    });
  });

  group('slider', () {
    test('takes the hue at the intensity that reads', () {
      // The same token the progress indicator moved to, for the same reason.
      for (final entry in themes.entries) {
        final t = entry.value;

        expect(t.sliderTheme.activeTrackColor, semanticOf(t).focusRing);
        expect(t.sliderTheme.thumbColor, semanticOf(t).focusRing);
      }
    });

    test("M3's own pairing is what fails here, and still does", () {
      // Pins the premise rather than only the fix. `primary` on
      // `secondaryContainer` is the Material default; if the palette ever moves
      // enough for it to pass, this file's deviation is no longer earning its
      // keep and this test says so.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final m3 = contrast(scheme.primary, scheme.secondaryContainer);

        if (entry.key == 'dark') {
          expect(
            m3,
            lessThan(graphic),
            reason:
                'dark: primary on secondaryContainer now clears 3:1, so the '
                'slider could take M3 default after all',
          );
        }
      }
    });

    test('the filled half separates from the empty half', () {
      for (final entry in themes.entries) {
        final t = entry.value.sliderTheme;

        expect(
          contrast(t.activeTrackColor!, t.inactiveTrackColor!),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the slider value is unreadable',
        );
      }
    });
  });

  group('tab bar', () {
    test('the selected label is the accent, not the selection ink', () {
      // A tab's label sits on the page, not on a container fill — which is the
      // boundary `primaryAccent` and `selectedInk` were split along.
      for (final entry in themes.entries) {
        final t = entry.value;

        expect(t.tabBarTheme.labelColor, semanticOf(t).primaryAccent);
        expect(
          contrast(t.tabBarTheme.labelColor!, t.colorScheme.surface),
          greaterThanOrEqualTo(text),
          reason: '${entry.key}: the selected tab label is unreadable',
        );
      }
    });

    test('the indicator clears the graphic floor', () {
      for (final entry in themes.entries) {
        expect(
          contrast(
            entry.value.tabBarTheme.indicatorColor!,
            entry.value.colorScheme.surface,
          ),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: nothing marks the active tab',
        );
      }
    });
  });

  group('overflow menu', () {
    test('is the same paper as a dialog and a sheet', () {
      for (final entry in themes.entries) {
        final menu = entry.value.popupMenuTheme;

        expect(menu.color, entry.value.dialogTheme.backgroundColor);
        expect(menu.elevation, AppElevation.none);
        expect(menu.surfaceTintColor, Colors.transparent);
      }
    });

    test('its label reads, and its disabled label reads as disabled', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        final style = t.popupMenuTheme.labelTextStyle!;
        final ground = t.colorScheme.surface;

        final enabled = style.resolve(const <WidgetState>{})!.color!;
        final disabled = Color.alphaBlend(
          style.resolve(const <WidgetState>{WidgetState.disabled})!.color!,
          ground,
        );

        expect(contrast(enabled, ground), greaterThanOrEqualTo(text));
        expect(
          contrast(disabled, ground),
          lessThan(contrast(enabled, ground)),
          reason: '${entry.key}: a disabled menu item reads as available',
        );
      }
    });
  });
}
