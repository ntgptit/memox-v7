import 'package:flutter/material.dart';

import '../../typography/app_typography.dart';
import '../../foundations/app_elevation.dart';

/// The bottom bar's whole appearance.
///
/// Split out of `app_theme.dart` on the seam `app_chip_theme.dart` and
/// `app_button_themes.dart` were cut on — one component family, every state
/// declared by hand — when the active-state pass took that file past the
/// 400-line guard.
NavigationBarThemeData buildNavigationBarTheme(
  ColorScheme scheme,
  TextTheme texts,
) => NavigationBarThemeData(
  // `surfaceContainer`, which is `_NavigationBarDefaultsM3.backgroundColor`.
  // It took the page colour before M100.22 — passed in as a `background`
  // parameter, so the bar was the one surface in the app whose role could not
  // be read off the theme. A bar painted the same colour as the page behind it
  // is not a bar; the ladder has a rung for exactly this and it is this one.
  backgroundColor: scheme.surfaceContainer,
  // `secondaryContainer` — M3's indicator role, restored at M100.22.
  //
  // It was `primaryContainer` from the owner mockup of 2026-08-20, on the
  // argument that the active tab should wear the brand. The argument was
  // sound and the fix was in the wrong layer: `secondaryContainer` was too
  // near the bar to read (4.22 L\* of step), so the component changed role
  // instead of the role changing tone. M100.22 moved the tone —
  // `AppMaterialRoles.secondaryContainerLight` carries the table — and the
  // indicator now steps 7.33 L\* off the bar in light and 7.99 in dark,
  // against the 7.16 the brand container gave.
  indicatorColor: scheme.secondaryContainer,
  iconTheme: WidgetStateProperty.resolveWith(
    (Set<WidgetState> states) => IconThemeData(
      color: states.contains(WidgetState.selected)
          ? scheme.onSecondaryContainer
          : scheme.onSurfaceVariant,
    ),
  ),
  // **The selected label is `onSurface`, which is M3's own answer and not the
  // indicator's ink.** The glyph sits *inside* the pill and takes the pill's
  // `on` colour; the label sits *below* it, on the bar, so it is read against
  // `surfaceContainer` and `onSurfaceVariant`'s stronger sibling is what
  // separates it from the three unselected words beside it — 15.65:1 in light
  // and 13.49:1 in dark, against those words' 5.92 and 6.72.
  //
  // It carried `onPrimaryContainer` from the 2026-08-20 review, which read the
  // label as part of the pill. `_NavigationBarDefaultsM3.labelTextStyle` does
  // not, and neither does the render: there is no pill under the word.
  //
  // **The selected weight goes through [AppTypography.withWeight].** Both
  // faces are variable fonts, and the renderer reads the `wght` axis over
  // `fontWeight` once the axis is present — `labelMedium` arrives carrying
  // wght 500, so a bare `copyWith(fontWeight: w600)` reported 600 to every
  // test that asked and painted 500 on the device. The exact bug the helper
  // exists for, found on this slot by the 2026-08 theme-composition review.
  labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    final bool isSelected = states.contains(WidgetState.selected);
    final TextStyle rung = isSelected
        ? AppTypography.withWeight(texts.labelMedium!, FontWeight.w600)
        : texts.labelMedium!;

    return rung.copyWith(
      color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
    );
  }),
  surfaceTintColor: Colors.transparent,
  elevation: AppElevation.none,
  // Labels always visible, on every destination. The M3 default hides the
  // unselected ones, which leaves unlabelled icons whose selection is
  // readable only as a colour difference — exactly what an accessibility
  // review rejects.
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
);
