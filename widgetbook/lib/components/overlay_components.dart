import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_alert_dialog.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_dialog_tone.dart';
import 'package:memox/shared/widgets/mx_form_dialog.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
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
          // **Two dropdowns, because there are two axes.** `variant` answers
          // what the confirm button does to the data; `tone` answers how
          // serious the situation is. The pair worth checking here is
          // `cautious` + `info` — a soft action wearing a calm icon — which is
          // what `showStarterAddAgainConfirm` renders, and the combination a
          // single merged enum could not have expressed.
          final tone = context.knobs.objectOrNull.dropdown<MxDialogTone>(
            label: 'tone',
            options: MxDialogTone.values,
            initialOption: MxDialogTone.error,
            defaultToNull: true,
            labelBuilder: (MxDialogTone value) => value.name,
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
              tone: tone,
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

/// The form-in-a-dialog playground.
///
/// The knobs worth turning together are `errorMessage` and `isSubmitting`: a
/// refusal arriving while the previous attempt is still spinning is the state
/// the hand-built version could not reach at all, because it had neither.
WidgetbookComponent formDialogComponent() {
  return WidgetbookComponent(
    name: 'MxFormDialog',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'Add tag',
          );
          final errorMessage = context.knobs.stringOrNull(
            label: 'errorMessage',
            initialValue: 'Tag name is too long.',
          );
          final isSubmitting = context.knobs.boolean(label: 'isSubmitting');
          final tone = context.knobs.objectOrNull.dropdown<MxDialogTone>(
            label: 'tone',
            options: MxDialogTone.values,
            initialOption: MxDialogTone.warning,
            defaultToNull: true,
            labelBuilder: (MxDialogTone value) => value.name,
          );

          return CatalogCenterPage(
            child: MxFormDialog(
              title: title,
              tone: tone,
              errorMessage: errorMessage,
              isSubmitting: isSubmitting,
              confirmLabel: 'Add',
              cancelLabel: 'Cancel',
              onConfirm: _noop,
              onCancel: _noop,
              child: MxTextField(
                controller: TextEditingController(),
                label: 'Tag',
                hintText: 'Add tag',
              ),
            ),
          );
        },
      ),
    ],
  );
}

/// The one-button alert.
///
/// **The only place it is rendered today**: it has no caller in `lib/features/`
/// yet, deliberately (see `MxAlertDialog`'s own doc and `docs/wbs.md` M99.59),
/// so the catalog is where its four tones get looked at before someone picks
/// one for a real message.
WidgetbookComponent alertDialogComponent() {
  return WidgetbookComponent(
    name: 'MxAlertDialog',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final tone = context.knobs.object.dropdown<MxDialogTone>(
            label: 'tone',
            options: MxDialogTone.values,
            initialOption: MxDialogTone.error,
            labelBuilder: (MxDialogTone value) => value.name,
          );

          return CatalogCenterPage(
            child: MxAlertDialog(
              tone: tone,
              title: context.knobs.string(
                label: 'title',
                initialValue: 'Export failed',
              ),
              message: context.knobs.string(
                label: 'message',
                initialValue:
                    'The file could not be written to that folder. Pick '
                    'another and try again.',
                maxLines: 3,
              ),
              dismissLabel: context.knobs.string(
                label: 'dismissLabel',
                initialValue: 'OK',
              ),
              onDismiss: _noop,
            ),
          );
        },
      ),
    ],
  );
}
