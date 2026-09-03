import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_spacing.dart';

/// Every `ListTile` in the app, and `MxListTile` with it.
///
/// One of the four component themes added at M4.8. The selected pair is the
/// one decision here that needed a measurement — see `selectedColor` below.
ListTileThemeData buildListTileTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => ListTileThemeData(
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.xs,
  ),
  minVerticalPadding: AppSpacing.sm,
  iconColor: scheme.onSurfaceVariant,
  textColor: scheme.onSurface,
  // **`primary`, and the ground is what used to make that hard.** A
  // selected row lands on `surfaceMuted`, not the page, and the old dark
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
  selectedTileColor: semantic.surfaceMuted,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
);
