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
  // **A `primary` tint, which v3 names for this slot** (M100.100) — 14% in
  // light, 20% in dark, composited here because AD-14 §1 forbids paint-time
  // alpha.
  //
  // **It reverses M100.22, and that is worth stating plainly.** The slot was
  // `primaryContainer` from the owner mockup of 2026-08-20; M100.22 put it
  // back on M3's `secondaryContainer` and moved that role's *tone* instead,
  // reaching a 7.33 L\* step off the bar in light and 7.99 in dark. v3 asks
  // for the brand again, and as a tint rather than a container: the pill now
  // reads 1.18:1 against the bar in light and 1.41:1 in dark, where
  // `secondaryContainer` read 1.06 and 1.32. So the indicator is *slightly*
  // more visible than it was and still nowhere near a boundary — which is why
  // the selection cue does not rest on it. The glyph and the label carry it,
  // and the outlined/filled icon pair carries it without colour at all.
  //
  // Composited at the slot rather than in a helper: `m3_role_binding_guard`
  // reads the role out of the declaration that names the slot, and a helper
  // takes `scheme.primary` out of its sight.
  indicatorColor: Color.alphaBlend(
    scheme.primary.withValues(
      alpha: scheme.brightness == Brightness.dark
          ? _indicatorTintDark
          : _indicatorTintLight,
    ),
    scheme.surfaceContainer,
  ),
  // **Selected ink is `primary`, per v3.** It was `onSecondaryContainer`,
  // the pill's own `on` colour. The glyph sits inside the pill and reads
  // 3.34:1 against it in light, 3.69:1 in dark — enough for a graphic, short
  // of the 4.5:1 a *label* owes; see the label resolver below, which carries
  // the same figure and the same record.
  iconTheme: WidgetStateProperty.resolveWith(
    (Set<WidgetState> states) => IconThemeData(
      color: states.contains(WidgetState.selected)
          ? scheme.primary
          : scheme.onSurfaceVariant,
    ),
  ),
  // **The selected label is `primary`, per v3, and this is the one real
  // accessibility cost in the chrome wave** (M100.100).
  //
  // The label sits *below* the pill, on the bar, so it is read against
  // `surfaceContainer`. `onSurface` gave **15.03:1 in light and 11.01:1 in
  // dark**; `primary` gives **3.95:1 and 5.22:1**. Small text owes 4.5:1, so
  // **light is under the floor** — on the word that tells a user which tab
  // they are in. The owner chose v3 with that figure in hand.
  //
  // What still carries the selection when the colour does not: the
  // outlined/filled icon pair (no colour at all), the w600 weight below, and
  // `Semantics(selected:)`. `component_depth_and_state_test.dart` pins 3.95
  // as an intermediate-state record — it blocks a further drop and names what
  // would close it, which is a darker `primary` for ink use or a bar ground
  // further from it. It is not a statement that 3.95 is adequate.
  //
  // Before v3 it also carried `onPrimaryContainer` briefly, from the
  // 2026-08-20 review, which read the label as part of the pill.
  // `_NavigationBarDefaultsM3.labelTextStyle` does not, and neither does the
  // render: there is no pill under the word.
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
      color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
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

/// v3's indicator tint: 14% of `primary` in light, 20% in dark.
const double _indicatorTintLight = 0.14;
const double _indicatorTintDark = 0.20;
