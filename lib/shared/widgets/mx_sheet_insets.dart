import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';

/// Whatever is covering the bottom of a bottom sheet: the keyboard, or the
/// system bar when the keyboard is down.
///
/// **`max`, not a sum, and not `viewInsets` alone.** `viewInsets` covers only
/// the keyboard; with the keyboard down it is zero, and on an edge-to-edge
/// Android target — which this app is, unavoidably, from API 35 — the gesture
/// bar (24dp) or the three-button bar (48dp) is painted over the sheet.
/// Measured on the tag filter sheet before this existed: the primary action
/// ended 14dp above the bottom of an 852dp surface, entirely underneath the
/// inset. And `max` rather than a sum, because when the keyboard *is* up it
/// already covers the system bar; adding both pushes the actions a bar's height
/// above the keyboard.
///
/// **Public, and in its own file, because the third copy was written wrong.**
/// `showMxFormSheet` had this; `card_export_sheet_widget` wrote a `SafeArea`
/// plus `viewInsets` version that reaches the same answer a different way; and
/// `starter_install_widget` wrote `viewInsets` **without** the `SafeArea` — a
/// sheet with no text field, so the term is always zero and its actions sat
/// under the navigation bar on every device with one. Three call sites, three
/// spellings, one of them silently broken on the platform the app ships to.
double mxSheetBottomObstruction(BuildContext context) {
  final MediaQueryData media = MediaQuery.of(context);

  return media.viewInsets.bottom > media.viewPadding.bottom
      ? media.viewInsets.bottom
      : media.viewPadding.bottom;
}

/// A bottom sheet's content, inset from all four edges and clear of whatever is
/// covering the bottom.
///
/// The common shape: one gutter all round, plus [mxSheetBottomObstruction] at
/// the bottom. A sheet whose padding is not this — the export sheet has no top
/// gutter because its drag handle already provides one — composes the function
/// directly instead of taking a flag here. A parameter that changes which edges
/// are padded is a second layout, and the design-system rule is that a second
/// layout is a second widget rather than a boolean.
///
/// **No `SafeArea`.** It would be a second answer to the same question: the
/// bottom obstruction already accounts for `viewPadding`, and wrapping this in
/// a `SafeArea` insets the system bar twice, leaving a visible dead band under
/// the actions.
class MxSheetInsets extends StatelessWidget {
  const MxSheetInsets({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + mxSheetBottomObstruction(context),
      ),
      child: child,
    );
  }
}
