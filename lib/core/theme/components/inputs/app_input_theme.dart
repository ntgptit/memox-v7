import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_spacing.dart';
import '../../foundations/app_stroke.dart';

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
/// and moving the hue to `scheme.primary` is the difference between a field
/// answering and a field shouting. (`focusRing` was the token that stood there
/// until M100.19 retired it; the role carries the job now.)
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
  // **`borderControl`, not `borderSubtle`.** An empty field with a placeholder
  // and nothing else is identified by its edge alone, which is exactly the
  // information WCAG 1.4.11 asks 3:1 of; the hairline measured 1.38:1 in light.
  // A card's edge stays subtle because a card is identified by its content.
  border: _inputBorder(scheme.outline),
  enabledBorder: _inputBorder(scheme.outline),
  focusedBorder: _inputBorder(scheme.primary),
  errorBorder: _inputBorder(scheme.error),
  focusedErrorBorder: _inputBorder(scheme.error),
  // Solid, per MX-VIS-002 rule R7. Blended here rather than read from
  // `disabledSurface`: this is the *hairline* faded, that is the *ink*.
  disabledBorder: _inputBorder(
    Color.alphaBlend(scheme.outline.withValues(alpha: 0.5), scheme.surface),
  ),
  hintStyle: texts.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
);

/// Same geometry and the same stroke in every state — only the colour speaks.
OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(AppRadius.md),
  borderSide: BorderSide(color: color, width: AppStroke.input),
);
