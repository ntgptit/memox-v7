import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_icon_size.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_sizing.dart';
import '../../states/app_interaction_states.dart';

/// **`primary`/`onPrimary`, because the v3 registry names that pair** — and
/// this is the third time this slot has moved, so the history is worth having.
///
/// It was `primary`/`onPrimary` once before, from an owner mockup
/// (2026-08-20), on the argument that the screen's one create action should
/// wear the brand rather than the same clothes as the navigation bar's active
/// tab. #426/#427 reverted it to `_FABDefaultsM3`'s own pair, and correctly:
/// the argument was sound but the fix was in the wrong layer — it swapped one
/// accent pair for another on the component, the substitution those PRs
/// removed from five other components.
///
/// What is different now is where the instruction comes from. v3 states the
/// pair in the registry, so the binding *is* the design system's rather than a
/// component's local preference, and AD-14's invariant is intact.
///
/// **It also fixes a measurement nobody had taken.** `primaryContainer`
/// against the page is **1.19:1 in light and 1.64:1 in dark** — the app's one
/// create action was a shape you found by knowing where it was. `primary`
/// reads **4.39:1 and 7.39:1** there. The glyph gives some of that back
/// (10.37 → 4.63 in light, 8.81 → 6.76 in dark) and stays above the 4.5:1 a
/// label owes (M100.100).
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
  // The v3 Fab contract's own dimension table — a fixed 52×52 painted box
  // and a 20dp glyph — not `_FABDefaultsM3`'s 56/24. `sizeConstraints` is
  // the mechanism `FloatingActionButton` already resolves through for its
  // `regular` type, so no widget-level `SizedBox` is needed.
  sizeConstraints: const BoxConstraints.tightFor(
    width: AppSizing.fab,
    height: AppSizing.fab,
  ),
  iconSize: AppIconSize.mdCompact,
  // **The state washes move with the pair, or they describe the old one.**
  // M3's defaults are not derived from the effective foreground — the SDK
  // hardcodes `onPrimaryContainer` at 8/10/10% — so overriding the resting
  // pair above and leaving these null meant hover, focus and press painted
  // another system's ink over this system's fill (theme-composition
  // review, 2026-08). The rule Chip and the buttons already follow: change
  // a component's resting pair, and every state default it owns is yours
  // to restate — which is why these three move with the pair above.
  hoverColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.hoverControl),
  focusColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.focus),
  splashColor: scheme.onPrimary.withValues(alpha: AppStateOpacity.pressed),
  // **One dp in both modes since M100.35.** These four read
  // `overlayElevationFor(scheme)`, which returned zero in dark — so the FAB
  // *claimed* to be flush with the page in one theme and eight dp above it in
  // the other, to express something that was only ever about paint. The dark
  // shadow it was hiding is invisible on its own terms (`materialShadowColor`
  // carries the measurement, and since A20.1 P1-12 `app_theme.dart` wires it
  // through `ThemeData.shadowColor`, which is the one slot the FAB's
  // `RawMaterialButton` reads — `button.dart:387`), and Flutter 3.44.8 makes
  // the substitution safe:
  // `_FABDefaultsM3` sets no `surfaceTintColor`, so elevation has no effect
  // here beyond the shadow.
  //
  // **Flat across all four states, and that is the mobile reading.** Canonical
  // M3 is 6 / 6 / 8 / 6 — the 8 is *hover*, which Android has no pointer to
  // produce. A single `AppElevation.overlay` keeps the app's own scale and
  // spends nothing on a state the release target cannot reach.
  elevation: AppElevation.overlay,
  focusElevation: AppElevation.overlay,
  hoverElevation: AppElevation.overlay,
  highlightElevation: AppElevation.overlay,
);
