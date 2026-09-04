import 'package:flutter/material.dart';

import '../../states/app_interaction_states.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_stroke.dart';

/// The two binary toggles — `Switch` and `Checkbox`.
///
/// **Declared because they render, which is the rule `app_theme.dart` states in
/// both directions and was only keeping in one.** Four call sites were taking
/// Material's defaults: the reminder screen's `Switch`, two `SwitchListTile`s in
/// the card importer and the tag filter sheet's `CheckboxListTile`. Their
/// hover, press and focus washes came from `ThemeData`'s unseeded fallbacks
/// rather than from [AppInteractionStates], so they were the only controls in
/// the app resolving a different state layer from every other one.
///
/// Radio stays in `app_radio_theme.dart`. It is not a toggle: a radio answers
/// *which one of these*, and its neighbours change with it. The three are not
/// one family just because all three are small and round.
///
/// **The kit has no switch and no checkbox** — no mock renders a reminder toggle
/// or a tag filter — so, as with the radio, there is no CSS to transcribe and
/// the values are the app's own tokens. Recorded as a Flutter-only gap in
/// `docs/reviews/design-parity-checklist.md`.
///
/// **One rule decides every colour below, and it is the one the radio already
/// draws:** a *glyph* and a *fill* both take `primary`, with `onPrimary` as the
/// fill's partner. A selected radio is a ring and a dot; a selected checkbox is
/// a filled box with a tick inside; a selected switch track is a filled pill.
/// Glyph and fill used to part company here — the glyph needed a brighter ink
/// because the old dark fill tone reached only 2.90:1 against the card — and
/// M100.18 closed that by inverting the tone rather than by keeping two inks.

/// The switch, as the reminder toggle and the importer's two `SwitchListTile`s
/// render it.
///
/// **Every slot is `_SwitchDefaultsM3`'s, and M100.22 is where the last three
/// substitutions were given back.** The off state had drifted furthest:
///
/// | slot | was | M3, and now |
/// |---|---|---|
/// | off thumb | `onSurfaceVariant` | `outline` |
/// | off track | `surfaceMuted` (= `surfaceContainerHigh`) | `surfaceContainerHighest` |
/// | off track outline | `borderControl` | `outline` |
/// | on track outline | `onPrimary` | transparent |
///
/// **The reason the first three were substituted was real, and it was a palette
/// fault.** `outline` on `surfaceContainerHighest` measured **2.79:1 in light
/// and 2.54:1 in dark** — under the 3:1 WCAG 1.4.11 asks of the visual
/// information identifying a control's state, and on a switch the thumb *is*
/// the state. The theme answered by moving the component to a brighter ink and
/// a lower track, which fixed the number and left `outline` failing for the
/// next component to find. M100.22 moved the role instead:
/// `AppBorderColors.borderControlLight`/`Dark` carry the derivation, and the
/// pairing now reads **3.24:1 and 3.04:1** with every other `outline` ground
/// improving as a side effect.
///
/// **The on-state outline is gone, and that is the same correction one state
/// over.** M3 drops the track outline once the switch is on; this theme kept it
/// and painted `onPrimary` there, because `primaryDark` used to sit at 2.90:1
/// against a dark card and the pill needed an edge to be findable. M100.18
/// inverted that tone — the on track now reads **10.01:1 on the dark card and
/// 7.27:1 on the light one** — so the fill separates itself and the edge has
/// nothing left to do. In light it was 1.03:1 white-on-near-white the whole
/// time, which is to say the app was carrying a brightness-conditional
/// workaround for a condition that no longer holds in either mode.
SwitchThemeData buildSwitchTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith((states) {
    // **`onDisabled`, and it shipped as `disabledSurface` — the same value the
    // track resolves to, which put the knob at 1:1 against the pill it sits
    // on.** A disabled switch drawn that way is a uniform blob: the stored
    // on/off state disappears exactly while the user cannot change it, which
    // on the reminder toggle is the whole time a command is in flight.
    //
    // WCAG 1.4.11 does exempt inactive components from its 3:1 floor, so the
    // requirement here is *visible*, not *3:1* — and 1:1 fails the weaker one.
    // The ink at 38% reads 2.05:1 in light and 2.51:1 in dark on the disabled
    // track (re-measured at M100.36; it was 2.29 / 2.90 on the pre-M100.22
    // palette): plainly muted, plainly still there. It is also M3's own answer
    // for an unselected disabled thumb, and the value the radio's disabled
    // mark already takes.
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
    if (states.contains(WidgetState.selected)) return scheme.onPrimary;

    return scheme.outline;
  }),
  trackColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.disabledSurface;
    if (states.contains(WidgetState.selected)) return scheme.primary;

    return scheme.surfaceContainerHighest;
  }),
  // `_SwitchDefaultsM3.trackOutlineColor`'s own order: selected, then disabled,
  // then the role. **No focus branch, and removing the one that was here is the
  // point of M100.23.** It read focus first and returned `primary`, on the
  // argument that a focused *on* switch still has to show where the keyboard
  // is — which is true, and was answered in the wrong slot. The outline is the
  // switch's canonical boundary role; a focused-on switch was being drawn with
  // a boundary M3 says should not exist, in a colour that means something else.
  //
  // The keyboard cue is `overlayColor` below — `AppInteractionStates.controlOverlay`
  // washes `primary` at `AppStateOpacity.focus` around the thumb, which is
  // where `_SwitchDefaultsM3.overlayColor` puts it too.
  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return Colors.transparent;
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

    return scheme.outline;
  }),
  // One width in every state, and it is M3's 2.0 rather than a hairline. Focus
  // moves the colour and not the weight, the same way an input's border does —
  // and because `AppStroke.selectionControl` equals `AppStroke.focus`, the ring
  // needs no second value here to be the right thickness.
  trackOutlineWidth: const WidgetStatePropertyAll<double>(
    AppStroke.selectionControl,
  ),
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);

