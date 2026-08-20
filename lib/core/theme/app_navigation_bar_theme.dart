import 'package:flutter/material.dart';

import 'app_material_roles.dart';

/// The bottom bar's whole appearance.
///
/// Split out of `app_theme.dart` on the seam `app_chip_theme.dart` and
/// `app_button_themes.dart` were cut on — one component family, every state
/// declared by hand — when the active-state pass took that file past the
/// 400-line guard.
NavigationBarThemeData buildNavigationBarTheme(
  ColorScheme scheme,
  TextTheme texts,
  Color background,
) => NavigationBarThemeData(
  backgroundColor: background,
  // The active tab wears the brand, not a grey pill: with four quiet
  // destinations the selected one is the only colored thing on the bar,
  // which is what makes it findable at a glance (owner mockup,
  // 2026-08-20).
  indicatorColor: scheme.primaryContainer,
  iconTheme: WidgetStateProperty.resolveWith(
    (Set<WidgetState> states) => IconThemeData(
      color: states.contains(WidgetState.selected)
          ? brandInk(scheme)
          : scheme.onSurfaceVariant,
    ),
  ),
  // **The label follows the glyph.** Left unset it fell through to
  // `onSurface` for both states, so the active tab was a brand pill under
  // a navy word — the indicator said "here" and the label did not (owner
  // review, 2026-08-20).
  labelTextStyle: WidgetStateProperty.resolveWith(
    (Set<WidgetState> states) => texts.labelMedium!.copyWith(
      color: states.contains(WidgetState.selected)
          ? brandInk(scheme)
          : scheme.onSurfaceVariant,
      fontWeight: states.contains(WidgetState.selected)
          ? FontWeight.w600
          : null,
    ),
  ),
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  // Labels always visible, on every destination. The M3 default hides the
  // unselected ones, which leaves unlabelled icons whose selection is
  // readable only as a colour difference — exactly what an accessibility
  // review rejects.
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
);
