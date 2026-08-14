import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_async_view.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../domain/entities/trash_batch_entity.dart';
import '../../../domain/models/trash_restore_target_model.dart';
import '../../controllers/trash_controller.dart';
import '../support/trash_labels_widget.dart';

/// Asks where a batch should go back to (BR-187, wireframe T8, T9).
///
/// **No disabled rows.** The list is built from the production eligibility
/// rules, so anything drawn here would be accepted; a greyed-out row is one the
/// reader still has to read and which cannot explain itself. When nothing
/// qualifies, the sheet says so and offers only a way out (UC-12 E1).
///
/// Returns the chosen target, or null if the user backed out.
Future<TrashRestoreTarget?> showTrashRestoreTargetSheet(
  BuildContext context, {
  required TrashBatchEntity batch,
}) => showModalBottomSheet<TrashRestoreTarget>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: MxAsyncView<List<TrashRestoreTarget>>(
          value: targets,
          loadingLabel: l10n.trashRestoreTargetTitle,
          error: (error, _) => MxEmptyState(
            icon: Icons.error_outline,
            title: l10n.trashRestoreTargetTitle,
            message: context.trashCommandError(error),
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
      ),
    );
  }

  /// The preselected target, until the user picks something (T9, BR-188).
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
      return MxEmptyState(
        icon: Icons.block_outlined,
        title: l10n.trashRestoreTargetTitle,
        message: l10n.trashRestoreTargetEmpty,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.trashRestoreTargetTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];

              return MxListTile(
                title: switch (target) {
                  TrashTopLevelTarget() => l10n.trashRestoreTargetTopLevel,
                  TrashDeckTarget(name: final name) => name,
                },
                subtitle: switch (target) {
                  TrashTopLevelTarget() => null,
                  TrashDeckTarget(parentName: final parent) => parent,
                },
                isSelected: target.deckId == selectedDeckId,
                onTap: () => onSelect(target.deckId),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
