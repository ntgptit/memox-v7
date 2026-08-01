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
/// sits straight on the page. Measured, light: `#E0E0E5` over the card against
/// `#D9DADF` over the page. (The kit's `--color-disabled-surface` reads `#E3E3E6`,
/// four units away; `IMPORT_LEDGER.md` records why the derivation wins.)
///
/// That gap is the finding, not a side effect of fixing it. One token was
/// rendering as two colours depending on what happened to be behind it, and
/// nobody had chosen either. Four goldens moved when this landed, which is how
/// the gap became visible at all.
///
/// [over] names the ground when it is not the page's `surface`. A selected pill
/// that goes disabled sits on `secondaryContainer`, not on `surface`, so
/// blending the same 12% over `surface` there would erase the selection rather
/// than dim it. The tint is the constant; the ground is per state.
Color disabledSurfaceTint(ColorScheme scheme, {Color? over}) =>
    Color.alphaBlend(
      scheme.onSurface.withValues(alpha: kDisabledTintAlpha),
      over ?? scheme.surface,
    );

/// Material's disabled-surface alpha, named because three component themes now
/// blend with it and a fourth copying the literal is how they drift apart.
const double kDisabledTintAlpha = 0.12;

/// Material's disabled-foreground alpha — `--color-on-disabled` in
/// `design_system/tokens/colors.css`, which states it at 0.38 in both modes.
///
/// **Alpha here is correct and is not a rule R7 violation.** A label's ground is
/// always the surface it is printed on, so nothing is left unresolved; R7 is
/// about fills and borders, whose ground is whatever happens to be behind them.
const double kDisabledForegroundAlpha = 0.38;

/// How much of the accent a control takes on while it is pressed, focused or
/// hovered.
///
/// Named because the pill reuses them. A `ChipThemeData` cannot express feedback
/// as an overlay — declaring its state-aware `color` makes Material set the
/// InkWell's `hoverColor` to transparent — so the pill blends these into its
/// fill instead. Same three numbers either way, so a pill and a button answer a
/// pointer by the same amount.
const double kPressedOverlayAlpha = 0.12;
const double kFocusedOverlayAlpha = 0.10;
const double kHoveredOverlayAlpha = 0.06;

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
      return scheme.primary.withValues(alpha: kPressedOverlayAlpha);
    }
    if (states.contains(WidgetState.focused)) {
      return scheme.primary.withValues(alpha: kFocusedOverlayAlpha);
    }
    // **Hover used to fall through to `null`**, which handed it to Material's
    // default — a wash of the *foreground* colour, so a filled button hovered
    // toward white and an outlined one toward its own label. 6% of the accent is
    // the design's number and it points the same way in both. Web and desktop
    // only, and Android is the release target (AD-04) — but the web build is the
    // E2E channel, so it shows up in exactly the place this project takes
    // screenshots.
    if (states.contains(WidgetState.hovered)) {
      return scheme.primary.withValues(alpha: kHoveredOverlayAlpha);
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
        return Color.lerp(actionFill, scheme.onSurface, kPressedOverlayAlpha);
      }

      return actionFill;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurface.withValues(alpha: kDisabledForegroundAlpha);
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
        return scheme.onSurface.withValues(alpha: kDisabledForegroundAlpha);
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
