import 'package:flutter/material.dart';

import '../foundations/app_radius.dart';
import '../foundations/app_semantic_colors.dart';
import '../foundations/app_sizing.dart';
import '../states/app_interaction_states.dart';

/// `MxIconButton`, and every bare `IconButton` under it.
///
/// One of the four component themes added at M4.8, each because a shared
/// component had started rendering through it.
IconButtonThemeData buildIconButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => IconButtonThemeData(
  style:
      IconButton.styleFrom(
        // The 48×48 minimum lives here rather than in `MxIconButton`, so no
        // screen can pass a smaller one — there is no parameter to pass.
        minimumSize: const Size.square(AppSizing.touchTarget),
        foregroundColor: scheme.onSurfaceVariant,
        // Named, not left to `defaultStyleOf` where no audit can see it.
        disabledForegroundColor: semantic.onDisabled,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ).copyWith(
        // Hover, press and focus declared. Left null they came from
        // Material, which is neither the kit nor what every other control
        // in this app resolves.
        overlayColor: AppInteractionStates.iconOverlay(scheme),
        // Focus draws a ring, not just the tint: measured off the goldens
        // that tint alone is 1.15:1 against the surface behind it in both
        // modes, where WCAG 1.4.11 asks 3:1 of a focus indicator.
        side: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.focused)) return null;
          return AppInteractionStates.focusIndicator(scheme);
        }),
      ),
);
