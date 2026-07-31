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

/// A disabled control's fill and border, resolved to a solid colour.
///
/// **Precomputed rather than translucent, per MX-VIS-002 rule R7.** Material's
/// idiom is `onSurface` at 12% alpha, and as a `BorderSide` or a fill that
/// composites against whatever happens to be behind the button at paint time —
/// a card, a sheet, a dialog — so one token renders as three values and none of
/// them was chosen. Blending over [scheme.surface] here fixes the ground.
///
/// **Blended over `surface`, and that is a choice with a cost.** Precomputing
/// forces one ground where translucency had none, so the value is now right in
/// the place these states actually occur — a disabled submit inside a form sheet,
/// a disabled action inside a dialog — and slightly light where a disabled button
/// sits straight on the page. Measured, light: `#E3E3E6` over the card against
/// `#D9DADF` over the page.
///
/// That gap is the finding, not a side effect of fixing it. One token was
/// rendering as two colours depending on what happened to be behind it, and
/// nobody had chosen either. Four goldens moved when this landed, which is how
/// the gap became visible at all.
Color disabledSurfaceTint(ColorScheme scheme) =>
    Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.12), scheme.surface);

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
        return disabledSurfaceTint(scheme);
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
        return BorderSide(color: disabledSurfaceTint(scheme));
      }
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: scheme.primary, width: 2);
      }

      return BorderSide(color: semantic.borderSubtle);
    }),
  ),
);
