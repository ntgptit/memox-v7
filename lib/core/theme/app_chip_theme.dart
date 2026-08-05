import 'package:flutter/material.dart';

import 'app_button_themes.dart';
import 'app_icon_size.dart';
import 'app_interaction_states.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';

/// The chip theme — `MxPillButton`'s entire appearance.
///
/// Split from `app_theme.dart` when that file crossed the 400-line guard, on the
/// same seam `app_button_themes.dart` was cut on: one component family, every
/// interaction state declared by hand, read by nothing else in the theme.
///
/// **Every state is resolved here, and that is a correction rather than polish.**
/// This theme used to declare `backgroundColor` and `selectedColor` and nothing
/// else, which left Material to answer for the rest — and Material's answers are
/// exactly the kind AD-05 rule 5 calls invisible to a source scan:
///
/// * a **disabled** pill fell through to `onSurface` at 12% *alpha*, composited
///   against whatever was behind it at paint time. That is the translucency
///   MX-VIS-002 rule R7 exists to stop, arrived at by not writing anything down.
/// * a **disabled and selected** pill kept the full `secondaryContainer` fill,
///   because `_IndividualOverrides` returns `selectedColor` for that pair before
///   the defaults are consulted. A pill nobody could press looked exactly as
///   live as one they could.
/// * **hover, focus and press** had no chip-level answer at all, so a pill
///   responded to a pointer by a different amount than every button beside it.
///
/// Declaring the state-aware [ChipThemeData.color] is what takes ownership of
/// all four: it is consulted before `backgroundColor`, `selectedColor` and
/// `disabledColor`, which is why those three are deliberately *not* set — two
/// spellings of one fill, one of them dead, is how the next edit changes the
/// colour in the half nothing reads.

/// The resting fill for a pill, before any pointer or disabled state.
///
/// Selected borrows the navigation bar's indicator pair, so "this one is active"
/// looks the same whether it is a tab or a filter; unselected is a card sitting
/// on the page, which is the same surface-over-background step every other panel
/// uses.
Color _restingFill(ColorScheme scheme, {required bool isSelected}) =>
    isSelected ? scheme.secondaryContainer : scheme.surface;

/// The fill for [states], resolved to a solid colour over the ground that state
/// actually has.
///
/// Blended rather than washed over: R7 asks for `Color.alphaBlend` at build
/// time, and here the ground is known — a pill's fill is the only thing under
/// its own feedback.
Color _fillFor(ColorScheme scheme, Set<WidgetState> states) {
  final resting = _restingFill(
    scheme,
    isSelected: states.contains(WidgetState.selected),
  );

  if (states.contains(WidgetState.disabled)) {
    return disabledSurfaceTint(scheme, over: resting);
  }
  if (states.contains(WidgetState.pressed)) {
    return _tint(resting, scheme.primary, AppStateOpacity.pressed);
  }
  if (states.contains(WidgetState.focused)) {
    return _tint(resting, scheme.primary, AppStateOpacity.focus);
  }
  if (states.contains(WidgetState.hovered)) {
    return _tint(resting, scheme.primary, AppStateOpacity.hoverControl);
  }

  return resting;
}

Color _tint(Color ground, Color tint, double alpha) =>
    Color.alphaBlend(tint.withValues(alpha: alpha), ground);

/// The label colour for [states].
///
/// **Carried by `labelStyle.color` as a [WidgetStateColor], and `secondaryLabelStyle`
/// is left null on purpose.** `ChoiceChip` passes `secondaryLabelStyle` down as the
/// widget's own label style when selected, and it is merged *over* this one — so a
/// plain `Color` there would win for the selected pill and take the disabled and
/// pressed states with it. One state machine, in the slot Material resolves.
Color _labelColorFor(
  ColorScheme scheme,
  AppSemanticColors semantic,
  Set<WidgetState> states,
) {
  if (states.contains(WidgetState.disabled)) {
    return semantic.onDisabled;
  }
  if (states.contains(WidgetState.selected)) {
    return scheme.onSecondaryContainer;
  }

  return scheme.onSurfaceVariant;
}

ChipThemeData buildChipTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => ChipThemeData(
  color: WidgetStateProperty.resolveWith((states) => _fillFor(scheme, states)),
  // No checkmark: the pill group is always visible in full, so the selected one
  // is legible by contrast alone and the tick would shift the label sideways on
  // every change.
  showCheckmark: false,
  side: WidgetStateBorderSide.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) {
      return BorderSide(color: disabledSurfaceTint(scheme));
    }
    // The same ring `iconButtonTheme` and the outlined button draw, from the
    // one definition. A pill is reachable by keyboard on the web build, which is
    // the E2E channel, and Material's own focus cue for a chip is a fill tint
    // this theme now owns — so without a ring the focused pill and the hovered
    // one look alike.
    if (states.contains(WidgetState.focused)) {
      return AppInteractionStates.focusRing(semantic);
    }

    return BorderSide(color: semantic.borderSubtle);
  }),
  shape: const StadiumBorder(),
  labelStyle: texts.labelLarge?.copyWith(
    color: WidgetStateColor.resolveWith(
      (states) => _labelColorFor(scheme, semantic, states),
    ),
  ),
  iconTheme: IconThemeData(
    size: AppIconSize.sm,
    color: scheme.onSurfaceVariant,
  ),
  // **`sm` across, not `md`.** Material's own M3 chip padding is 8, and `md`
  // put 21 of chrome on each side of a label as short as "All 1" — 42 of a
  // 69.5-wide pill, so more of the control was padding than word. `sm` brings
  // that to 17 a side and the pill to 61.5, which is where M3 draws it.
  // Vertical stays `sm`: that is what makes the pill 36 tall, the height M3
  // draws and the one `MaterialTapTargetSize.padded` grows to 48 for a finger.
  //
  // **The measurement is here so nobody re-derives it.** The card list's four
  // pills — All, Due, New, ⚑ Flagged, each carrying a count — ran to 426.4
  // against the 374 a 390-wide screen leaves inside the gutter. This token took
  // them to 394.4 and dropping "now" from the Due label took them to 361.8, so
  // a deck with single-digit counts now shows all four without scrolling.
  //
  // **It is not fixed at every size, and no further padding will fix it.** At
  // 360 the row overflows by 17.8, and on a deck with three-digit counts it
  // runs to 416.5 at 390 — the labels grow with the data, so the row is
  // horizontally scrollable by design and the trailing gutter below exists for
  // that. Do not shave this token again to buy those pixels: it is shared with
  // every other pill in the app, and they are not the ones short of room.
  //
  // `.mx-pill__body` in `design_system/components/mx.css` carries the same two
  // numbers and changed with this — a pill that is one size in the app and
  // another in the kit is the drift the parity checklist exists to catch.
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.sm,
  ),
);
