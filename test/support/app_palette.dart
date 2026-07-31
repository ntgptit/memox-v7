import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_colors.dart';

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
  AppColors.primaryContainerLight,
  AppColors.onPrimaryContainerLight,
  AppColors.secondaryLight,
  AppColors.onSecondaryLight,
  AppColors.secondaryContainerLight,
  AppColors.onSecondaryContainerLight,
  AppColors.tertiaryLight,
  AppColors.onTertiaryLight,
  AppColors.tertiaryContainerLight,
  AppColors.onTertiaryContainerLight,
  AppColors.onErrorLight,
  AppColors.errorContainerLight,
  AppColors.onErrorContainerLight,
  AppColors.surfaceContainerLowestLight,
  AppColors.surfaceContainerLowLight,
  AppColors.surfaceContainerLight,
  AppColors.surfaceContainerHighLight,
  AppColors.surfaceContainerHighestLight,
  AppColors.surfaceDimLight,
  AppColors.surfaceBrightLight,
  AppColors.inverseSurfaceLight,
  AppColors.onInverseSurfaceLight,
  AppColors.inversePrimaryLight,
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
  AppColors.primaryContainerDark,
  AppColors.onPrimaryContainerDark,
  AppColors.secondaryDark,
  AppColors.onSecondaryDark,
  AppColors.secondaryContainerDark,
  AppColors.onSecondaryContainerDark,
  AppColors.tertiaryDark,
  AppColors.onTertiaryDark,
  AppColors.tertiaryContainerDark,
  AppColors.onTertiaryContainerDark,
  AppColors.onErrorDark,
  AppColors.errorContainerDark,
  AppColors.onErrorContainerDark,
  AppColors.surfaceContainerLowestDark,
  AppColors.surfaceContainerLowDark,
  AppColors.surfaceContainerDark,
  AppColors.surfaceContainerHighDark,
  AppColors.surfaceContainerHighestDark,
  AppColors.surfaceDimDark,
  AppColors.surfaceBrightDark,
  AppColors.inverseSurfaceDark,
  AppColors.onInverseSurfaceDark,
  AppColors.inversePrimaryDark,
  AppColors.shadowDark,
  AppColors.scrimDark,
  // The `*Fixed` family is the same in both schemes, so the dark scheme
  // legitimately carries these light tokens.
  AppColors.primaryContainerLight,
  AppColors.onPrimaryContainerLight,
  AppColors.primaryLight,
  AppColors.secondaryContainerLight,
  AppColors.onSecondaryContainerLight,
  AppColors.secondaryLight,
  AppColors.tertiaryContainerLight,
  AppColors.onTertiaryContainerLight,
  AppColors.tertiaryLight,
];
