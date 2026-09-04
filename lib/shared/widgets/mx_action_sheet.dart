import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/extensions/app_ink.dart';
import 'mx_icon.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_focus_ring.dart';
import 'mx_sheet.dart';

/// Whether an action in a sheet destroys something.
enum MxActionSheetActionVariant {
  normal,

  /// Deletes or discards. Carried by the enum so the sheet can style **and**
  /// announce it; colour alone would say nothing to a screen reader and nothing
  /// to a colour-blind user.
  destructive,
}

/// One row of an [MxActionSheet].
@immutable
class MxActionSheetAction {
  const MxActionSheetAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = MxActionSheetActionVariant.normal,
    this.isSelected = false,
  });

  /// Already-localized.
  final String label;

  final VoidCallback onPressed;
  final IconData? icon;
  final MxActionSheetActionVariant variant;

  /// Whether this row is the state the app is already in.
  ///
  /// **For a sheet that chooses rather than acts.** A list of sort orders is
  /// still a list of actions — each one does something — but one of them is
  /// where the user already is, and a sheet that does not say which turns
  /// "change the order" into "guess the order". It draws a trailing check and
  /// announces itself as selected, so the fact does not live in the tick alone.
  ///
  /// Off by default: an action sheet that performs things has no current state
  /// to mark, and every existing caller is one of those.
  final bool isSelected;
}

/// The mobile action menu.
///
/// **It decides nothing.** Which actions exist, whether *Create card* belongs
/// beside *Create deck*, whether either is available for this `content_type` —
/// all of that is the feature's, and arrives as a list. A sheet that knew about
/// content types would have to know about schedulers next, and then about
/// permissions.
///
/// Content is scrollable and inside a `SafeArea`: a sheet is anchored to the
/// bottom of the screen, which is exactly where the home indicator and the
/// keyboard are. The title is an `MxSheetHeader`, announced as a heading
/// (A20.1 P1-01); the rows carry the app's row overlay and its focus ring
/// (A20.1 P2-04), so a keyboard user sees which action has focus.
///
/// **It paints no surface of its own.** Background, radius, drag handle and
/// elevation come from `bottomSheetTheme`, which means this is the child of a
/// `showModalBottomSheet` call and not a standalone panel. Rendered anywhere
/// else it draws rows straight onto whatever is behind it. Dismissal belongs to
/// the caller that opened the route, for the same reason `MxConfirmDialog` does
/// not close itself: the sheet does not know whether the action it just fired
/// succeeded.
class MxActionSheet extends StatelessWidget {
  const MxActionSheet({required this.actions, this.title, super.key});

  /// Already-localized.
  final String? title;

  final List<MxActionSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (title != null) MxSheetHeader(title: title!),
              for (final action in actions) _SheetRow(action: action),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.action});

  final MxActionSheetAction action;

  @override
  Widget build(BuildContext context) {
    final isDestructive =
        action.variant == MxActionSheetActionVariant.destructive;

    // **The row names its ink rather than picking a colour** (M100.4). Both
    // values were already `AppInk` members under the names the rest of the
    // app uses them by; going through the enum is what stops the next colour
    // here from being chosen instead of named. (A disabled row left with
    // `isEnabled` — A20.1 P3-11 — no production sheet ever showed one.)
    final AppInk ink = isDestructive ? AppInk.danger : AppInk.stated;

    // **The row overlay and the ring, the same as every other row** (A20.1
    // P2-04). This was the one `ListTile` in `lib/shared/` outside the row
    // family: it took Material's defaults for hover/focus/splash and drew no
    // focus indicator at all on a keyboard-focusable row.
    final overlay = AppInteractionStates.rowOverlay(context.colors);

    return MxFocusRing(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ListTile(
        hoverColor: overlay.resolve(const <WidgetState>{WidgetState.hovered}),
        focusColor: overlay.resolve(const <WidgetState>{WidgetState.focused}),
        splashColor: overlay.resolve(const <WidgetState>{WidgetState.pressed}),
        // **The row carries the state, not just the tick.** `selected: true`
        // alone would repaint the row and tell a screen reader nothing; the
        // explicit flag is what makes "Recently studied, selected" the
        // announcement rather than "Recently studied".
        selected: action.isSelected,
        onTap: action.onPressed,
        leading: action.icon == null
            ? null
            // **Not `color`.** The label and the glyph were both `onSurface`, so a
            // row's icon carried the same weight as the words next to it and the
            // eye had two things to land on. `listTileTheme.iconColor` is
            // `onSurfaceVariant` for exactly this reason; passing `color` here
            // overrode the theme's own answer with a copy of the label's.
            //
            // Destructive keeps the full colour: there the glyph is part of the
            // warning, and quieting it would leave red text beside a neutral bin.
            : MxIcon(action.icon!, ink: isDestructive ? ink : AppInk.quiet),
        title: Text(
          action.label,
          style: context.texts.bodyLarge!.inked(context, ink),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Brand ink, and only here: the check is the one thing in the sheet
        // saying "you are here", so it is the one thing allowed to be the accent.
        // `primary`, and this is one of the marks that used to need a second
        // token: a sheet sits on `surface`, where the old fill tone measured
        // 2.90:1 — under the 3:1 WCAG 1.4.11 asks of a graphic carrying state.
        // Tone 80 reads 10.02:1 there (M100.18).
        trailing: action.isSelected
            ? const MxIcon(Icons.check, ink: AppInk.accent)
            : null,
      ),
    );
  }
}
