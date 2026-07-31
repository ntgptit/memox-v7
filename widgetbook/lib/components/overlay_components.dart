import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/theme_context_extension.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/catalog_page.dart';

void _noop() {}

/// Both overlay components render inline rather than through `showDialog` /
/// `showModalBottomSheet`: a popped route builds outside the use-case subtree,
/// where the theme and viewport addons cannot reach it.
WidgetbookComponent confirmDialogComponent() {
  return WidgetbookComponent(
    name: 'MxConfirmDialog',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'Delete deck?',
          );
          final message = context.knobs.string(
            label: 'message',
            initialValue:
                'This deletes 4 sub-decks and 11 cards. It cannot be undone.',
            maxLines: 3,
          );
          final confirmLabel = context.knobs.string(
            label: 'confirmLabel',
            initialValue: 'Delete',
          );
          final cancelLabel = context.knobs.string(
            label: 'cancelLabel',
            initialValue: 'Cancel',
          );
          final variant = context.knobs.object.dropdown<MxConfirmDialogVariant>(
            label: 'variant',
            options: MxConfirmDialogVariant.values,
            initialOption: MxConfirmDialogVariant.destructive,
            labelBuilder: (MxConfirmDialogVariant value) => value.name,
          );
          final isSubmitting = context.knobs.boolean(label: 'isSubmitting');

          return CatalogCenterPage(
            child: MxConfirmDialog(
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
              onConfirm: _noop,
              onCancel: _noop,
              variant: variant,
              isSubmitting: isSubmitting,
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent actionSheetComponent() {
  return WidgetbookComponent(
    name: 'MxActionSheet',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final title = context.knobs.stringOrNull(
            label: 'title',
            initialValue: 'Deck actions',
          );
          final isMoveEnabled = context.knobs.boolean(
            label: 'second row enabled',
          );

          return CatalogCenterPage(
            child: _SheetSurface(
              child: MxActionSheet(
                title: title,
                actions: <MxActionSheetAction>[
                  const MxActionSheetAction(
                    label: 'Rename',
                    onPressed: _noop,
                    icon: Icons.edit_outlined,
                  ),
                  MxActionSheetAction(
                    label: 'Move',
                    onPressed: _noop,
                    icon: Icons.drive_file_move_outlined,
                    isEnabled: isMoveEnabled,
                  ),
                  const MxActionSheetAction(
                    label: 'Delete',
                    onPressed: _noop,
                    icon: Icons.delete_outline,
                    variant: MxActionSheetActionVariant.destructive,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

/// The surface `showModalBottomSheet` would normally paint under a sheet.
///
/// `MxActionSheet` deliberately paints no background of its own. A `Material`,
/// not a `DecoratedBox`: the sheet's rows are `ListTile`s, which paint their
/// splashes on the nearest Material ancestor.
class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: context.semanticColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
