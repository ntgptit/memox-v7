import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';

/// The snack bar — `MxMessenger` and `MxUndoSnackBar`.
SnackBarThemeData buildSnackBarTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => SnackBarThemeData(
  backgroundColor: scheme.inverseSurface,
  contentTextStyle: texts.bodyMedium?.copyWith(color: scheme.onInverseSurface),
  behavior: SnackBarBehavior.floating,
  // **The action is text, so it takes the snackbar's ink** (M100.86).
  // The handoff's `inversePrimary` reads 4.32:1 on the slate in light and
  // 2.40:1 in dark; the slate does not flip, and neither does the ink.
  actionTextColor: semantic.inversePrimaryInk,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  // The last overlay that let Material decide its depth: Dialog,
  // BottomSheet, PopupMenu and the FAB all state theirs, and this slot's
  // silence resolved to the SDK's 6.0. Stated, and **the same dp in both
  // modes since M100.35** — the brightness split this used to share with
  // the FAB was hiding a shadow by lying about a depth. See
  // `materialShadowColor`.
  //
  // **The snack bar cannot name its shadow colour, and that is recorded
  // rather than worked around** (A20.1 P1-12, INTENTIONALLY_ACCEPTED with
  // the SDK read). `SnackBarThemeData` has no `shadowColor` and
  // `snack_bar.dart` builds a bare `Material(elevation:, color:, shape:)`,
  // which in M3 resolves its shadow from `colorScheme.shadow`
  // (`material.dart:465`) — `ThemeData.shadowColor` is not consulted. In
  // dark that shadow is `#000000` over a page at L* 4.7: the same
  // measurement `materialShadowColor` encodes says it is invisible, so
  // nothing paints wrong, and no `MxSnackBar` wrapper is worth a slot the
  // framework does not offer. `component_depth_and_state_test.dart` pins
  // this exemption by name so it cannot widen.
  elevation: AppElevation.overlay,
);
