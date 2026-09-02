import 'package:flutter/material.dart';

import 'app_interaction_states.dart';
import 'app_semantic_colors.dart';

/// The radio, as the deck form's scheduler picker renders it through
/// `RadioListTile`.
///
/// Declared the moment it gained a renderer — before this, the picker took
/// Material's defaults: a fill derived from the seed rather than the palette,
/// and hover/press/focus washes from `ThemeData`'s unseeded fallbacks. A
/// missing decision looks the same as a made one until someone measures it,
/// which is the drift `AppStateOpacity` exists to close.
///
/// The kit has no radio — no mock renders a scheduler picker — so there is no
/// CSS to transcribe from. The values are the app's own conventions instead:
/// the resting ring is the secondary ink like every other quiet glyph, and the
/// overlay is the shared control wash. Recorded as a Flutter-only gap in
/// `docs/reviews/design-parity-checklist.md`.
///
/// **The selected mark is `primary`**, which is what M3 gives a radio and what
/// the role can now carry: a mark is a glyph on a bare surface, and the old
/// dark fill tone reached only 2.90:1 against the card — under the 3:1 WCAG
/// 1.4.11 asks of a control's visual information. That shortfall is what put a
/// separate ink here until M100.18 inverted the tone; it now measures 10.02:1.
RadioThemeData buildRadioTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => RadioThemeData(
  fillColor: WidgetStateProperty.resolveWith((states) {
    // The mark is a glyph, so disabled takes the translucent content token
    // — the same 38% every disabled label and icon wears — not the solid
    // `disabledSurface`, which is a fill for things that have a face.
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
    if (states.contains(WidgetState.selected)) return scheme.primary;

    return scheme.onSurfaceVariant;
  }),
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);
