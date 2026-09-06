import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_async_view.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_error_state.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../domain/entities/trash_batch_entity.dart';
import '../../../domain/models/trash_restore_target_model.dart';
import '../../controllers/trash_controller.dart';
import '../support/trash_labels_widget.dart';
import '../../../../../shared/widgets/mx_sheet.dart';
import '../../../../../shared/widgets/mx_sheet_insets.dart';

/// Asks where a batch should go back to (BR-261, wireframe T8, T9).
///
/// **No disabled rows.** The list is built from the production eligibility
/// rules, so anything drawn here would be accepted; a greyed-out row is one the
/// reader still has to read and which cannot explain itself. When nothing
/// qualifies, the sheet says so and offers only a way out (UC-21 E1).
///
/// Returns the chosen target, or null if the user backed out.
Future<TrashRestoreTarget?> showTrashRestoreTargetSheet(
  BuildContext context, {
  required TrashBatchEntity batch,
}) => showMxSheet<TrashRestoreTarget>(
  context,
  builder: (sheetContext) => _TrashRestoreTargetSheet(batch: batch),
);

class _TrashRestoreTargetSheet extends ConsumerStatefulWidget {
  const _TrashRestoreTargetSheet({required this.batch});

  final TrashBatchEntity batch;

  @override
  ConsumerState<_TrashRestoreTargetSheet> createState() =>
      _TrashRestoreTargetSheetState();
}

