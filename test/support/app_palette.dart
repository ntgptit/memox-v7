import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_colors.dart';
import 'package:memox/core/theme/app_material_roles.dart';

/// The approved A2 Quizlet Navy Indigo palette, as flat lists.
///
/// One list per brightness, shared by every check that needs to ask "is this
/// colour ours". Two consumers today — the `ColorScheme` role test and the
/// visual audit's palette-closure rule — and they must not drift apart, because
/// a screen passing one while failing the other tells you nothing about which
/// answer is right.

/// A list, not a set: several roles deliberately share a token — white is the
/// card, the raised surface and three `on*` labels at once — and a set literal
/// calls that a duplicate.
final List<Color> lightPaletteTokens = <Color>[
  AppColors.backgroundLight,
  AppColors.surfaceLight,
  AppColors.surfaceMutedLight,
  AppColors.surfaceElevatedLight,
  AppColors.textPrimaryLight,
  AppColors.textSecondaryLight,
  AppColors.borderAccentLight,
  AppColors.borderSubtleLight,
  AppColors.focusRingLight,
  AppColors.primaryLight,
  AppColors.onPrimaryLight,
  AppColors.secondaryActionLight,
  AppColors.streakContainerLight,
  AppColors.onStreakContainerLight,
  AppColors.progressTrackLight,
  AppColors.progressFillLight,
  AppColors.successLight,
  AppColors.warningLight,
  AppColors.dangerLight,
  AppColors.infoLight,
  AppMaterialRoles.primaryContainerLight,
  AppMaterialRoles.onPrimaryContainerLight,
  AppMaterialRoles.secondaryLight,
  AppMaterialRoles.onSecondaryLight,
  AppMaterialRoles.secondaryContainerLight,
  AppMaterialRoles.onSecondaryContainerLight,
  AppMaterialRoles.tertiaryLight,
  AppMaterialRoles.onTertiaryLight,
  AppMaterialRoles.tertiaryContainerLight,
  AppMaterialRoles.onTertiaryContainerLight,
  AppMaterialRoles.onErrorLight,
  AppMaterialRoles.errorContainerLight,
  AppMaterialRoles.onErrorContainerLight,
  AppMaterialRoles.surfaceContainerLowestLight,
  AppMaterialRoles.surfaceContainerLowLight,
  AppMaterialRoles.surfaceContainerLight,
  AppMaterialRoles.surfaceContainerHighLight,
  AppMaterialRoles.surfaceContainerHighestLight,
  AppMaterialRoles.surfaceDimLight,
  AppMaterialRoles.surfaceBrightLight,
  AppMaterialRoles.inverseSurfaceLight,
  AppMaterialRoles.onInverseSurfaceLight,
  AppMaterialRoles.inversePrimaryLight,
  AppColors.disabledSurfaceLight,
  AppColors.onDisabledLight,
  AppColors.shadowLight,
  AppColors.scrimLight,
];

/// A list, not a set: several roles deliberately share a token — white is the
/// card, the raised surface and three `on*` labels at once — and a set literal
/// calls that a duplicate.
final List<Color> darkPaletteTokens = <Color>[
  AppColors.backgroundDark,
  AppColors.surfaceDark,
  AppColors.surfaceMutedDark,
  AppColors.surfaceElevatedDark,
  AppColors.textPrimaryDark,
  AppColors.textSecondaryDark,
  AppColors.borderAccentDark,
  AppColors.borderSubtleDark,
  AppColors.focusRingDark,
  AppColors.primaryDark,
  AppColors.onPrimaryDark,
  AppColors.secondaryActionDark,
  AppColors.streakContainerDark,
  AppColors.onStreakContainerDark,
  AppColors.progressTrackDark,
  AppColors.progressFillDark,
  AppColors.successDark,
  AppColors.warningDark,
  AppColors.dangerDark,
  AppColors.infoDark,
  AppMaterialRoles.primaryContainerDark,
  AppMaterialRoles.onPrimaryContainerDark,
  AppMaterialRoles.secondaryDark,
  AppMaterialRoles.onSecondaryDark,
  AppMaterialRoles.secondaryContainerDark,
  AppMaterialRoles.onSecondaryContainerDark,
  AppMaterialRoles.tertiaryDark,
  AppMaterialRoles.onTertiaryDark,
  AppMaterialRoles.tertiaryContainerDark,
  AppMaterialRoles.onTertiaryContainerDark,
  AppMaterialRoles.onErrorDark,
  AppMaterialRoles.errorContainerDark,
  AppMaterialRoles.onErrorContainerDark,
  AppMaterialRoles.surfaceContainerLowestDark,
  AppMaterialRoles.surfaceContainerLowDark,
  AppMaterialRoles.surfaceContainerDark,
  AppMaterialRoles.surfaceContainerHighDark,
  AppMaterialRoles.surfaceContainerHighestDark,
  AppMaterialRoles.surfaceDimDark,
  AppMaterialRoles.surfaceBrightDark,
  AppMaterialRoles.inverseSurfaceDark,
  AppMaterialRoles.onInverseSurfaceDark,
  AppMaterialRoles.inversePrimaryDark,
  AppColors.disabledSurfaceDark,
  AppColors.onDisabledDark,
  AppColors.shadowDark,
  AppColors.scrimDark,
  // The `*Fixed` family is the same in both schemes, so the dark scheme
  // legitimately carries these light tokens.
  AppMaterialRoles.primaryContainerLight,
  AppMaterialRoles.onPrimaryContainerLight,
  AppColors.primaryLight,
  AppMaterialRoles.secondaryContainerLight,
  AppMaterialRoles.onSecondaryContainerLight,
  AppMaterialRoles.secondaryLight,
  AppMaterialRoles.tertiaryContainerLight,
  AppMaterialRoles.onTertiaryContainerLight,
  AppMaterialRoles.tertiaryLight,
];
