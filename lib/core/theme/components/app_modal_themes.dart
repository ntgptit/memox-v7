import 'package:flutter/material.dart';

import '../foundations/app_elevation.dart';
import '../foundations/app_radius.dart';
import '../states/app_interaction_states.dart';
import 'app_overlay_themes.dart';

/// The three surfaces that appear **over** the page and then go away: the
/// dialog, the modal bottom sheet and the snack bar.
///
/// One family by behaviour rather than by widget class. Each has a barrier
/// or a float; each has to answer "does this mode paint a shadow?", and all
/// three answer it through `overlayElevationFor` or a stated `elevation: 0`
/// rather than by leaving the slot silent; two of them share
/// `modalBarrierColor`. Dialog and BottomSheet were two of the four
/// component themes added at M4.8, SnackBar came with UC-05.
///
/// `timePickerTheme` and `popupMenuTheme` are overlays too and live in
/// `app_overlay_themes.dart` beside the non-modal chrome. That seam is
/// history rather than taxonomy — they were split out earlier — and moving
/// them now would be churn in a pass whose whole claim is that no pixel
/// moved.
DialogThemeData buildDialogTheme(ColorScheme scheme, TextTheme texts) =>
    DialogThemeData(
      barrierColor: modalBarrierColor(scheme),
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      // Zero, and the shadow is hand-painted instead: a Material elevation on
      // top of `shadowsFor` is a second depth mechanism, which AD-14 does not
      // admit. See F15. The FAB and the SnackBar are the two that keep a dp
      // value, because their slots have nowhere to put a painted shadow.
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      titleTextStyle: texts.titleMedium?.copyWith(color: scheme.onSurface),
      contentTextStyle: texts.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      // **`actionsPadding` deliberately stays unset here** — it moved to
      // `MxDialogMetrics` while this was in flight (#348). The footer's width
      // has to be *computed* from that inset, so the dialog states it on the
      // widget; a theme entry saying the same 24 would be a second answer that
      // all three dialogs override, and the one that could silently drift out
      // of step with the arithmetic that reads it.
    );

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

/// The snack bar — `MxMessenger` and `MxUndoSnackBar`.
SnackBarThemeData buildSnackBarTheme(ColorScheme scheme, TextTheme texts) =>
    SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: texts.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      // The SDK's own default, restated so the action's colour is a decision
      // on record rather than a silence that resolves to one.
      actionTextColor: scheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      // The last overlay that let Material decide its depth: Dialog,
      // BottomSheet, PopupMenu and the FAB all state theirs, and this slot's
      // silence resolved to the SDK's 6.0 — in dark too, where every other
      // surface has measurably opted out of shadows. Same brightness split as
      // the FAB, for the same reason (theme-composition review, 2026-08).
      elevation: overlayElevationFor(scheme),
    );
