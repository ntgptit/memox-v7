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

    test('the M3 pairing is what clears the floor, not a substitute', () {
      // **This test asserted the opposite until M100.22, and it is worth saying
      // why rather than just flipping it.** It pinned that `outline` on the
      // resting track measures *under* the floor — which was true, and which
      // made the substitution (`onSurfaceVariant` on `surfaceMuted`) look
      // load-bearing. What it actually did was hold the palette's failure in
      // place: any agent restoring M3's own pairing would have been failed by
      // the suite for it, and the only way to pass was to keep the component
      // off its default.
      //
      // The floor is now cleared by the roles themselves — `borderControl`
      // moved 5.07 L\* in light and 5.73 in dark — so the assertion can be what
      // it should always have been: the canonical pairing works.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;

        expect(
          contrast(scheme.outline, scheme.surfaceContainerHighest),
          greaterThanOrEqualTo(graphic),
          reason:
              '${entry.key}: M3 puts the resting thumb (`outline`) on the '
              'resting track (`surfaceContainerHighest`). If this fails, the '
              'fix is a tone in AppBorderColors — not a different role on the '
              'switch.',
        );
      }
    });

    test('the track is bounded against the surface in both states', () {
      // Off, the fill is a near-surface tile and the outline does it. On, M3
      // drops the outline entirely and the fill has to carry it alone —
      // `primary` on the card is 7.27:1 in light and 10.01:1 in dark since
      // M100.18, which is why the app stopped drawing an on-state edge at
      // M100.22. Either half satisfies this; the point is that one of them
      // must.
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
          AppInteractionStates.focusRing(t.colorScheme).color,
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

    test('an edge on a ticked box is one you can see on the card', () {
      // **The rule the previous test could not state.** The one above accepts
      // an edge *or* a fill that reads, and a `BorderSide` is painted inside
      // the shape — so a ring that reads only against its own fill passes it
      // while subtracting its width from every side of the box. Light shipped
      // exactly that: `onPrimary` white measured 1.03:1 on the sheet, and the
      // ticked box drew 14dp of indigo beside 18dp empty ones.
      //
      // So: draw no edge, or draw one the card behind the control can show.
      for (final entry in themes.entries) {
        final t = entry.value;
        final side = box(t, const {WidgetState.selected});
        if (side.style == BorderStyle.none || side.width == 0) continue;

        expect(
          contrast(side.color, t.colorScheme.surface),
          greaterThanOrEqualTo(graphic),
          reason:
              '${entry.key}: the ticked box paints an edge that does not read '
              'on the card, so it shrinks the box instead of bounding it',
        );
      }
    });

    test('focus draws the ring', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        final side = box(t, const {WidgetState.focused});

        expect(side.color, AppInteractionStates.focusRing(t.colorScheme).color);
        expect(side.width, AppStroke.focus);
      }
    });
  });

  group('disabled still shows what it is', () {
    // **The state a contrast floor does not cover.** WCAG 1.4.11 exempts
    // inactive components, so nothing above would have caught a disabled
    // switch whose thumb and track were the same colour — which is what
    // shipped, at 1:1. The requirement here is weaker than 3:1 and it is still
    // a requirement: a control the user cannot change is a control whose
    // current value they can only read.
    const off = <WidgetState>{WidgetState.disabled};
    const on = <WidgetState>{WidgetState.disabled, WidgetState.selected};

    test('a disabled switch still shows which side the knob is on', () {
      for (final entry in themes.entries) {
        final t = entry.value;

        for (final states in const <Set<WidgetState>>[off, on]) {
          final knob = Color.alphaBlend(thumb(t, states), track(t, states));

          expect(
            contrast(knob, track(t, states)),
            greaterThan(1.5),
            reason:
                '${entry.key}: with states $states the thumb dissolves into '
                'its own track',
          );
        }
      }
    });

    test('a disabled ticked box still looks ticked', () {
      for (final entry in themes.entries) {
        final t = entry.value;
        final fill = t.checkboxTheme.fillColor!.resolve(on)!;
        final tick = Color.alphaBlend(
          t.checkboxTheme.checkColor!.resolve(on)!,
          fill,
        );

        expect(
          contrast(tick, fill),
          greaterThan(1.5),
          reason: '${entry.key}: the disabled tick vanishes into its box',
        );
      }
    });

    test('and still reads as disabled rather than as available', () {
      // The other bound. Fixing the first one by making disabled look enabled
      // trades a real bug for a worse one.
      for (final entry in themes.entries) {
        final t = entry.value;

        // Composited, not raw. `onDisabled` is translucent, and `contrast`
        // reads RGB without alpha — so comparing the token itself would
        // measure an opaque near-black thumb that nothing ever paints, and
        // report the disabled switch as the louder of the two.
        final disabledKnob = Color.alphaBlend(thumb(t, off), track(t, off));

        expect(
          contrast(disabledKnob, track(t, off)),
          lessThan(contrast(thumb(t, const {}), track(t, const {}))),
          reason: '${entry.key}: the disabled switch is as loud as a live one',
        );
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
