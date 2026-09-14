import 'package:flutter/material.dart';

import '../../foundations/app_elevation.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_sizing.dart';
import '../../states/app_interaction_states.dart';
import '../overlays/app_backdrop_recipe.dart';

/// The modal sheet — `MxFormSheet`, `MxActionSheet`, and every direct
/// `showModalBottomSheet` call.
///
/// The handoff BottomSheet (M100.93): `surfaceContainerHigh`, top corners 20
/// (D12), a 36 × 4 grabber, and no shadow — `shadow-chrome` would be invisible
/// over a 45% scrim, and this theme has no `BoxShadow` slot (D21).
BottomSheetThemeData buildBottomSheetTheme(ColorScheme scheme) =>
    BottomSheetThemeData(
      modalBarrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.none,
      showDragHandle: true,
      dragHandleSize: const Size(
        AppSizing.sheetHandleWidth,
        AppSizing.sheetHandleHeight,
      ),
      // **The handle is a button, not a decoration, and the SDK is explicit
      // about it:** `_DragHandle` wraps itself in `Semantics(button: true,
      // onTap: …)` with the dismiss label and pads itself to
      // `kMinInteractiveDimension`, so WCAG 1.4.11 asks 3:1 of it.
      //
      // **`outlineVariant`, the kit's grabber, is under that 3:1 on purpose.**
      // It measures 1.30:1 in light and 1.05:1 in dark on
      // `surfaceContainerHigh`. Owner decision 5 keeps a control edge's kit hex
      // even under 3:1 and has the gate pin the measured figure as the floor
      // (`component_depth_and_state_test`). Until M100.93 the handle was
      // `onSurfaceVariant`, the slot's M3 role, chosen at M100.22/23 for its
      // contrast. The barrier and the back gesture dismiss the sheet as well.
      dragHandleColor: WidgetStateColor.resolveWith((states) {
        // **Two states, because two is all the SDK ever sets here** — it adds
        // `hovered` from its own `MouseRegion` and `dragged` while the sheet is
        // actually moving. No focus and no pressed: the handle has semantics
        // but no `Focus`, so it is not in the traversal.
        //
        // `dragged` is the one that matters on the release platform. Hover does
        // not exist on a phone; the grab does.
        //
        // **One role in every state, and the grab is a state layer over it
        // rather than a second role.** An interaction state moving a slot off
        // its role is the bug class M100.23 found in four component resolvers
        // — chip, switch, checkbox and segmented button. The grab blends
        // `onSurface` at `AppStateOpacity.pressed` into the role itself —
        // pre-composed against a known ground, because AD-14 §1 forbids
        // paint-time alpha — so the handle firms up without ever claiming to
        // be a different token.
        if (states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.hovered)) {
          return Color.alphaBlend(
            scheme.onSurface.withValues(alpha: AppStateOpacity.pressed),
            scheme.outlineVariant,
          );
        }

        return scheme.outlineVariant;
      }),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
    );
