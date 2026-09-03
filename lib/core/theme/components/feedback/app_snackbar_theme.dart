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
      // silence resolved to the SDK's 6.0 — in dark too, where every other
      // surface has measurably opted out of shadows. Same brightness split as
      // the FAB, for the same reason (theme-composition review, 2026-08).
      elevation: overlayElevationFor(scheme),
    );
