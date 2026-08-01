import 'package:flutter/material.dart';

import 'app_interaction_states.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';

/// The filled, outlined, text-link and destructive button styles, and the
/// geometry the filled and outlined pair share.
///
/// Split out of `app_theme.dart` when that file crossed the 400-line guard. They
/// are the natural seam: everything here is one component family, it is the
/// longest block in the theme because every button declares every interaction
/// state by hand, and nothing else in the theme reads it.
///
/// **They declare disabled, pressed, hovered and focused explicitly.** Material
/// supplies defaults, but they are derived from the scheme and drift the moment
/// the scheme changes; naming them is what keeps the states stable. The values
/// come from [AppStateOpacity], which transcribes them from the kit's `mx.css`.

/// A disabled control's fill and border, resolved to a solid colour over the
/// ground that state actually has.
///
/// Most disabled controls sit on the page or on a card, and for those the answer
/// is already precomputed: `AppSemanticColors.disabledSurface`. This exists for
/// the one that does not — a *selected* pill that goes disabled sits on
/// `secondaryContainer`, so blending the same 12% over `surface` there would
/// erase the selection rather than dim it. The tint is the constant; the ground
/// is per state.
Color disabledSurfaceTint(ColorScheme scheme, {Color? over}) =>
    Color.alphaBlend(
      scheme.onSurface.withValues(alpha: AppStateOpacity.disabledSurfaceBlend),
      over ?? scheme.surface,
    );

/// Geometry shared by every button.
///
/// 48 high before padding: the minimum touch target, enforced here rather than
/// per component so no button in the app can be built below it.
ButtonStyle buildSharedButtonStyle(ColorScheme scheme) => ButtonStyle(
  minimumSize: const WidgetStatePropertyAll<Size>(
    Size(64, AppSpacing.minimumTouchTarget),
  ),
  padding: const WidgetStatePropertyAll<EdgeInsets>(
    EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
  ),
  shape: WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  ),
  // **Hover used to fall through to `null`**, which handed it to Material's
  // default — a wash of the *foreground* colour, so a filled button hovered
  // toward white and an outlined one toward its own label. Web and desktop only,
  // and Android is the release target (AD-04) — but the web build is the E2E
  // channel, so it shows up in exactly the place this project takes screenshots.
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);

/// The primary action: `MxActionButton`'s `primary` variant.
FilledButtonThemeData buildFilledButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color actionFill,
  required Color actionLabel,
}) => FilledButtonThemeData(
  style: buildFilledStyle(
    scheme,
    semantic,
    fill: actionFill,
    label: actionLabel,
  ),
);

/// A filled button's colours, for any fill.
///
/// Public so `MxActionButton`'s destructive variant can be the same button with
/// a different pair rather than a second implementation. It used to reach for
/// `FilledButton.styleFrom(backgroundColor: error)`, and that is a flat
/// `WidgetStatePropertyAll` which **shadows the theme's property entirely** —
/// so a destructive button did not darken on press and, worse, stayed fully red
/// when disabled while its label went to 38%. A button that looks armed and is
/// inert is the failure this whole file exists to prevent.
ButtonStyle buildFilledStyle(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color fill,
  required Color label,
}) => buildSharedButtonStyle(scheme).copyWith(
  backgroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.disabledSurface;
    if (states.contains(WidgetState.pressed)) {
      return Color.lerp(
        fill,
        scheme.onSurface,
        AppStateOpacity.filledPressedBlend,
      );
    }
    // **A blend, where every other control gets an overlay.** The shared
    // `overlayColor` washes 6% of `primary`, and 6% of the accent painted on
    // the accent is the accent — the primary button had no visible hover at
    // all. `.mx-btn--primary:hover` mixes toward the ink instead, and only a
    // colour that is not already the fill can show up on it.
    if (states.contains(WidgetState.hovered)) {
      return Color.lerp(
        fill,
        scheme.onSurface,
        AppStateOpacity.filledHoverBlend,
      );
    }

    return fill;
  }),
  foregroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

    return label;
  }),
);

/// A text link's label colour, resolved per state.
///
/// Public for the same reason as [buildFilledStyle]: `MxTextButton`'s
/// destructive variant is the same link with `danger` as its accent, not a
/// second implementation. Every state is a blend of the accent toward the ink
/// — `.mx-textbtn` is the one control in the kit with no surface to wash, so
/// its states are carried by the text itself. Focus adds no colour: the
/// label's underline is the focus indicator, and it is drawn by `MxTextButton`
/// where the decoration cannot inherit into icon glyphs.
WidgetStateProperty<Color> textLinkForeground(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color accent,
}) => WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
  if (states.contains(WidgetState.pressed)) {
    return Color.lerp(
      accent,
      scheme.onSurface,
      AppStateOpacity.textPressedBlend,
    )!;
  }
  if (states.contains(WidgetState.hovered)) {
    return Color.lerp(
      accent,
      scheme.onSurface,
      AppStateOpacity.textHoverBlend,
    )!;
  }

  return accent;
});

/// The low-emphasis action: `MxTextButton`, a bare label in the flow of the
/// content.
///
/// **No padding, no radius and no hover surface — that is the entire point.**
/// Material's `TextButton` insets its label by 12 and paints a tinted overlay
/// on hover, and a text button with a background is an outlined button with
/// the border turned off. Zero padding keeps the label on the same vertical
/// line as everything else in the column; the overlay is suppressed, and every
/// state lives on the text through [textLinkForeground].
///
/// **The 48 floor is kept as height, not as padding.** `AppSpacing` calls the
/// touch target a floor rather than a step for exactly this case: the label
/// may sit flush, but the thing a finger has to hit may not shrink to the
/// height of a line of text. The width floor is zero rather than Material's
/// 64 — a link that pads itself out re-introduces the misalignment on the
/// trailing side, and `tapTargetSize: padded` gives the finger its horizontal
/// 48 without drawing it.
///
/// **Colour is the accent, not the fill.** `ColorScheme.primary` is held dark
/// enough on dark surfaces that it measures 3.33:1 as bare text and fails AA
/// at label size; `AppSemanticColors.primaryAccent` is the variant that reads
/// as a label.
///
/// This is the design system's definition of a text button, so anything that
/// builds a `TextButton` inherits the link shape — a future `SnackBarAction`
/// included. A caller that genuinely needs Material's padded button declares
/// its own style; none exists today.
TextButtonThemeData buildTextButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) {
  final foreground = textLinkForeground(
    scheme,
    semantic,
    accent: semantic.primaryAccent,
  );

  return TextButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppSpacing.minimumTouchTarget),
      ),
      alignment: AlignmentDirectional.centerStart,
      // No hover surface and no ripple — the states live on the text.
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      foregroundColor: foreground,
      iconColor: foreground,
    ),
  );
}

/// The secondary action: `MxActionButton`'s `secondary` variant.
OutlinedButtonThemeData buildOutlinedButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color outlineLabel,
}) => OutlinedButtonThemeData(
  style: buildSharedButtonStyle(scheme).copyWith(
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

      return outlineLabel;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: semantic.disabledSurface);
      }
      // The ring, at the one stroke every focus indicator in the app uses. It
      // replaces the hairline rather than sitting outside it, so focus costs no
      // layout — an `OutlinedBorder`'s side is painted on the shape, not added
      // to the box.
      if (states.contains(WidgetState.focused)) {
        return AppInteractionStates.focusRing(scheme);
      }

      return BorderSide(color: semantic.borderSubtle);
    }),
  ),
);
