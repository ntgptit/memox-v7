import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

/// The switch and the checkbox, which rendered through Material's defaults
/// until M99.48.
///
/// **What these assert is the pair, never the token.** A thumb colour is right
/// or wrong only against the track it sits on, and Material's own default —
/// `outline` on `surfaceContainerHighest` — is the version that reads fine as
/// two token names and measures 2.79:1 as a pair. So every check below resolves
/// both halves from the built theme and divides them.
/// **The resting switch the owner accepted under 3:1** (M100.87, M100.92).
/// The handoff thumb — `surfaceBright` on its `surfaceContainerHighest` track —
/// reads 1.32:1 in light and 1.36:1 in dark (owner decision 5); both are
/// pinned at those figures so the accepted state cannot sink further. Until
/// the Switch pass it was `outline`, at 2.74:1 and 1.96:1.
const Map<String, double> _acceptedRestingThumb = <String, double>{
  'light': 1.3,
  'dark': 1.3,
};

/// The resting track against the page, accepted the same way: 1.25:1 in light
/// and 1.92:1 in dark, with no outline drawn around it since M100.92.
const Map<String, double> _acceptedRestingTrack = <String, double>{
  'light': 1.2,
  'dark': 1.9,
};

/// How loud a disabled knob is allowed to read on its track: 2.32:1 in light
/// and 2.83:1 in dark, measured at M100.92. A ceiling, not a floor.
const Map<String, double> _disabledKnobCeiling = <String, double>{
  'light': 2.4,
  'dark': 2.9,
};

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
          greaterThanOrEqualTo(_acceptedRestingThumb[entry.key]!),
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

    test('the track, not the thumb, tells on from off', () {
      // **Until M100.92 this pinned M3's `outline` thumb on the resting track**
      // — the pairing M100.22 retuned the palette to clear. The handoff thumb
      // is `surfaceBright` in both states, so the thumb no longer changes with
      // the state; the track does, and that change is what WCAG 1.4.11 asks
      // 3:1 of.
      for (final entry in themes.entries) {
        final t = entry.value;

        expect(
          thumb(t, const {}),
          thumb(t, const {WidgetState.selected}),
          reason: '${entry.key}: the thumb changed role with the state',
        );
        expect(
          contrast(track(t, const {WidgetState.selected}), track(t, const {})),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the on and off tracks read as one colour',
        );
      }
    });

    test('the track is bounded against the surface in both states', () {
      // No outline draws in either state since M100.92, so the fill is the
      // boundary: `primary` clears 3:1 against the page when on, and the
      // resting track holds its accepted figure. **The edge is composited
      // before anything reads it** — `contrast` ignores alpha, and a
      // transparent outline read raw is black, a boundary nothing paints.
      for (final entry in themes.entries) {
        final t = entry.value;
        final ground = t.colorScheme.surface;

        expect(
          Color.alphaBlend(trackEdge(t, const {}), ground),
          ground,
          reason: '${entry.key}: the resting track grew an outline again',
        );
        expect(
          contrast(track(t, const {}), ground),
          greaterThanOrEqualTo(_acceptedRestingTrack[entry.key]!),
          reason: '${entry.key}: the resting track sank into the page',
        );
        expect(
          contrast(track(t, const {WidgetState.selected}), ground),
          greaterThanOrEqualTo(graphic),
          reason: '${entry.key}: the selected track sank into the page',
        );
      }
    });

    test('focus goes to the overlay, not to the track outline', () {
      // **The inverse of what this pinned until M100.23.** It required the
      // focused switch to draw the ring in `trackOutlineColor`, because
      // `SwitchThemeData` has no `side` — true, and the wrong conclusion. That
      // slot is the track's canonical boundary role, and filling it with a
      // focus colour meant a switched-*on* switch that took focus drew a
      // boundary `_SwitchDefaultsM3` says should not exist at all.
      //
      // Material puts the cue in `overlayColor`, and so does this theme now.
      for (final entry in themes.entries) {
        final t = entry.value;
        const focused = <WidgetState>{WidgetState.focused};
        final ring = AppInteractionStates.focusIndicator(t.colorScheme).color;

        expect(
          trackEdge(t, focused),
          isNot(ring),
          reason:
              '${entry.key}: the track outline is carrying the focus ring '
              'again — it is the switch identity slot',
        );
        expect(
          t.switchTheme.overlayColor!.resolve(focused),
          isNotNull,
          reason: '${entry.key}: a focused switch shows nothing at all',
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

    test('focus darkens the edge to onSurface, as hover does', () {
      // `_CheckboxDefaultsM3.side` gives pressed, hovered and focused the same
      // `onSurface` — an 18dp box has little length to be seen over, so the
      // edge is what changes. This asserted a `primary` ring until M100.23,
      // read *above* the `selected` branch, so a ticked box that took focus
      // grew an edge where M3 draws none and lost the stroke's width from its
      // fill on all four sides.
      for (final entry in themes.entries) {
        final t = entry.value;
        final side = box(t, const {WidgetState.focused});

        expect(side.color, t.colorScheme.onSurface, reason: entry.key);
        expect(side.width, AppStroke.selectionControl, reason: entry.key);
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

        // **Inverted in both modes, and recorded rather than hidden**
        // (M100.87, M100.92). The handoff's resting thumb reads 1.32:1 and
        // 1.36:1, and the disabled knob 2.32:1 and 2.83:1 — louder than a live
        // one. D3 keeps a colour per disabled slot rather than the kit's whole
        // control at 38%, so the figures are a ceiling the knob cannot grow
        // past.
        expect(
          contrast(disabledKnob, track(t, off)),
          lessThanOrEqualTo(_disabledKnobCeiling[entry.key]!),
          reason: '${entry.key}: the disabled switch got louder still',
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
