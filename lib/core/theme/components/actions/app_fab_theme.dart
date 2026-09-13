import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_icon_size.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_sizing.dart';
import '../../states/app_interaction_states.dart';

/// **`primary`/`onPrimary` — the Tokyo handoff's FAB, over M3's canonical
/// `primaryContainer`** (owner decision 4, 2026-09-13: the kit beats the
/// canonical role).
///
/// The binding was canonical from M100.32 on AD-14's invariant that the palette
/// moves and the binding does not. The redesign reopened that contract for the
/// handoff, whose FloatingActionButton is a primary fill with an onPrimary
/// label and glyph; `m3_role_bindings.dart` pins the new pair.
///
/// **Extended only.** The kit has no circular variant: 52 tall, radius 16,
/// glyph and label side by side (`MxFab`).
FloatingActionButtonThemeData buildFloatingActionButtonTheme(
  ColorScheme scheme,
) => FloatingActionButtonThemeData(
  backgroundColor: scheme.primary,
  foregroundColor: scheme.onPrimary,
  // **The focus ring rides on the shape, in the label colour** (M100.90, UI
  // audit P1). The wash below is `onPrimary` at 10% over `primary`, which is
  // 1.18:1 — under the 3:1 WCAG 1.4.11 asks of a focus indicator — and the
  // shared ring token is `primary`, the fill itself. So the FAB takes the
  // filled button's answer: `focusIndicatorOf(onPrimary)`. The theme has no
  // `side` slot; `RawMaterialButton` resolves this shape with the `focused`
  // state instead. Never null: null would fall back to the extended FAB's
  // `StadiumBorder`.
  shape: WidgetStateOutlinedBorder.resolveWith((states) {
    final corner = BorderRadius.circular(AppRadius.lg);
    if (states.contains(WidgetState.disabled)) {
      return RoundedRectangleBorder(borderRadius: corner);
    }
    if (states.contains(WidgetState.focused)) {
      return RoundedRectangleBorder(
        borderRadius: corner,
        side: AppInteractionStates.focusIndicatorOf(scheme.onPrimary),
      );
    }

    return RoundedRectangleBorder(borderRadius: corner);
  }),
  extendedSizeConstraints: const BoxConstraints.tightFor(height: AppSizing.fab),
  iconSize: AppIconSize.sm,
  // **The state washes move with the pair, or they describe the old one.**
  // M3's defaults hardcode `onPrimaryContainer`, so the pair above restates
  // every state default it owns (theme-composition review, 2026-08).
  hoverColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.hoverControl),
  focusColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.focus),
  splashColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.pressed),
  // The depth is `shadow-fab`, painted by `MxFab` — Material's elevation
  // shadow is a different shape, so it is switched off here.
  elevation: AppElevation.none,
  focusElevation: AppElevation.none,
  hoverElevation: AppElevation.none,
  highlightElevation: AppElevation.none,
);
