import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_spacing.dart';

/// The time picker, as the reminder screen's `showTimePicker` renders it.
///
/// **The one dialog in the app that does not inherit `dialogTheme`, which is
/// why it needs its own entry.** `TimePickerDialog` builds its `Dialog` from
/// `_TimePickerDefaultsM3` rather than from the theme every other dialog reads:
/// elevation 6, a 28px radius and a `surfaceContainerHigh` background. So
/// without this the reminder flow opened the single surface in the app that
/// carries a Material shadow and a different corner — while `dialogTheme`
/// spends a paragraph on why dialogs are `elevation: 0` with a hairline (see
/// F15 and AD-14).
///
/// The values below are `dialogTheme`'s, restated in the slots this component
/// happens to read. Nothing here is a new decision; every one of them is the
/// app's existing answer arriving somewhere it was not being asked.
///
/// **The number fields are the exception, and they are a real decision.** M3
/// gives the hour and minute a `primaryContainer` fill when selected. That is
/// already the app's answer for a selected control — the navigation bar's
/// indicator and the filter pills use the same pair — so it stays, and the ink
/// on it is `onPrimaryContainer`, the container's own `on` role: 11.46:1 in
/// light and 8.87:1 in dark. This used to be a function that switched role by
/// brightness, because `primary` on that fill measured 2.13:1 in dark
/// (M100.19).
TimePickerThemeData buildTimePickerTheme(ColorScheme scheme, TextTheme texts) {
  final selected = scheme.onPrimaryContainer;

  return TimePickerThemeData(
    backgroundColor: scheme.surfaceContainerHigh,
    // Zero, and a hairline instead — the same trade `dialogTheme` makes, for
    // the same reason: AD-14 admits one depth mechanism and this app spends it
    // on the surface ladder.
    elevation: AppElevation.none,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    padding: const EdgeInsets.all(AppSpacing.xl),
    helpTextStyle: texts.labelLarge?.copyWith(color: scheme.onSurfaceVariant),

    // The dial. Its face is the inset-tile surface, so the ring of numbers
    // reads as a panel within the sheet rather than as a hole in it.
    // **`WidgetStateColor`, not `WidgetStateProperty<Color>`.** Every slot in
    // `TimePickerThemeData` is typed `Color?` rather than a state property, so
    // the per-state values have to arrive as a Color subclass. Writing the
    // property form here does not compile, which is the good outcome; writing
    // a flat colour compiles and silently drops the selected state, which is
    // the one to watch for.
    dialBackgroundColor: scheme.surfaceContainerHighest,
    dialHandColor: scheme.primary,
    dialTextColor: WidgetStateColor.resolveWith((states) {
      // The number the hand is on sits ON the hand, so it takes the fill's
      // partner: 7.51:1 in light, 5.88:1 in dark.
      if (states.contains(WidgetState.selected)) return scheme.onPrimary;

      return scheme.onSurface;
    }),
    dialTextStyle: texts.bodyLarge,

    // The hour and minute fields above the dial.
    // `primaryContainer` selected, `surfaceContainerHighest` at rest — both
    // `_TimePickerDefaultsM3.hourMinuteColor`'s. The resting fill read
    // `surfaceMuted`, which is `surfaceContainerHigh`: one rung low, and a rung
    // the app happened to have a name for rather than the one M3 asks for.
    hourMinuteColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return scheme.primaryContainer;

      return scheme.surfaceContainerHighest;
    }),
    hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return selected;

      return scheme.onSurface;
    }),
    hourMinuteTextStyle: texts.displaySmall,
    hourMinuteShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),

    // AM/PM. Only some locales show it, which is exactly why it is themed
    // rather than left out: a component nobody sees in `en` is one an
    // `en_US` reviewer sees on the first screenshot.
    // **`tertiaryContainer`, which is M3's role here and not the one this
    // theme first used.** It shipped as `primaryContainer` — the app's answer
    // for *a selected control* — and that is the right answer to the wrong
    // question. M3 gives the hour/minute field `primaryContainer` and AM/PM
    // `tertiaryContainer` on purpose: they are two different questions
    // ("which unit am I editing" and "morning or afternoon") and one fill for
    // both loses the distinction the component is drawn to make.
    //
    // **What adopting it buys here is less than it should be, and the number
    // is worth recording rather than discovering later.** Against
    // `primaryContainer` the app's `tertiaryContainer` measures **1.10:1 in
    // light and 1.29:1 in dark** — the two containers differ in hue but barely
    // in lightness, so the distinction reads as a tint rather than as a
    // separation. That is a property of a hand-tuned palette whose tertiary
    // carries 8.8 chroma against primary's 14.5, not of this mapping: the fix,
    // if the owner wants the distinction to carry, is a tone on
    // `tertiaryContainer`, not a different role in this file.
    //
    // It also gives the tertiary family its first renderer. Until now it was
    // declared only so `fromSeed` could not invent it.
    dayPeriodColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return scheme.tertiaryContainer;
      }

      return Colors.transparent;
    }),
    dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
      // 9.75:1 in light, 7.24:1 in dark on the fill above.
      if (states.contains(WidgetState.selected)) {
        return scheme.onTertiaryContainer;
      }

      return scheme.onSurfaceVariant;
    }),
    dayPeriodTextStyle: texts.titleMedium,
    dayPeriodBorderSide: BorderSide(color: scheme.outline),
    dayPeriodShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: BorderSide(color: scheme.outline),
    ),

    // **`inputDecorationTheme` is deliberately left to Material.** The picker's
    // keyboard-entry mode draws the hour and minute as display-scale fields;
    // `buildInputDecorationTheme` is padded and radiused for a 16px body
    // field, and forcing it on them would be a layout decision made without a
    // screen to check it against — which is the one thing this file's own rule
    // refuses. It becomes worth deciding the day a mock shows that mode.
    entryModeIconColor: scheme.onSurfaceVariant,
  );
}
