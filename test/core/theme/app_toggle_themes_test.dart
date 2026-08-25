import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_interaction_states.dart';
import 'package:memox/core/theme/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../support/color_math.dart';

/// The switch and the checkbox, which rendered through Material's defaults
/// until M99.48.
///
/// **What these assert is the pair, never the token.** A thumb colour is right
/// or wrong only against the track it sits on, and Material's own default —
/// `outline` on `surfaceContainerHighest` — is the version that reads fine as
/// two token names and measures 2.79:1 as a pair. So every check below resolves
/// both halves from the built theme and divides them.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  /// WCAG 1.4.11 — the floor for anything that identifies a control or its
  /// state.
  const graphic = 3.0;

  Color thumb(ThemeData t, Set<WidgetState> states) =>
      t.switchTheme.thumbColor!.resolve(states)!;
  Color track(ThemeData t, Set<WidgetState> states) =>
      t.switchTheme.trackColor!.resolve(states)!;
  Color trackEdge(ThemeData t, Set<WidgetState> states) =>
      t.switchTheme.trackOutlineColor!.resolve(states)!;
  // `CheckboxThemeData.side` is typed `BorderSide?`, and the theme puts a
  // `WidgetStateBorderSide` in it — a BorderSide that is also a state property.
  // The cast is what lets a test ask for one state; a widget gets the same
  // resolution done for it by `Checkbox` itself.
  BorderSide box(ThemeData t, Set<WidgetState> states) =>
      (t.checkboxTheme.side! as WidgetStateBorderSide).resolve(states)!;

  group('switch', () {
    test('the thumb reads against its track in both states', () {
      // The thumb IS the state — which side it sits on is the whole answer —
      // so this is the measurement the control cannot ship without.
      for (final entry in themes.entries) {
        final t = entry.value;

        expect(
          contrast(thumb(t, const {}), track(t, const {})),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the resting thumb disappears into its track',
        );
        expect(
          contrast(
            thumb(t, const {WidgetState.selected}),
            track(t, const {WidgetState.selected}),
          ),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the selected thumb disappears into its track',
        );
      }
    });

    test('Material default thumb would have failed this', () {
      // Pins the reason for the departure rather than only its result. If a
      // later edit puts the thumb back on `outline`, this says what breaks.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;

        expect(
          contrast(scheme.outline, track(entry.value, const {})),
          lessThan(graphic),
          reason:
              '${entry.key}: `outline` now clears the floor on the resting '
              'track, so the note in buildSwitchTheme is out of date',
        );
      }
    });

    test('the track is bounded against the surface in both states', () {
      // Off, the fill is a near-surface muted tile and the outline does it.
      // On, the fill is `primary` — 7.27:1 in light but 2.90:1 in dark — so
      // the outline changes colour rather than disappearing the way M3's does.
      for (final entry in themes.entries) {
        final t = entry.value;
        final ground = t.colorScheme.surface;

        for (final states in const <Set<WidgetState>>[
          <WidgetState>{},
          <WidgetState>{WidgetState.selected},
        ]) {
          final edge = contrast(trackEdge(t, states), ground);
          final fill = contrast(track(t, states), ground);

          expect(
            edge >= graphic || fill >= graphic,
            isTrue,
            reason:
                '${entry.key}: with states $states neither the track nor its '
                'outline separates the switch from the card behind it',
          );
        }
      }
    });

    test('focus draws the ring in the outline slot', () {
      // `SwitchThemeData` has no side, so the outline carries it. Same colour
      // and same weight as every other ring in the app.
      for (final entry in themes.entries) {
        final t = entry.value;
        const focused = <WidgetState>{WidgetState.focused};

        expect(
          trackEdge(t, focused),
          AppInteractionStates.focusRing(t.extension()!).color,
          reason: '${entry.key}: the focused switch is not wearing the ring',
        );
        expect(
          t.switchTheme.trackOutlineWidth!.resolve(focused),
          AppStroke.focus,
        );
      }
    });
  });

  group('checkbox', () {
    test('the empty box is identified by its edge', () {
      // The same case as an empty text field, and the reason `borderControl`
      // exists: nothing but the outline says there is something to tick.
      for (final entry in themes.entries) {
        expect(
          contrast(
            box(entry.value, const {}).color,
            entry.value.colorScheme.surface,
          ),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the unticked box has no visible edge',
        );
      }
    });

    test('the tick reads on the ticked box', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        const on = <WidgetState>{WidgetState.selected};

        expect(
          contrast(
            t.checkboxTheme.checkColor!.resolve(on)!,
            t.checkboxTheme.fillColor!.resolve(on)!,
          ),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the tick disappears into its own box',
        );
      }
    });

    test('the ticked box stays bounded where its fill is not enough', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        const on = <WidgetState>{WidgetState.selected};
        final ground = t.colorScheme.surface;

        final edge = contrast(box(t, on).color, ground);
        final fill = contrast(t.checkboxTheme.fillColor!.resolve(on)!, ground);

        expect(
          edge >= graphic || fill >= graphic,
          isTrue,
          reason: '${entry.key}: the ticked box has no boundary on a card',
        );
      }
    });

    test('focus draws the ring', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        final side = box(t, const {WidgetState.focused});

        expect(
          side.color,
          AppInteractionStates.focusRing(t.extension()!).color,
        );
        expect(side.width, AppStroke.focus);
      }
    });
  });

  test('both resolve the house control wash, not Material own', () {
    // The drift that opened this task: four call sites taking hover, press and
    // focus from `ThemeData`'s unseeded fallbacks while every other control in
    // the app resolved `AppInteractionStates`.
    for (final entry in themes.entries) {
      final t = entry.value;
      final expected = AppInteractionStates.controlOverlay(t.colorScheme);

      for (final state in const <WidgetState>[
        WidgetState.hovered,
        WidgetState.pressed,
        WidgetState.focused,
      ]) {
        final states = <WidgetState>{state};

        expect(
          t.switchTheme.overlayColor!.resolve(states),
          expected.resolve(states),
          reason: '${entry.key}: the switch washes $state differently',
        );
        expect(
          t.checkboxTheme.overlayColor!.resolve(states),
          expected.resolve(states),
          reason: '${entry.key}: the checkbox washes $state differently',
        );
      }
    }
  });
}
