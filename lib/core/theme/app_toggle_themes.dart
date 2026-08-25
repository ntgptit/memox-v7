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
    // The thumb is a face, not a glyph — a disabled switch still shows a
    // pill with a knob on it — so this is the solid `disabledSurface` rather
    // than the translucent content token the radio's mark takes.
    if (states.contains(WidgetState.disabled)) return semantic.disabledSurface;
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
/// **The edge stays when the box is ticked, which is where this departs from
/// M3** (`_CheckboxDefaultsM3.side` returns width 0 once selected). A ticked
/// box is a `primary` fill, and `primaryDark` is held low enough that it
/// measures 2.90:1 on a dark card. So the edge remains and becomes `onPrimary`
/// — 5.88:1 on the fill it sits on, 17.05:1 on the card behind it — by the same
/// derivation the switch's track uses.
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
  checkColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
  side: WidgetStateBorderSide.resolveWith((states) {
    if (states.contains(WidgetState.focused)) {
      return AppInteractionStates.focusRing(semantic);
    }
    if (states.contains(WidgetState.disabled)) {
      return _boxSide(semantic.onDisabled);
    }
    if (states.contains(WidgetState.selected)) {
      return _boxSide(scheme.onPrimary);
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
