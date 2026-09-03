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
      elevation: AppElevation.overlay,
    );
