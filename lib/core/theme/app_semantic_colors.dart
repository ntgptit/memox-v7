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
    required this.borderSubtle,
  });

  const AppSemanticColors.light()
    : success = AppColors.successLight,
      warning = AppColors.warningLight,
      danger = AppColors.dangerLight,
      info = AppColors.infoLight,
      surfaceMuted = AppColors.surfaceMutedLight,
      borderSubtle = AppColors.borderSubtleLight;

  const AppSemanticColors.dark()
    : success = AppColors.successDark,
      warning = AppColors.warningDark,
      danger = AppColors.dangerDark,
      info = AppColors.infoDark,
      surfaceMuted = AppColors.surfaceMutedDark,
      borderSubtle = AppColors.borderSubtleDark;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color surfaceMuted;
  final Color borderSubtle;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? surfaceMuted,
    Color? borderSubtle,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
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
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}
