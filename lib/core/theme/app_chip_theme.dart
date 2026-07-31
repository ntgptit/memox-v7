import 'package:flutter/material.dart';

import 'app_icon_size.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';

/// The chip theme — `MxPillButton`'s entire appearance.
///
/// Split from `app_theme.dart` when that file crossed the 400-line guard, on the
/// same seam `app_button_themes.dart` was cut on: one component family, every
/// interaction state declared by hand, read by nothing else in the theme.

ChipThemeData buildChipTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => ChipThemeData(
  backgroundColor: scheme.surface,
  selectedColor: scheme.secondaryContainer,
  showCheckmark: false,
  side: BorderSide(color: semantic.borderSubtle),
  shape: const StadiumBorder(),
  labelStyle: texts.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
  secondaryLabelStyle: texts.labelLarge?.copyWith(
    color: scheme.onSecondaryContainer,
  ),
  iconTheme: IconThemeData(
    size: AppIconSize.sm,
    color: scheme.onSurfaceVariant,
  ),
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  ),
);
