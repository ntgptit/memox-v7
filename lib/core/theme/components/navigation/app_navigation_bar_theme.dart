import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_semantic_colors.dart';

/// The bottom bar's whole appearance.
///
/// Split out of `app_theme.dart` on the seam `app_chip_theme.dart` and
/// `app_button_themes.dart` were cut on — one component family, every state
/// declared by hand — when the active-state pass took that file past the
/// 400-line guard.
NavigationBarThemeData buildNavigationBarTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => NavigationBarThemeData(
  // Solid `surface` — the handoff's own fallback for its glass chrome (D7).
  // The bar parts from content with `shadow-chrome` (`MxNavigationBar`), not
  // with a tier of its own.
  backgroundColor: scheme.surface,
  // **`primary`, the kit's pill, over M3's `secondaryContainer`** (owner
  // decision 4: kit beats the canonical role). The glyph inside it takes the
  // pill's `on` role.
  indicatorColor: scheme.primary,
  iconTheme: WidgetStateProperty.resolveWith(
    (Set<WidgetState> states) => IconThemeData(
      color: states.contains(WidgetState.selected)
          ? scheme.onPrimary
          : scheme.onSurfaceVariant,
    ),
  ),
  // The active label sits *below* the pill, on the bar, and the kit inks it
  // with the brand. As text it takes the brand's text ink, `accentInk`, not
  // `primary` (owner decision 2). **No selected re-weight:** `labelMedium` is
  // the handoff's 12/600 label already (D1, PLAN-DEV-2.4).
  labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (!states.contains(WidgetState.selected)) {
      return texts.labelMedium!.copyWith(color: scheme.onSurfaceVariant);
    }
    return texts.labelMedium!.copyWith(color: semantic.accentInk);
  }),
  surfaceTintColor: Colors.transparent,
  elevation: AppElevation.none,
  // Labels always visible, on every destination. The M3 default hides the
  // unselected ones, which leaves unlabelled icons whose selection is
  // readable only as a colour difference — exactly what an accessibility
  // review rejects.
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
);
