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
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
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
