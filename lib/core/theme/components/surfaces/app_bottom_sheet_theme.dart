import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../states/app_interaction_states.dart';
import '../overlays/app_backdrop_recipe.dart';

/// The modal sheet — `MxFormSheet`, `MxActionSheet`, and every direct
/// `showModalBottomSheet` call.
BottomSheetThemeData buildBottomSheetTheme(ColorScheme scheme) =>
    BottomSheetThemeData(
      modalBarrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      // **The handle is a button, not a decoration, and the SDK is explicit
      // about it:** `_DragHandle` wraps itself in `Semantics(button: true,
      // onTap: …)` with the dismiss label and pads itself to
      // `kMinInteractiveDimension`. So WCAG 1.4.11's 3:1 applies to it, and
      // `borderSubtle` — the decorative hairline, `outlineVariant` — measured
      // **1.45:1** in light and **2.04:1** in dark. It is the only thing on the
      // sheet that says the sheet can be dragged or dismissed.
      //
      // **`borderControl` rather than `onSurfaceVariant`, and that was decided
      // by looking.** Material's default for this slot is `onSurfaceVariant`,
      // which here measures 6.45 and 7.29 — it clears the floor twice over and
      // renders as a bar heavy enough to take the eye *before* the sheet's own
      // heading. A sheet's first job is to say what it is. `borderControl`
      // reads as an affordance at 3.19 and 3.00 without competing, and it is
      // the token this app already means by "interactive control".
      dragHandleColor: WidgetStateColor.resolveWith((states) {
        // **Two states, because two is all the SDK ever sets here** — it adds
        // `hovered` from its own `MouseRegion` and `dragged` while the sheet is
        // actually moving. No focus and no pressed: the handle has semantics
        // but no `Focus`, so it is not in the traversal.
        //
        // `dragged` is the one that matters on the release platform. Hover does
        // not exist on a phone; the grab does, and until now it looked exactly
        // like the rest.
        //
        // **The role is `onSurfaceVariant` in every state, and the grab is a
        // state layer over it rather than a second role.**
        // `_BottomSheetDefaultsM3.dragHandleColor` is that role and does not
        // vary; the SDK still resolves this slot against states, which is the
        // sanctioned place to put feedback — but feedback is a layer, not a
        // different meaning.
        //
        // It read `outline` until M100.22 (M3's resting answer held back as an
        // emphasis), then `onSurface` under the grab, which M100.23 caught as
        // the same bug class it had just found in four component resolvers —
        // chip, switch, checkbox and segmented button: an interaction state
        // moving a slot off its canonical role. The grab now blends `onSurface`
        // at `AppStateOpacity.pressed` into the role itself — pre-composed
        // against a known ground, because AD-14 §1 forbids paint-time alpha —
        // so the handle firms up without ever claiming to be a different token.
        if (states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.hovered)) {
          return Color.alphaBlend(
            scheme.onSurface.withValues(alpha: AppStateOpacity.pressed),
            scheme.onSurfaceVariant,
          );
        }

        return scheme.onSurfaceVariant;
      }),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    );
