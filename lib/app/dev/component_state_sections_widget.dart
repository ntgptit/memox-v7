import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/theme_context_extension.dart';
import '../../shared/widgets/mx_action_sheet.dart';
import '../../shared/widgets/mx_confirm_dialog.dart';
import '../../shared/widgets/mx_empty_state.dart';
import '../../shared/widgets/mx_error_state.dart';
import '../../shared/widgets/mx_loading_state.dart';
import 'showcase_section_widget.dart';

/// The feedback demos of the component gallery: the three full-screen states
/// (`MxEmptyState`, `MxErrorState`, `MxLoadingState`), the confirm dialog in
/// both variants, and the action sheet — plus a note on the two shared
/// components that have no visual of their own to demo.
class ComponentStateSectionsWidget extends StatelessWidget {
  const ComponentStateSectionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ScreenStatesSection(),
        _ConfirmDialogSection(),
        _ActionSheetSection(),
        _NotDemoedNote(),
      ],
    );
  }
}

/// Height of the frame the full-screen state components are demoed inside.
const double _stateFrameHeight = 220;

void _noop() {}

class _ScreenStatesSection extends StatelessWidget {
  const _ScreenStatesSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShowcaseSectionWidget(
          title: 'MxEmptyState',
          children: <Widget>[
            ShowcaseItemWidget(
              label: 'with action',
              child: SizedBox(
                height: _stateFrameHeight,
                child: MxEmptyState(
                  title: 'All done for today',
                  message: 'Nothing is due. Come back tomorrow.',
                  actionLabel: 'Browse decks',
                  onAction: _noop,
                ),
              ),
            ),
          ],
        ),
        ShowcaseSectionWidget(
          title: 'MxErrorState',
          children: <Widget>[
            ShowcaseItemWidget(
              label: 'with retry',
              child: SizedBox(
                height: _stateFrameHeight,
                child: MxErrorState(
                  title: 'Something went wrong',
                  message: 'Could not load this demo content.',
                  retryLabel: 'Try again',
                  onRetry: _noop,
                ),
              ),
            ),
          ],
        ),
        ShowcaseSectionWidget(
          title: 'MxLoadingState',
          children: <Widget>[
            ShowcaseItemWidget(
              label: 'indeterminate',
              child: SizedBox(
                height: _stateFrameHeight,
                child: MxLoadingState(semanticsLabel: 'Loading (demo)'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfirmDialogSection extends StatelessWidget {
  const _ConfirmDialogSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'MxConfirmDialog',
      children: <Widget>[
        ShowcaseItemWidget(
          label: 'normal',
          child: MxConfirmDialog(
            title: 'Rename deck?',
            message: 'The new name is applied everywhere at once.',
            confirmLabel: 'Rename',
            cancelLabel: 'Cancel',
            onConfirm: _noop,
            onCancel: _noop,
          ),
        ),
        ShowcaseItemWidget(
          label: 'destructive · submitting',
          child: MxConfirmDialog(
            title: 'Delete deck?',
            message:
                'This deletes 4 sub-decks and 11 cards. It cannot be undone.',
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
            onConfirm: _noop,
            onCancel: _noop,
            variant: MxConfirmDialogVariant.destructive,
            isSubmitting: true,
          ),
        ),
      ],
    );
  }
}

class _ActionSheetSection extends StatelessWidget {
  const _ActionSheetSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'MxActionSheet',
      children: <Widget>[
        ShowcaseItemWidget(
          label: 'normal / destructive / disabled rows',
          child: _SheetSurface(
            child: MxActionSheet(
              title: 'Deck actions',
              actions: <MxActionSheetAction>[
                MxActionSheetAction(
                  label: 'Rename',
                  onPressed: _noop,
                  icon: Icons.edit_outlined,
                ),
                MxActionSheetAction(
                  label: 'Move',
                  onPressed: _noop,
                  icon: Icons.drive_file_move_outlined,
                  isEnabled: false,
                ),
                MxActionSheetAction(
                  label: 'Delete',
                  onPressed: _noop,
                  icon: Icons.delete_outline,
                  variant: MxActionSheetActionVariant.destructive,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotDemoedNote extends StatelessWidget {
  const _NotDemoedNote();

  @override
  Widget build(BuildContext context) {
    return ShowcaseSectionWidget(
      title: 'Not demoed here',
      children: <Widget>[
        Text(
          'MxContentShell is the scaffold every product screen already sits '
          'in, and MxAsyncView is a rendering policy over AsyncValue whose '
          'three branches are the loading, error and content states shown '
          'above.',
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The surface `showModalBottomSheet` would normally paint under a sheet.
///
/// `MxActionSheet` deliberately paints no background of its own, so demoing it
/// inline needs this stand-in. A `Material`, not a `DecoratedBox`: the sheet's
/// rows are `ListTile`s, which paint their splashes on the nearest Material
/// ancestor — the framework asserts when a tile sits on a plain decorated box.
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
