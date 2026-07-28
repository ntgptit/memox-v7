import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The meanings `ColorScheme` has no slot for.
///
/// A `ThemeExtension` rather than a set of globals, because these must change
/// with the theme. A global `successColor` is correct in exactly one
/// brightness, and wrong in the other on every screen at once.
@immutable
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.focusRing,
    required this.secondaryAction,
  });

  const AppSemanticColors.light()
    : success = AppColors.successLight,
      warning = AppColors.warningLight,
      danger = AppColors.dangerLight,
      info = AppColors.infoLight,
      surfaceMuted = AppColors.surfaceMutedLight,
      surfaceElevated = AppColors.surfaceElevatedLight,
      borderSubtle = AppColors.borderSubtleLight,
      focusRing = AppColors.focusRingLight,
      secondaryAction = AppColors.secondaryActionLight;

  const AppSemanticColors.dark()
    : success = AppColors.successDark,
      warning = AppColors.warningDark,
      danger = AppColors.dangerDark,
      info = AppColors.infoDark,
      surfaceMuted = AppColors.surfaceMutedDark,
      surfaceElevated = AppColors.surfaceElevatedDark,
      borderSubtle = AppColors.borderSubtleDark,
      focusRing = AppColors.focusRingDark,
      secondaryAction = AppColors.secondaryActionDark;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Inset tile, chip, icon container — a step above the card.
  final Color surfaceMuted;

  /// The most prominent surface. In dark this is the fill of a primary action:
  /// the button is the top of the surface ladder rather than a block of colour,
  /// which leaves every saturated hue free to carry meaning.
  final Color surfaceElevated;

  final Color borderSubtle;

  /// Input border while focused. Focus shifts hue, never stroke width.
  final Color focusRing;

  /// Label of a secondary (outlined) action.
  final Color secondaryAction;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? surfaceMuted,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? focusRing,
    Color? secondaryAction,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      focusRing: focusRing ?? this.focusRing,
      secondaryAction: secondaryAction ?? this.secondaryAction,
    );
  }

  /// Interpolates every field.
  ///
  /// A field left out of `lerp` snaps instead of animating during a theme
  /// change, and the snap is only visible on the one screen that uses it —
  /// which is why the test compares against a full mid-point rather than
  /// spot-checking a colour.
  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;

    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      secondaryAction: Color.lerp(secondaryAction, other.secondaryAction, t)!,
    );
  }
}