/// The checkbox, as the tag filter sheet's `CheckboxListTile` renders it.
///
/// **The resting edge is `onSurfaceVariant`, and correcting that to M3's role
/// was the finding of the role audit.** It shipped as `borderControl` on the
/// argument that an empty checkbox is identified by its edge — the same case as
/// an empty text field. The case is the same; the *number* is not. A text field
/// is a full-width control whose edge is read along its whole length, so the
/// 3:1 floor is enough; an 18dp box has a fraction of that length to be seen
/// over, and M3 answers it with the secondary ink rather than the outline role.
/// The app's own tokens make the gap plain: `borderControl` measures 3.19:1 in
/// light and 3.00:1 in dark, `onSurfaceVariant` 6.41:1 and 7.30:1. Transferring
/// the field's argument to a control an order of magnitude smaller was the
/// mistake, and the stroke width carried the same one — see
/// [AppStroke.selectionControl].
///
/// **A ticked box has no edge, which is `_CheckboxDefaultsM3.side`'s answer**
/// (a zero-width transparent side once selected). It used to keep one in dark
/// and drop it in light — a brightness switch, and it existed because the old
/// dark `primary` was a fill tone at 2.90:1 against the card, so the box needed
/// a ring to be findable. M100.18 inverted that tone and M100.21 removed the
/// ring; the fill now reads 10.02:1 on the dark card and 7.27:1 on the light
/// one, and carries the state on its own.
///
/// What the light half of that switch had already shown is why it was worth
/// removing rather than mirroring: white on the sheet measures **1.03:1**, so
/// the ring bought nothing, and a `BorderSide` is painted *inside* the shape —
/// the fill was inset by the stroke on all four sides, so a ticked box drew
/// 14dp of indigo where the empty boxes above and below it drew an 18dp edge.
/// In a column of checkboxes the ticked ones read smaller and sat off the line
/// the others share, which is exactly how the owner found it (2026-08-26).
///
/// The rule underneath, and what `app_toggle_themes_test.dart` now pins: an edge
/// on a ticked box has to read against **the card behind the control**, because
/// that edge is what says where the control ends. One that reads only against
/// its own fill is a ring nobody can see, subtracting from the only shape they
/// can.
CheckboxThemeData buildCheckboxTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => CheckboxThemeData(
  fillColor: WidgetStateProperty.resolveWith((states) {
    // **Disabled keeps its boolean, M3's way** (A20.1 P2-15). A ticked box
    // that cannot be changed fills with the *disabled ink* — `onSurface` at
    // 38%, `_CheckboxDefaultsM3.fillColor` — not with `disabledSurface`: the
    // surface tint is a face for things that have one, and on a box it read
    // 1.32:1 against the card, so a disabled tick and an empty box were one
    // grey. The ink at 38% still reads as a box, and the tick inside it is
    // the page colour (below), which is how M3 keeps "ticked" legible while
    // "unavailable" stays obvious.
    if (states.contains(WidgetState.disabled)) {
      return states.contains(WidgetState.selected)
          ? semantic.onDisabled
          : Colors.transparent;
    }
    if (states.contains(WidgetState.selected)) return scheme.primary;

    // Transparent, not a surface. An unticked box on a card and the same box
    // on a muted tile are one control, and a fill would make it two.
    return Colors.transparent;
  }),
  checkColor: WidgetStateProperty.resolveWith((states) {
    // `_CheckboxDefaultsM3.checkColor` disabled is `surface`: the tick is cut
    // out of the disabled-ink fill above in the page colour, so it reads at
    // the ink's own contrast rather than as a second grey on a grey (A20.1
    // P2-15). Until then the tick was `onDisabled` on `disabledSurface` —
    // 2.05:1, a disabled ticked box that read as an empty one.
    if (states.contains(WidgetState.disabled)) return scheme.surface;

    return scheme.onPrimary;
  }),
  // Disabled, then selected, then the interaction inks — `_CheckboxDefaultsM3
  // .side`'s order exactly. **Focus used to be read first**, so a ticked box
  // that had keyboard focus drew a `primary` ring where M3 draws no edge at
  // all: the one combination where this slot left its canonical answer, and
  // invisible to a test that only ever asked about `{selected}` and `{}`.
  side: WidgetStateBorderSide.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      // A disabled *ticked* box has no edge — `_CheckboxDefaultsM3.side` is
      // transparent there, for the same reason the live selected box has
      // none: the fill is the box. An edge on it only subtracted its width
      // from the one shape left to read (A20.1 P2-15). Unticked keeps the
      // disabled-ink ring, which is the whole control when there is no fill.
      return states.contains(WidgetState.selected)
          ? BorderSide.none
          : _boxSide(semantic.onDisabled);
    }
    if (states.contains(WidgetState.selected)) {
      // **No edge, which is M3's own answer** (`_CheckboxDefaultsM3.side`
      // returns a zero-width transparent side when selected): the fill *is*
      // the box, so an edge can only subtract its width from every side.
      //
      // This used to draw `onPrimary` in dark and nothing in light — a third
      // brightness switch, and it existed because the old dark `primary` was a
      // fill tone sitting close to the card, so the box needed a ring to be
      // findable. Since dark inverted to tone 80 (M100.18) the fill reads on
      // its own: 10.02:1 on the dark card, 7.27:1 on the light one.
      return BorderSide.none;
    }
    // M3 darkens the outline under a pointer *and* under keyboard focus, to the
    // same `onSurface` — see the pressed/hovered/focused trio in
    // `_CheckboxDefaultsM3.side`. Focus joins them here rather than drawing a
    // ring of its own: the edge is most of what an 18dp box has to change, and
    // the overlay wash alone is 1.15:1.
    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) {
      return _boxSide(scheme.onSurface);
    }

    return _boxSide(scheme.onSurfaceVariant);
  }),
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);

/// A checkbox's box edge, at the one weight.
BorderSide _boxSide(Color color) =>
    BorderSide(color: color, width: AppStroke.selectionControl);
