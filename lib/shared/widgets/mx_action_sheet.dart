import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

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
    this.isEnabled = true,
  });

  /// Already-localized.
  final String label;

  final VoidCallback onPressed;
  final IconData? icon;
  final MxActionSheetActionVariant variant;

  /// `false` greys the row and blocks the callback. The row stays visible on
  /// purpose: hiding an unavailable action makes the menu change shape between
  /// visits, and the user cannot learn where anything is.
  final bool isEnabled;
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
/// keyboard are.
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
              if (title != null) _SheetTitle(title: title!),
              for (final action in actions) _SheetRow(action: action),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});

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
      child: Text(
        title,
        style: context.texts.titleSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
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

    // Disabled wins over destructive: a greyed row that is still red reads as
    // available and dangerous, which is the worst of both.
    final color = !action.isEnabled
        ? Color.alphaBlend(
            context.colors.onSurface.withValues(alpha: _disabledOpacity),
            context.colors.surface,
          )
        : isDestructive
        ? context.semanticColors.danger
        : context.colors.onSurface;

    return ListTile(
      enabled: action.isEnabled,
      onTap: action.isEnabled ? action.onPressed : null,
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
          : Icon(
              action.icon,
              size: AppIconSize.md,
              color: isDestructive || !action.isEnabled
                  ? color
                  : context.colors.onSurfaceVariant,
            ),
      title: Text(
        action.label,
        style: context.texts.bodyLarge?.copyWith(color: color),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Material's own disabled opacity for content on a surface.
const double _disabledOpacity = 0.38;
