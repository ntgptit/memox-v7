import 'package:flutter/material.dart';

import 'app_button_themes.dart';
import 'app_icon_size.dart';
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
    return _tint(resting, scheme.primary, kPressedOverlayAlpha);
  }
  if (states.contains(WidgetState.focused)) {
    return _tint(resting, scheme.primary, kFocusedOverlayAlpha);
  }
  if (states.contains(WidgetState.hovered)) {
    return _tint(resting, scheme.primary, kHoveredOverlayAlpha);
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
Color _labelColorFor(ColorScheme scheme, Set<WidgetState> states) {
  if (states.contains(WidgetState.disabled)) {
    return scheme.onSurface.withValues(alpha: kDisabledForegroundAlpha);
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
    // The same ring `iconButtonTheme` and the outlined button draw, through the
    // one function so the three cannot drift. A pill is reachable by keyboard on
    // the web build, which is the E2E channel, and Material's own focus cue for
    // a chip is a fill tint this theme now owns — so without a ring the focused
    // pill and the hovered one look alike.
    if (states.contains(WidgetState.focused)) {
      return focusRingSide(semantic);
    }

    return BorderSide(color: semantic.borderSubtle);
  }),
  shape: const StadiumBorder(),
  labelStyle: texts.labelLarge?.copyWith(
    color: WidgetStateColor.resolveWith(
      (states) => _labelColorFor(scheme, states),
    ),
  ),
  iconTheme: IconThemeData(
    size: AppIconSize.sm,
    color: scheme.onSurfaceVariant,
  ),
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  ),
);