class _TrashRestoreTargetSheetState
    extends ConsumerState<_TrashRestoreTargetSheet> {
  /// What the user has picked. Held by deck id rather than by target, because
  /// the list is a live stream and the object identity changes on every
  /// emission while the id does not.
  String? _selectedDeckId;
  bool _hasSelection = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final targets = ref.watch(
      trashRestoreTargetsProvider(widget.batch.batchId),
    );

    return MxSheetInsets(
      child: MxAsyncView<List<TrashRestoreTarget>>(
        value: targets,
        loadingLabel: l10n.trashRestoreTargetTitle,
        // **Every `Center`-based face gets a min Column, not just the error
        // one.** The sheet hands down a bounded, loose height and each of
        // `MxLoadingState`, `MxErrorState` and `MxEmptyState` centres itself,
        // so bare they stretch this compact sheet to full height. A min Column
        // gives its child unbounded height, which is exactly what makes a
        // `Center`-based state hug its content. The wrap used to be on the
        // error face alone, so the same modal opened full-screen while loading
        // and then snapped ~350dp shorter the moment the targets arrived. The
        // data face stays outside the wrap on purpose — its
        // `Flexible(ListView)` needs the bounded constraint the sheet
        // provides.
        loadingFrame: (loading) =>
            Column(mainAxisSize: MainAxisSize.min, children: <Widget>[loading]),
        // The app's one full-surface error grammar (C10): a failed read
        // offers Retry where it failed, not a dead face the user can only
        // dismiss. Invalidate re-runs the watch.
        error: (error, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MxErrorState(
              // The headline names the failure, not the sheet. `Restore to`
              // in large type above a failure message told the reader nothing
              // about what went wrong — the same correction `trash_screen`
              // made for the list itself. Not `trashLoadErrorTitle` though:
              // Trash is open, it is the target read that failed, so this
              // takes the generic phrase its structural sibling
              // `card_bulk_overlays_widget` already uses, and the specifics
              // stay in the message below.
              title: l10n.unexpectedErrorTitle,
              message: context.trashCommandError(error),
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(
                trashRestoreTargetsProvider(widget.batch.batchId),
              ),
            ),
          ],
        ),
        data: (values) => _Body(
          batch: widget.batch,
          targets: values,
          selectedDeckId: _resolveSelection(values),
          onSelect: (deckId) => setState(() {
            _selectedDeckId = deckId;
            _hasSelection = true;
          }),
          onConfirm: () {
            final chosen = _chosen(values);
            if (chosen == null) return;
            Navigator.of(context).pop(chosen);
          },
        ),
      ),
    );
  }

  /// The preselected target, until the user picks something (T9, BR-262).
  ///
  /// **Preselecting is not choosing.** The primary still has to be pressed, so
  /// the sheet saves a tap without turning silence into consent. The default is
  /// the batch's own origin when that is still eligible — the most likely
  /// answer — and otherwise nothing.
  String? _resolveSelection(List<TrashRestoreTarget> targets) {
    if (_hasSelection) return _selectedDeckId;

    final originId = widget.batch.originDeckId;
    for (final target in targets) {
      if (target.deckId == originId) return originId;
    }

    return targets.length == 1 ? targets.single.deckId : null;
  }

  TrashRestoreTarget? _chosen(List<TrashRestoreTarget> targets) {
    final selected = _resolveSelection(targets);
    for (final target in targets) {
      if (target.deckId == selected) return target;
    }

    return null;
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.batch,
    required this.targets,
    required this.selectedDeckId,
    required this.onSelect,
    required this.onConfirm,
  });

  final TrashBatchEntity batch;
  final List<TrashRestoreTarget> targets;
  final String? selectedDeckId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onConfirm;

  /// The top level is a real target whose `deckId` is null, so "nothing chosen"
  /// cannot be read from the id alone.
  bool get hasTopLevelTarget =>
      targets.any((target) => target is TrashTopLevelTarget);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (targets.isEmpty) {
      // Min Column for the same reason the loading and error faces have one:
      // `MxEmptyState` is a `Center`, and bare it made one sentence — "there
      // is nowhere this can go back to" — fill the whole screen.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MxEmptyState(
            icon: Icons.block_outlined,
            title: l10n.trashRestoreTargetTitle,
            message: l10n.trashRestoreTargetEmpty,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The sheet's title announces as a header (A20.1 P1-01, §23 #17).
        Semantics(
          header: true,
          child: Text(
            l10n.trashRestoreTargetTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];
              final isSelected = target.deckId == selectedDeckId;

              return MxListTile(
                title: switch (target) {
                  TrashTopLevelTarget() => l10n.trashRestoreTargetTopLevel,
                  TrashDeckTarget(name: final name) => name,
                },
                subtitle: switch (target) {
                  TrashTopLevelTarget() => null,
                  TrashDeckTarget(parentName: final parent) => parent,
                },
                // Selected state is never colour alone — the same rule and
                // the same glyph as the study-direction chooser, this
                // picker's pair in `MxListTile`'s own note. Without it the
                // only difference between the chosen deck and the rest was
                // the tile tint and a recoloured title, which a monochrome
                // display and a colour-blind reader both lose. `accent` on
                // the filled glyph because it is the signal here; the tint is
                // the reinforcement.
                leading: MxIcon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  ink: isSelected ? AppInk.accent : AppInk.quiet,
                ),
                isSelected: isSelected,
                onTap: () => onSelect(target.deckId),
              );
            },
          ),
        ),
        // `lg`, not the `md` above: this is the sheet's terminal boundary,
        // not another gap inside the picker. At `md` the control that ends
        // the sheet was separated from the list by exactly as much as the
        // title is from the first row — `md` is the scale's inside-a-compact-
        // control step — so the primary read as one more item of the list it
        // closes. Every sibling sheet that ends in an action steps at `lg` or
        // wider (study_direction_chooser_widget.dart:152,
        // study_resume_widget.dart:44, starter_install_widget.dart:164).
        const SizedBox(height: AppSpacing.lg),
        MxActionButton(
          label: l10n.trashRestoreConfirmAction,
          // Disabled rather than silently inert: with several targets and no
          // preselection, this used to be a live button whose tap did nothing
          // and said nothing.
          onPressed: selectedDeckId == null && !hasTopLevelTarget
              ? null
              : onConfirm,
        ),
      ],
    );
  }
}
