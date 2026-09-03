import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_sizing.dart';
import '../../states/app_interaction_states.dart';

/// The segmented button — a range switch (week / month / year) on the deferred
/// progress and study-history screens.
///
/// **`secondaryContainer` / `onSecondaryContainer`, which is
/// `_SegmentedButtonDefaultsM3`'s pair and now the app's.** This slot did carry
/// the brand container, on the sound argument that the app should have one
/// answer for "this segment is the active one" and that the navigation
/// indicator and `MxPillButton` already drew it. The argument was right and the
/// role was wrong: all three had been re-pointed away from M3 for the same
/// reason, so agreeing with each other only made the deviation consistent.
/// M100.22 moved all three back and moved the tone underneath them instead.
///
/// The label is the container's own `on` role — the M3 pairing — rather than
/// `primary`, which is a fill and not the ink for a fill.
SegmentedButtonThemeData buildSegmentedButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => SegmentedButtonThemeData(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return states.contains(WidgetState.selected)
            ? semantic.disabledSurface
            : Colors.transparent;
      }
      // `secondaryContainer`/`onSecondaryContainer` —
      // `_SegmentedButtonDefaultsM3` names both, and M100.22 restored them
      // from the brand container the 2026-08-20 review had put here. The
      // review wanted the selected segment to carry brand; the tone move in
      // `AppMaterialRoles.secondaryContainerLight` is what pays for that
      // without the segment claiming a role that means "primary action".
      if (states.contains(WidgetState.selected)) {
        return scheme.secondaryContainer;
      }

      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
      if (states.contains(WidgetState.selected)) {
        return scheme.onSecondaryContainer;
      }

      // `onSurface`, not `onSurfaceVariant`: an unselected *segment* is still a
      // live target inside a control the user is reading, where an unselected
      // nav destination is one of four peers. M3 splits them that way and this
      // had taken the navigation answer.
      return scheme.onSurface;
    }),
    overlayColor: AppInteractionStates.controlOverlay(scheme),
    // `_SegmentedButtonDefaultsM3.side` has two answers and neither is a focus
    // ring: disabled, then `outline`. The focus branch that stood here returned
    // `primary`, so tabbing onto a segment replaced the control's boundary role
    // — removed at M100.23. The keyboard cue is `overlayColor` above, which is
    // where M3 puts it.
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: semantic.disabledSurface);
      }

      return BorderSide(color: scheme.outline);
    }),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    minimumSize: const WidgetStatePropertyAll<Size>(
      Size.fromHeight(AppSizing.touchTarget),
    ),
  ),
);
