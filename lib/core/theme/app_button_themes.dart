import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';

/// The filled and outlined button themes, and the geometry both share.
///
/// Split out of `app_theme.dart` when that file crossed the 400-line guard. They
/// are the natural seam: everything here is one component family, it is the
/// longest block in the theme because both buttons declare every interaction
/// state by hand, and nothing else in the theme reads it.
///
/// **Both declare disabled, pressed and focused explicitly.** Material supplies
/// defaults, but they are derived from the scheme and drift the moment the scheme
/// changes; naming them is what keeps the states stable.

/// Geometry shared by both buttons.
///
/// 48 high before padding: the minimum touch target, enforced here rather than
/// per component so no button in the app can be built below it.
ButtonStyle buildSharedButtonStyle(ColorScheme scheme) => ButtonStyle(
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

/// The primary action: `MxActionButton`'s `primary` and `destructive` variants.
FilledButtonThemeData buildFilledButtonTheme(
  ColorScheme scheme, {
  required Color actionFill,
  required Color actionLabel,
}) => FilledButtonThemeData(
  style: buildSharedButtonStyle(scheme).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.pressed)) {
        return Color.lerp(actionFill, scheme.onSurface, 0.12);
      }

      return actionFill;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: 0.38);
      }

      return actionLabel;
    }),
  ),
);

/// The secondary action: `MxActionButton`'s `secondary` variant.
OutlinedButtonThemeData buildOutlinedButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color outlineLabel,
}) => OutlinedButtonThemeData(
  style: buildSharedButtonStyle(scheme).copyWith(
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: 0.38);
      }

      return outlineLabel;
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
);
