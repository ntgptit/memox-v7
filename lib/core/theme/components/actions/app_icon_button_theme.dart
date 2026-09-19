import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_sizing.dart';
import '../../states/app_interaction_states.dart';

/// `MxIconButton`, and every bare `IconButton` under it.
///
/// One of the four component themes added at M4.8, each because a shared
/// component had started rendering through it.
IconButtonThemeData buildIconButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => IconButtonThemeData(
  style:
      IconButton.styleFrom(
        // **36 drawn, 48 hit** (MemoX v3 IconButton component spec, Actions &
        // controls, 2026-09-18). `minimumSize` states the painted ink circle,
        // not the touch floor — `tapTargetSize: padded` below restores
        // `AppSizing.touchTarget` around it, so no screen can pass a smaller
        // hit area even though the circle itself is smaller than the target
        // it keeps.
        minimumSize: const Size.square(AppSizing.iconButtonInk),
        tapTargetSize: MaterialTapTargetSize.padded,
        // v3's `onSurface` (M100.101). A straight gain: the glyph reads
        // **16.72:1** on the page in light and **15.59:1** in dark, where
        // `onSurfaceVariant` read 7.20 and 8.50.
        foregroundColor: scheme.onSurface,
        // Named, not left to `defaultStyleOf` where no audit can see it.
        disabledForegroundColor: semantic.onDisabled,
        // Fully round, matching the outlined variant's shape token — the
        // squircle `AppRadius.md` used to draw here read as a rounded box
        // beside the outlined style's true circle.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ).copyWith(
        // Hover, press and focus declared. Left null they came from
        // Material, which is neither the kit nor what every other control
        // in this app resolves.
        overlayColor: AppInteractionStates.iconOverlay(scheme),
        // Focus draws a ring, not just the tint: measured off the goldens
        // that tint alone is 1.15:1 against the surface behind it in both
        // modes, where WCAG 1.4.11 asks 3:1 of a focus indicator.
        side: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.focused)) return null;
          return AppInteractionStates.focusIndicator(scheme);
        }),
      ),
);

/// The outlined icon button: the same control, wearing an edge.
///
/// **A style built from resolvers, not from `styleFrom`, and that is a rule
/// this file already learned.** `MxIconButton` carried an `isFilled` flag once,
/// spelled `IconButton.styleFrom(backgroundColor:)`; a flat
/// `WidgetStatePropertyAll` shadows the theme's property for every state at
/// once, so the button stayed fully armed when disabled and never darkened on
/// press. The note left behind said that if a bar ever leads with a coloured
/// icon action again, its colours come from the shared resolvers. This does.
///
/// **Three slots differ from the plain style and no more.** A resting border, a
/// surface behind it, and a pill shape; ink, overlay, target and disabled
/// handling all stay the theme's, because the outline is a shape decision and
/// not a new kind of control.
///
/// **The width is `BorderSide`'s own default and is stated nowhere here**, on
/// the precedent of the outlined button theme and the popup menu — both write
/// `BorderSide(color:)` and let the default stand. It coincides with
/// `AppStroke.hairline`, and `app_icon_button_outlined_test.dart` pins that
/// coincidence: if the token ever moves off 1, that test goes red instead of
/// this border quietly staying behind.
///
/// **The focus ring still wins the `side` slot.** Focused, the border is the
/// focus indicator — WCAG 1.4.11 asks 3:1 of an indicator and the resting
/// hairline is `outline`, which is not built to carry that. Unfocused, the
/// hairline. One slot, two jobs, resolved in the order that keeps the
/// accessible one visible.
ButtonStyle buildOutlinedIconButtonStyle(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => ButtonStyle(
  // **40 drawn, 48 hit** (owner brief, 2026-09-10) — the plain style's own
  // circle is a different, smaller 36 (`AppSizing.iconButtonInk`, MemoX v3
  // IconButton component spec, 2026-09-18); the two are separate
  // component-owned values for two different visuals, not one number reused.
  // An outlined circle is visible, and at 48 beside a 12px subtitle it is the
  // largest object in the header. `padded` keeps the finger's floor while the
  // circle comes down — the same split `MxActionButtonSize.compact` has used
  // since 2026-08-20.
  minimumSize: const WidgetStatePropertyAll<Size>(
    Size.square(AppSizing.controlCompact),
  ),
  tapTargetSize: MaterialTapTargetSize.padded,
  backgroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.disabledSurface;

    return scheme.surface;
  }),
  side: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.focused)) {
      return AppInteractionStates.focusIndicator(scheme);
    }
    if (states.contains(WidgetState.disabled)) {
      return BorderSide(color: semantic.onDisabled);
    }

    return BorderSide(color: scheme.outline);
  }),
  // A circle, because an edge makes the shape readable and the app's
  // `AppRadius.md` squircle then reads as a rounded box beside a round one.
  // `pill` is the existing token for "as round as this box gets" — the same one
  // the progress track clips with — so this adds no radius value.
  shape: WidgetStateProperty.all(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
  ),
);
