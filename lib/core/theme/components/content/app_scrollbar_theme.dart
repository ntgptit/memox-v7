import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';

/// The scroll thumb.
///
/// Long lists are the app's main surface, so the thumb is on screen often. Left
/// to Material it is a neutral grey with no seed in it.
ScrollbarThemeData buildScrollbarTheme(ColorScheme scheme) =>
    ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll<Color>(
        scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      radius: const Radius.circular(AppRadius.sm),
      thickness: const WidgetStatePropertyAll<double>(4),
    );
