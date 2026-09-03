import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';
import '../../states/app_interaction_states.dart';

/// **`primaryContainer`/`onPrimaryContainer` — `_FABDefaultsM3`'s own pair.**
///
/// It was `primary`/`onPrimary` from an owner mockup (2026-08-20), on the
/// argument that the screen's one create action should wear the brand rather
/// than the same clothes as the navigation bar's active tab. The argument was
/// sound and the fix was in the wrong layer: it swapped one accent pair for
/// another on the component, which is exactly the substitution #426/#427
/// removed from five other components. AD-14's invariant is that the palette
/// moves and the binding does not.
///
/// So the binding is canonical again. If the FAB reads as insufficiently
/// branded, the answers are the `primaryContainer` family's tone, or depth,
/// geometry and placement — not this slot.
FloatingActionButtonThemeData buildFloatingActionButtonTheme(
  ColorScheme scheme,
) => FloatingActionButtonThemeData(
  backgroundColor: scheme.primaryContainer,
  foregroundColor: scheme.onPrimaryContainer,
  // The house corner, stated here rather than at the one call site it
  // used to live on (deck list): a FAB shape is component grammar, and
  // M3's default is the 16dp large-component squircle this app does not
  // use anywhere else.
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
  // **The state washes move with the pair, or they describe the old one.**
  // M3's defaults are not derived from the effective foreground — the SDK
  // hardcodes `onPrimaryContainer` at 8/10/10% — so overriding the resting
  // pair above and leaving these null meant hover, focus and press painted
  // another system's ink over this system's fill (theme-composition
  // review, 2026-08). The rule Chip and the buttons already follow: change
  // a component's resting pair, and every state default it owns is yours
  // to restate.
  hoverColor: scheme.onPrimaryContainer.withValues(
    alpha: AppStateOpacity.hoverControl,
  ),
  focusColor: scheme.onPrimaryContainer.withValues(
    alpha: AppStateOpacity.focus,
  ),
  splashColor: scheme.onPrimaryContainer.withValues(
    alpha: AppStateOpacity.pressed,
  ),
  // Until the elevation matched `shadowsFor`, the FAB was the one object
  // in dark carrying a Material shadow while every other surface had
  // measurably opted out.
  elevation: overlayElevationFor(scheme),
  focusElevation: overlayElevationFor(scheme),
  hoverElevation: overlayElevationFor(scheme),
  highlightElevation: overlayElevationFor(scheme),
);
