import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';

/// The snack bar — `MxMessenger` and `MxUndoSnackBar`.
SnackBarThemeData buildSnackBarTheme(ColorScheme scheme, TextTheme texts) =>
    SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: texts.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      // The SDK's own default, restated so the action's colour is a decision
      // on record rather than a silence that resolves to one.
      actionTextColor: scheme.inversePrimary,
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
      // dark that shadow is `#03040B` over a page at L* 4.1: the same
      // measurement `materialShadowColor` encodes says it is invisible, so
      // nothing paints wrong, and no `MxSnackBar` wrapper is worth a slot the
      // framework does not offer. `component_depth_and_state_test.dart` pins
      // this exemption by name so it cannot widen.
      elevation: AppElevation.overlay,
    );
