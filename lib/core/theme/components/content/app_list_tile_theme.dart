import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_sizing.dart';
import '../../foundations/app_spacing.dart';

/// Every `ListTile` in the app, and `MxListTile` with it.
///
/// One of the four component themes added at M4.8. The selected pair is the
/// one decision here that needed a measurement — see `selectedColor` below.
///
/// **No `textColor`** (M100.36, #431 P1-1). `ListTile` 3.44.8 takes a non-null
/// `textColor` as `effectiveColor` and copies it onto the title, the subtitle
/// *and* the leading/trailing text style alike (`list_tile.dart:920`, `:934`,
/// `:899`), so `textColor: onSurface` painted every second line in the app —
/// `MxListTile`, `RadioListTile`, `CheckboxListTile`, `SwitchListTile` — in
/// the primary ink, and the row's hierarchy was carried by 16-vs-14 alone.
/// The three text styles below name their own M3 roles instead, which is what
/// `_LisTileDefaultsM3` does, and `m3_role_binding_guard_test.dart` reads
/// them at source level.
ListTileThemeData buildListTileTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => ListTileThemeData(
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.xs,
  ),
  minVerticalPadding: AppSpacing.sm,
  // **The reading row is 56, stated** (M100.36 4J, #431 P2-1). It was
  // Flutter's `_defaultTileHeight` all along — 56 / 72 / 88 for one, two and
  // three lines — and nothing in the design system owned it. 48 is the touch
  // *floor* (`AppSizing.touchTarget`), not a comfortable reading row: the kit
  // says 48 for a desktop tile and the app renders 56 + 4 + 4 for a phone.
  // Two-line rows grow past this on their own; the number is a minimum, so
  // no text is ever clipped to hold it.
  minTileHeight: AppSizing.rowMinHeight,
  iconColor: scheme.onSurfaceVariant,
  titleTextStyle: texts.bodyLarge!.copyWith(color: scheme.onSurface),
  subtitleTextStyle: texts.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
  // A trailing `Text` fell to `_LisTileDefaultsM3.leadingAndTrailingTextStyle`
  // — `labelSmall`, 11px — below anything this app uses for readable text
  // (#431 P2-8). The secondary rung, in the secondary ink.
  leadingAndTrailingTextStyle: texts.bodyMedium!.copyWith(
    color: scheme.onSurfaceVariant,
  ),
  // **`primary`, and the ground is what used to make that hard.** A
  // selected row lands on `surfaceSelected`, not the page, and the old dark
  // fill tone measured 2.45:1 there — under WCAG 1.4.11's 3:1 for a state
  // and far under the 4.5:1 its label needs, which is why a second token
  // stood here until M100.19. Tone 80 clears both grounds outright.
  //
  // Not the `secondaryContainer` pair NavigationBar and the chips take,
  // though that would also pass: a row is a wide target, and a tinted fill
  // stretched across a list reads as a button. The muted tile with an
  // accented label keeps the grammar — brand tint means selected — at a
  // weight a row can carry. `ListTile` has no M3 selected-fill default to
  // depart from; `selectedTileColor` is null in Material and the choice is
  // the app's to make.
  selectedColor: scheme.primary,
  // **`surfaceSelected` — the one app-owned "picked" surface** (M100.36 4I,
  // #431 P1-4). It was `surfaceMuted`, a neutral grey, while `MxCard`'s tint
  // for the same meaning was `surfaceSelected`, an indigo tint; two fills for
  // one idea, argued in two files that never cited each other. `MxCard`
  // keeps its own; this one now shares it. `primary` measures 5.4:1 light
  // and 7.3:1 dark on it (`component_depth_and_state_test.dart`).
  selectedTileColor: semantic.surfaceSelected,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
);
