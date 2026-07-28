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
  ColorScheme.fromSeed(seedColor: AppColors.seed).copyWith(
    // Surfaces and text are declared, not derived. `fromSeed` tints every
    // neutral with the seed, and that lavender cast over the whole app is what
    // made the previous palette read as dated. The seed still drives primary,
    // secondary and the rest of the tonal ramp.
    surface: AppColors.surfaceLight,
    surfaceContainerHighest: AppColors.surfaceMutedLight,
    onSurface: AppColors.onSurfaceLight,
    onSurfaceVariant: AppColors.onSurfaceVariantLight,
    outline: AppColors.borderSubtleLight,
    outlineVariant: AppColors.borderSubtleLight,
  ),
  const AppSemanticColors.light(),
  background: AppColors.backgroundLight,
);

ThemeData buildDarkTheme() => _buildTheme(
  ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.dark,
  ).copyWith(
    surface: AppColors.surfaceDark,
    surfaceContainerHighest: AppColors.surfaceMutedDark,
    onSurface: AppColors.onSurfaceDark,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    outline: AppColors.borderSubtleDark,
    outlineVariant: AppColors.borderSubtleDark,
  ),
  const AppSemanticColors.dark(),
  background: AppColors.backgroundDark,
);

ThemeData _buildTheme(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color background,
}) {
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    // Anything that builds its own TextStyle without going through the text
    // theme still lands on the body face rather than the platform default.
    fontFamily: AppTypography.bodyFamily,
  );

  return base.copyWith(
    // The page sits a step below the card, so a card reads as a card without
    // needing a shadow to say so.
    scaffoldBackgroundColor: background,
    textTheme: AppTypography.buildTextTheme(base.textTheme),
    extensions: <ThemeExtension<Object?>>[semantic],

    appBarTheme: AppBarTheme(
      backgroundColor: background,
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

    // Focus changes the border's COLOUR, not its weight. Material's default
    // goes 1px -> 2px on focus, which makes the field jump and nudges anything
    // laid out beside it; keeping the stroke at 1.5 in every state and moving
    // the hue to `focusRing` is the difference between a field answering and a
    // field shouting.
    inputDecorationTheme: InputDecorationTheme(
      // Outlined, not filled. A fill makes the field a block that competes with
      // the cards around it; the reference defines the field with a stroke
      // alone and lets the page show through, so the field reads as an opening
      // rather than an object. `filled: false` means it sits correctly on
      // whatever surface it lands on — page or card — with no per-screen
      // override.
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: _inputBorder(semantic.borderSubtle),
      enabledBorder: _inputBorder(semantic.borderSubtle),
      focusedBorder: _inputBorder(semantic.focusRing),
      errorBorder: _inputBorder(semantic.danger),
      focusedErrorBorder: _inputBorder(semantic.danger),
      disabledBorder: _inputBorder(
        semantic.borderSubtle.withValues(alpha: 0.5),
      ),
      hintStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
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

/// Same geometry and the same 1.5 stroke in every state — only the colour
/// carries the meaning.
OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.md),
  borderSide: BorderSide(color: color, width: 1.5),
);

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
