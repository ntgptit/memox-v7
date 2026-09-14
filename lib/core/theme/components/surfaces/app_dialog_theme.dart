import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../overlays/app_backdrop_recipe.dart';
import '../../foundations/app_elevation.dart';

/// The three surfaces that appear **over** the page and then go away: the
/// dialog, the modal bottom sheet and the snack bar.
///
/// One family by behaviour rather than by widget class. Each has a barrier
/// or a float; each has to answer "does this mode paint a shadow?", and all
/// three answer it through `overlayElevationFor` or a stated `elevation: 0`
/// rather than by leaving the slot silent; two of them share
/// `modalBarrierColor`. Dialog and BottomSheet were two of the four
/// component themes added at M4.8, SnackBar came with UC-05.
///
/// `timePickerTheme` and `popupMenuTheme` are overlays too and live in
/// `app_overlay_themes.dart` beside the non-modal chrome. That seam is
/// history rather than taxonomy — they were split out earlier — and moving
/// them now would be churn in a pass whose whole claim is that no pixel
/// moved.
DialogThemeData buildDialogTheme(ColorScheme scheme, TextTheme texts) =>
    DialogThemeData(
      barrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      // The handoff Dialog lifts on `shadow-card`, which has no
      // `DialogThemeData` slot: the raised elevation's Material shadow stands
      // in for it (D19), in `materialShadowColor`, which carries the scheme's
      // shadow in light and nothing in dark. AD-14 makes depth a measured
      // target per mode rather than one fixed mechanism, so the scrim and a
      // light-mode shadow together are within it. Radius 20, no edge.
      elevation: AppElevation.raised,
      shadowColor: materialShadowColor(scheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titleTextStyle: texts.titleMedium?.copyWith(color: scheme.onSurface),
      contentTextStyle: texts.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      // **`actionsPadding` deliberately stays unset here** — it moved to
      // `MxDialogMetrics` while this was in flight (#348). The footer's width
      // has to be *computed* from that inset, so the dialog states it on the
      // widget; a theme entry saying the same 24 would be a second answer that
      // all three dialogs override, and the one that could silently drift out
      // of step with the arithmetic that reads it.
    );
