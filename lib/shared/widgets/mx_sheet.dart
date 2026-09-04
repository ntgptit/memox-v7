import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_spacing.dart';

/// The one way a bottom sheet opens (A20.1 P1-01).
///
/// **Sixteen `showModalBottomSheet` calls in thirteen files were making five
/// different decisions about the same route** — which navigator, whether the
/// status bar is avoided, how the bottom is inset (`SafeArea` ×7,
/// `useSafeArea:` ×2, `MxSheetInsets` ×2, `mxSheetBottomObstruction` ×1, raw
/// `viewInsets` ×1, nothing ×5), and whether the title is a heading (1 of 17).
/// A sheet is one route with one shape, so the decisions live here and the
/// callers keep only what differs: the content, and what the sheet returns.
///
/// **Root navigator, like the dialogs.** `showModalBottomSheet` defaults
/// `useRootNavigator` to `false` (`bottom_sheet.dart:1301`) where `showDialog`
/// defaults to `true`; a sheet opened inside a navigation-bar branch therefore
/// slid up *under* the bar and the bar's ripple kept working through the
/// scrim. One owner decides once (A20.1 §20).
///
/// **`useSafeArea: true` avoids the status bar, and only that.** The flag
/// insets the top, left and right (`ModalBottomSheetRoute.useSafeArea`); the
/// bottom stays the content's to solve, which `MxSheetInsets` does with the
/// keyboard-or-system-bar rule — so the two never double-inset.
///
/// **`isScrollControlled: true` always.** Without it a sheet is capped at half
/// the screen and a form's submit button sits under the keyboard; with it a
/// `mainAxisSize: min` column still takes only what it needs. There is no
/// caller that wants the cap, so it is not a parameter.
///
/// **The handle, the surface, the radius and the depth are `bottomSheetTheme`'s.**
/// Nothing here paints.
Future<T?> showMxSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: builder,
  );
}

/// A sheet's title, announced as a heading.
///
/// **One of seventeen sheets said `header: true`** before A20.1 P1-01; the
/// other sixteen put a `Text` at the top and a screen reader met it as a
/// sentence like any other. The role is the whole point of the widget: a
/// heading is how a reader knows a new surface has a name, and jumps to it.
///
/// Quiet ink at the small title rung — the sheet's content is the loud thing;
/// the title says what the content is about.
class MxSheetHeader extends StatelessWidget {
  const MxSheetHeader({required this.title, super.key});

  /// Already-localized.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: context.texts.titleSmall!.inked(context, AppInk.quiet),
        ),
      ),
    );
  }
}
