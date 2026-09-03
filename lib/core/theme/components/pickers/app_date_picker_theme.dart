import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_stroke.dart';
import '../../states/app_interaction_states.dart';

/// The date picker — the reminder screen's likely companion to the time picker,
/// and the history range in `docs/wbs.md`'s deferred *study answers* screen.
///
/// **The same bug as the time picker, verified rather than assumed.**
/// `_DatePickerDefaultsM3.backgroundColor` is `surfaceContainerHigh` and the
/// dialog it builds carries Material's elevation, so a date picker opened today
/// would be the one surface in the app with a shadow and a foreign corner —
/// exactly what `buildTimePickerTheme` exists to stop. Everything below is
/// `dialogTheme`'s answer arriving in the slots this component reads.
DatePickerThemeData buildDatePickerTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) {
  return DatePickerThemeData(
    backgroundColor: scheme.surfaceContainerHigh,
    elevation: AppElevation.none,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    headerForegroundColor: scheme.onSurfaceVariant,
    weekdayStyle: texts.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
    dayStyle: texts.bodyMedium,
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
      if (states.contains(WidgetState.selected)) return scheme.onPrimary;

      return scheme.onSurface;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.primary;

      return null;
    }),
    dayOverlayColor: AppInteractionStates.controlOverlay(scheme),
    // Today is a ring, not a fill — M3's own answer, and the one that keeps a
    // filled day meaning *selected* and nothing else.
    todayBorder: BorderSide(
      color: scheme.primary,
      width: AppStroke.selectionControl,
    ),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.onPrimary;

      return scheme.primary;
    }),
    // `secondaryContainer`, which is `_DatePickerDefaultsM3`'s own answer and
    // the same tint the pills and the navigation indicator take. It read
    // `primaryContainer` on that reasoning while those two controls were also
    // substituted; M100.22 moved all three back together.
    rangeSelectionBackgroundColor: scheme.secondaryContainer,
    rangePickerHeaderForegroundColor: scheme.onSurfaceVariant,
    // A selected year is a `primary` fill under `onPrimary`, exactly as a
    // selected day is — `_DatePickerDefaultsM3` names both, and the container
    // pair that stood here made the year grid say "selected" in a different
    // voice from the day grid two taps away.
    yearForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.onPrimary;

      return scheme.onSurfaceVariant;
    }),
    yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.primary;

      return null;
    }),
    dividerColor: scheme.outlineVariant,
  );
}
