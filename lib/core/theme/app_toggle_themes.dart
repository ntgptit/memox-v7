import 'package:flutter/material.dart';

import 'app_interaction_states.dart';
import 'app_semantic_colors.dart';
import 'app_stroke.dart';

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
/// draws:** a *glyph* takes an ink token, a *fill* takes `primary` with its
/// `onPrimary` partner. A selected radio is a ring and a dot — glyph, so
/// `primaryAccent`. A selected checkbox is a filled box with a tick inside, and
/// a selected switch track is a filled pill — fills, so `primary`. That is why
/// these two do not follow the radio into the accent.

/// The switch, as the reminder toggle and the importer's two `SwitchListTile`s
/// render it.
///
/// **The resting thumb is the secondary ink, and that is a measured departure
/// from Material.** M3's default unselected thumb is `colorScheme.outline` —
/// `borderControl` here — on a `surfaceContainerHighest` track. Against this
/// app's muted track that pairing measures **2.79:1 in light and 2.54:1 in
/// dark**, under the 3:1 WCAG 1.4.11 asks of the visual information that
/// identifies a control's state; and on a switch the thumb *is* the state.
/// `onSurfaceVariant` on the same track reads 5.61:1 and 6.17:1.
///
/// **The track is outlined in every state, and the outline changes colour
/// rather than disappearing.** M3 drops the outline once the switch is on,
/// which is fine where `primary` is a light-mode fill and reads 7.27:1 against
/// a card — and wrong here, because `primaryDark` is deliberately held below
/// the card's headline text (see `AppColors.primaryDark`) and measures
/// **2.90:1** on a dark card. So the boundary is drawn from the pair the track
/// already carries, exactly as `AppInteractionStates.focusRingOf` derives a
/// filled button's ring:
///
/// | track | outline | on the fill | on a dark card |
/// |---|---|---|---|
/// | off (`surfaceMuted`) | `borderControl` | — | 3.00:1 |
/// | on (`primary`) | `onPrimary` | 5.88:1 | 17.05:1 |
///
/// In light the on-state outline is white on a near-white card — 1.03:1, which
/// is to say invisible — and that is the correct outcome rather than a missed
/// one: light's fill already separates itself at 7.27:1, so the outline has no
/// work to do and does none. The edge appears exactly in the mode that needs
/// it.
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
    // The ink at 38% reads 2.29:1 in light and 2.90:1 in dark on the disabled
    // track: plainly muted, plainly still there. It is also M3's own answer
    // for an unselected disabled thumb, and the value the radio's disabled
    // mark already takes.
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
    if (states.contains(WidgetState.selected)) return scheme.onPrimary;

    return scheme.onSurfaceVariant;
  }),
  trackColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.disabledSurface;
    if (states.contains(WidgetState.selected)) return scheme.primary;

    return semantic.surfaceMuted;
  }),
  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
    // Focus draws the ring in the track's outline slot, because
    // `SwitchThemeData` has no other. Same colour and same weight as every
    // other focus ring in the app; only the shape it follows differs.
    if (states.contains(WidgetState.focused)) return semantic.focusRing;
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
    if (states.contains(WidgetState.selected)) return scheme.onPrimary;

    return semantic.borderControl;
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
/// **The edge stays when the box is ticked in dark, and only there** — which is
/// where this departs from M3 (`_CheckboxDefaultsM3.side` returns width 0 once
/// selected). A ticked box is a `primary` fill, and `primaryDark` is held low
/// enough that it measures 2.90:1 on a dark card, under WCAG 1.4.11's floor. So
/// in dark the edge remains and becomes `onPrimary` — 5.88:1 on the fill it sits
/// on, 17.05:1 on the card behind it — by the same derivation the switch's track
/// uses.
///
/// **In light the same ring was invisible, and what it cost was the box.** White
/// on the sheet measures **1.03:1**, so nothing was gained; and a `BorderSide`
/// is painted *inside* the shape, so the fill was inset by the stroke on all
/// four sides — a ticked box drew 14dp of indigo where the empty boxes above and
/// below it drew an 18dp edge. In a column of checkboxes that is not a subtle
/// difference: the ticked ones read smaller and sit off the line the others
/// share, which is exactly how the owner found it (2026-08-26). The light fill
/// needs no help — 7.27:1 on the sheet — so it keeps the whole box.
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
    if (states.contains(WidgetState.disabled)) {
      return states.contains(WidgetState.selected)
          ? semantic.disabledSurface
          : Colors.transparent;
    }
    if (states.contains(WidgetState.selected)) return scheme.primary;

    // Transparent, not a surface. An unticked box on a card and the same box
    // on a muted tile are one control, and a fill would make it two.
    return Colors.transparent;
  }),
  checkColor: WidgetStateProperty.resolveWith((states) {
    // The same trap as the switch's thumb, one control over: a white tick on
    // the disabled fill measures 1.32:1 in light, so a disabled *ticked* box
    // reads as an empty one. The disabled ink is 2.29:1 on that fill.
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

    return scheme.onPrimary;
  }),
  side: WidgetStateBorderSide.resolveWith((states) {
    if (states.contains(WidgetState.focused)) {
      return AppInteractionStates.focusRing(semantic);
    }
    if (states.contains(WidgetState.disabled)) {
      return _boxSide(semantic.onDisabled);
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
    // M3 darkens the outline while the pointer is on it. Kept, because the
    // overlay wash alone is 1.15:1 and the box is small enough that the edge is
    // most of what there is to change.
    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered)) {
      return _boxSide(scheme.onSurface);
    }

    return _boxSide(scheme.onSurfaceVariant);
  }),
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);

/// A checkbox's box edge, at the one weight.
BorderSide _boxSide(Color color) =>
    BorderSide(color: color, width: AppStroke.selectionControl);
