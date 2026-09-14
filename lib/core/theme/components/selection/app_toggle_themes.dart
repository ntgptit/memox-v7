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

/// The raw `Switch`. The app draws every switch through `MxSwitchRow`, which
/// paints `MxSwitch` (M100.92): the handoff's 44 × 26 track is a size no
/// `SwitchThemeData` slot reaches. This theme keeps a bare or third-party
/// `Switch` on the same roles all the same.
///
/// **The handoff Switch, and where it leaves `_SwitchDefaultsM3`** (M100.92):
///
/// | slot | M3 | handoff, and now |
/// |---|---|---|
/// | thumb | `outline` off, `onPrimary` on | `surfaceBright` in both |
/// | track | `surfaceContainerHighest` off, `primary` on | same |
/// | track outline | `outline` off, transparent on | transparent in both |
///
/// **The resting thumb reads 1.32:1 in light and 1.36:1 in dark** on its
/// track — under the 3:1 WCAG 1.4.11 asks of a control's state. The owner
/// accepted the handoff's values (owner decision 5), and
/// `app_toggle_themes_test.dart` pins those figures so the pair cannot sink
/// further. The track is what tells on from off, and that change is pinned at
/// 3:1. Until M100.92 every slot was M3's; the measurements behind that are in
/// `docs/design-system/switch-spec.md`.
SwitchThemeData buildSwitchTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith((states) {
    // **`onDisabled`, never the track's own `disabledSurface`.** That shipped
    // once and put the knob at 1:1 on the pill it sits on — a disabled switch
    // drawn as a uniform blob, its stored state gone exactly while the user
    // cannot change it. WCAG 1.4.11 exempts inactive controls from 3:1, so the
    // requirement is *visible*: the knob reads 2.32:1 in light and 2.83:1 in
    // dark on the disabled track, a colour per slot rather than one alpha (D3).
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

    // One role in both states: the handoff thumb does not change with the
    // state; the track does.
    return scheme.surfaceBright;
  }),
  trackColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.disabledSurface;
    if (states.contains(WidgetState.selected)) return scheme.primary;

    return scheme.surfaceContainerHighest;
  }),
  // Transparent in every state (handoff Switch): the track's fill is its
  // boundary. **No focus branch** (M100.23) — the keyboard cue is
  // `overlayColor` below, `AppInteractionStates.controlOverlay` washing
  // `primary` at `AppStateOpacity.focus` around the thumb, where
  // `_SwitchDefaultsM3.overlayColor` puts it too.
  trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
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
