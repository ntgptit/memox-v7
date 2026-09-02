import 'package:flutter/material.dart';

import '../foundations/app_elevation.dart';
import '../foundations/app_radius.dart';
import '../states/app_interaction_states.dart';

/// **The brand pair, stated.** Material 3's default is the
/// `primaryContainer` tonal pair, which puts the screen's one create action
/// in the same clothes as the navigation bar's active tab. The owner's
/// mockup draws it as the brand fill (owner review, 2026-08-20), and the
/// pair carries its own contrast guarantee.
FloatingActionButtonThemeData buildFloatingActionButtonTheme(
  ColorScheme scheme,
) => FloatingActionButtonThemeData(
  backgroundColor: scheme.primary,
  foregroundColor: scheme.onPrimary,
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
  hoverColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.hoverControl),
  focusColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.focus),
  splashColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.pressed),
  // Until the elevation matched `shadowsFor`, the FAB was the one object
  // in dark carrying a Material shadow while every other surface had
  // measurably opted out.
  elevation: overlayElevationFor(scheme),
  focusElevation: overlayElevationFor(scheme),
  hoverElevation: overlayElevationFor(scheme),
  highlightElevation: overlayElevationFor(scheme),
);
