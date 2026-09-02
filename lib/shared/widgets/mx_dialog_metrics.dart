import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';

/// The two insets that decide how wide a dialog's footer really is.
///
/// **Stated rather than inherited, and shared rather than restated.** The
/// reasoning is #348's: `MxButtonPair` decides row-or-stack from a width, and
/// left to itself it assumes one page gutter in from the screen — true of a
/// page column, a sheet and an empty state, and wrong for a dialog, which is
/// `insetPadding` in from the screen *and* `actionsPadding` in from its own
/// edge. On a 393 screen the footer is 265 wide while the pair assumed 361, so
/// it laid out a row that could not hold either label and both wrapped. That is
/// invisible to every other gate: the pair is still one size, nothing overflows,
/// and a golden compares the screen with yesterday's copy of itself.
///
/// It lives here rather than on `MxConfirmDialog` because there are now three
/// dialogs — confirm, form and alert — and a number that two of them compute a
/// layout from cannot belong to the third's neighbour. That is the same move
/// #348 made one level down: the defect belonged to `MxButtonPair`, not to the
/// dialog that happened to show it.
abstract final class MxDialogMetrics {
  /// How far a dialog sits in from each edge of the screen — Material's own
  /// `AlertDialog` default.
  ///
  /// Off `AppSpacing.scale` on purpose: the scale stops at 32 and this is a
  /// framework constant, not a design step. Naming it keeps that visible.
  static const double inset = 40;

  /// A dialog's own padding around its action row.
  ///
  /// Material's default is also 24, so stating it moves nothing — but it puts
  /// the number on the app's scale, so an SDK bump cannot silently change how
  /// far a dialog sits in from its own edge.
  static const double actionsInset = AppSpacing.xl;

  /// The padding a dialog passes to `AlertDialog.insetPadding`.
  static const EdgeInsets insetPadding = EdgeInsets.symmetric(
    horizontal: inset,
    vertical: AppSpacing.xl,
  );

  /// The padding a dialog passes to `AlertDialog.actionsPadding`, for the same
  /// reason. No top: the content above already ends on its own gutter.
  static const EdgeInsets actionsPadding = EdgeInsets.fromLTRB(
    actionsInset,
    0,
    actionsInset,
    actionsInset,
  );

  // `footerWidth` used to live here, and it is gone on purpose. It existed so
  // `MxButtonPair` could be told a number it had no way to see; the pair is a
  // render object now and reads the constraint it is handed, which *is* this
  // footer. The two insets above stay — they are what the dialog passes to
  // Material, and stating them keeps an SDK bump from moving the dialog
  // silently — but nothing computes with them any more.
}
