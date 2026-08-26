import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

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
  /// the number on the app's scale, where [footerWidth] can read it and an SDK
  /// bump cannot silently change what the footer is measured against.
  static const double actionsInset = AppSpacing.xl;

  /// The padding a dialog passes to `AlertDialog.insetPadding` so that
  /// [footerWidth] describes the dialog it actually is.
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

  /// The line the action pair actually gets, which is neither the screen nor
  /// the dialog: `screen − 2×inset − 2×actionsInset`. On a 393 screen that is
  /// 265, against the 361 the pair assumed before #348.
  static double footerWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width - inset * 2 - actionsInset * 2;
}
