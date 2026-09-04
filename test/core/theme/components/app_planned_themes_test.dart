import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

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
    test('resolves the 2024 generation before any role is read', () {
      // A20.1 P2-06: assert the class first. Every role pin below is measured
      // against `_SliderDefaultsM3`'s 2024 slots; with `year2023` unset the
      // SDK would resolve the 2023 class for everything the theme leaves
      // undeclared, and the pins would be describing half a slider.
      for (final entry in themes.entries) {
        expect(
          // ignore: deprecated_member_use
          entry.value.sliderTheme.year2023,
          isFalse,
          reason: '${entry.key}: the slider is split across two generations',
        );
      }
    });

    test('takes the hue at the intensity that reads', () {
      // The same token the progress indicator moved to, for the same reason.
      for (final entry in themes.entries) {
        final t = entry.value;

        expect(t.sliderTheme.activeTrackColor, t.colorScheme.primary);
        expect(t.sliderTheme.thumbColor, t.colorScheme.primary);
      }
    });

    test("M3's own pairing now passes, which retired the deviation", () {
      // **The premise flipped, and this test is how it was noticed.** It used
      // to assert the opposite — that `primary` on `secondaryContainer` failed
      // 3:1 in dark, which was the whole justification for the slider reaching
      // for a substitute token. M100.18 inverted the dark accent to tone 80
      // and the Material default started passing, so the deviation stopped
      // earning its keep and the slider draws `primary` like M3 says.
      //
      // Kept as an assertion in the other direction for the same reason it was
      // written in the first: a palette that drifts back below the floor must
      // fail here rather than quietly re-introduce a substitute.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;

        expect(
          contrast(scheme.primary, scheme.secondaryContainer),
          greaterThanOrEqualTo(graphic),
          reason:
              '${entry.key}: primary no longer clears 3:1 on '
              'secondaryContainer, so a slider drawn in it is unbounded',
        );
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
    test('the selected label reads on the page it sits on', () {
      // A tab's label sits on the page, not on a container fill, which is why
      // `_TabBarDefaultsM3` inks it `primary` rather than an `on*` role. The
      // role identity is pinned in `m3_role_contract_test.dart`; this asks
      // whether it is readable where it actually lands.
      for (final entry in themes.entries) {
        final t = entry.value;

        expect(t.tabBarTheme.labelColor, t.colorScheme.primary);
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
    // **This used to assert the opposite, and the assertion was the argument.**
    // It pinned the menu to the dialog's paper at `elevation: 0` on the
    // reasoning that a menu is a small sheet. What a dialog and a sheet both
    // have and a menu does not is a scrim: they can afford `surface` because
    // 48–72% of black separates them from the page. A menu opening over a card
    // on the same paper lifted off it by 0.00 L*.
    //
    // The measurement lives in `component_depth_and_state_test.dart`; what is
    // asserted here is the distinction itself, so that restoring the old value
    // fails against the reason rather than against a number.
    test('is not the dialog paper, because a menu has no scrim', () {
      for (final entry in themes.entries) {
        final menu = entry.value.popupMenuTheme;

        expect(
          menu.color,
          isNot(entry.value.dialogTheme.backgroundColor),
          reason:
              '${entry.key}: a menu and a dialog are only alike until you ask '
              'what separates each from what is underneath it',
        );
        expect(menu.elevation, greaterThan(AppElevation.none));
        expect(menu.surfaceTintColor, Colors.transparent);
      }
    });

    test('its label reads, and its disabled label reads as disabled', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        final style = t.popupMenuTheme.labelTextStyle!;
        // The menu's own paper, not `colorScheme.surface`. They were the same
        // colour until the menu moved up a rung, and this line kept passing
        // while measuring a ground the menu no longer paints on — the same
        // mistake, in a test, that it exists to catch in the theme.
        final ground = t.popupMenuTheme.color!;

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
