import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 themes for the app.
///
/// Only the components UC-05 actually renders are themed: AppBar, Card,
/// FilledButton, OutlinedButton and SnackBar. Theming a Dialog or a Chip now
/// would be a decision made without a screen to check it against, and it would
/// still need revisiting when one exists.
ThemeData buildLightTheme() => _buildTheme(
  ColorScheme.fromSeed(seedColor: AppColors.seed),
  const AppSemanticColors.light(),
);

ThemeData buildDarkTheme() => _buildTheme(
  ColorScheme.fromSeed(seedColor: AppColors.seed, brightness: Brightness.dark),
  const AppSemanticColors.dark(),
);

ThemeData _buildTheme(ColorScheme scheme, AppSemanticColors semantic) {
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    // Anything that builds its own TextStyle without going through the text
    // theme still lands on the body face rather than the platform default.
    fontFamily: AppTypography.bodyFamily,
  );

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: AppTypography.buildTextTheme(base.textTheme),
    extensions: <ThemeExtension<Object?>>[semantic],

    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      // No tint on scroll: during a review the header must stay still, because
      // a colour shift behind the card reads as the card itself changing.
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: semantic.borderSubtle),
      ),
    ),

    // Both button themes declare disabled, pressed and focused explicitly.
    // Material supplies defaults, but they are derived from the scheme and
    // drift once the scheme changes; naming them keeps the states stable.
    filledButtonTheme: FilledButtonThemeData(
      style: _buttonStyle(scheme).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return scheme.primary.withValues(alpha: 0.88);
          }

          return scheme.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }

          return scheme.onPrimary;
        }),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _buttonStyle(scheme).copyWith(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }

          return scheme.primary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: scheme.onSurface.withValues(alpha: 0.12));
          }
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: scheme.primary, width: 2);
          }

          return BorderSide(color: semantic.borderSubtle);
        }),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );
}

ButtonStyle _buttonStyle(ColorScheme scheme) => ButtonStyle(
  // 48 high before padding: the minimum touch target, enforced here rather
  // than per component so no button can be built below it.
  minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 48)),
  padding: const WidgetStatePropertyAll<EdgeInsets>(
    EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
  ),
  shape: WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  ),
  overlayColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) {
      return scheme.primary.withValues(alpha: 0.12);
    }
    if (states.contains(WidgetState.focused)) {
      return scheme.primary.withValues(alpha: 0.10);
    }

    return null;
  }),
);
