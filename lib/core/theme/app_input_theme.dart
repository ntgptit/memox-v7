import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_stroke.dart';

/// The text field, as `MxTextField` (and `MxSearchField`'s inner field)
/// renders it.
///
/// Split out of `app_theme.dart` when that file crossed the 400-line guard —
/// the same seam as the buttons, the chip and the overlays: one component
/// family, every state declared by hand, read by nothing else in the theme.
///
/// **Focus changes the border's COLOUR, not its weight.** Material's default
/// goes 1px -> 2px on focus, which makes the field jump and nudges anything
/// laid out beside it; keeping the stroke at [AppStroke.input] in every state
/// and moving the hue to `focusRing` is the difference between a field
/// answering and a field shouting.
InputDecorationTheme buildInputDecorationTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => InputDecorationTheme(
  // Outlined, not filled. A fill makes the field a block that competes with
  // the cards around it; the reference defines the field with a stroke alone
  // and lets the page show through, so the field reads as an opening rather
  // than an object, and sits correctly on page or card with no override.
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
  // Solid, per MX-VIS-002 rule R7. Blended here rather than read from
  // `disabledSurface`: this is the *hairline* faded, that is the *ink*.
  disabledBorder: _inputBorder(
    Color.alphaBlend(
      semantic.borderSubtle.withValues(alpha: 0.5),
      scheme.surface,
    ),
  ),
  hintStyle: texts.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
);

/// Same geometry and the same stroke in every state — only the colour speaks.
OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.md),
  borderSide: BorderSide(color: color, width: AppStroke.input),
);
