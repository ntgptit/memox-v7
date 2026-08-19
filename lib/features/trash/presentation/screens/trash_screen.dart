import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../domain/entities/trash_batch_entity.dart';
import '../../domain/models/trash_restore_target_model.dart';
import '../controllers/trash_controller.dart';
import '../states/trash_state.dart';
import '../widgets/items/trash_row_widget.dart';
import '../widgets/overlays/trash_purge_dialog_widget.dart';
import '../widgets/overlays/trash_row_menu_widget.dart';
import '../widgets/overlays/trash_restore_target_sheet_widget.dart';
import '../widgets/sections/trash_filter_bar_widget.dart';
import '../widgets/sections/trash_selection_bar_widget.dart';
import '../widgets/support/trash_labels_widget.dart';

/// Trash (UC-21).
///
/// **The retention sweep is not here.** It belongs to `trashBatchesProvider`,
/// which runs it before its first emission — a rule that lived in a widget's
/// `initState` would be a rule nothing can find (BR-264).
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(trashFilterControllerProvider);
    final selection = ref.watch(trashSelectionControllerProvider);
    final batches = ref.watch(trashBatchesProvider);

    return MxContentShell(
      title: selection.isActive
          ? l10n.trashSelectionCount(selection.batchIds.length)
          : l10n.trashTitle,
      leading: selection.isActive
          ? MxIconButton(
              icon: Icons.close,
              semanticLabel: l10n.trashPurgeCancelAction,
              onPressed: () => _clearSelection(ref),
            )
          : null,
      actions: <Widget>[
        // **Selection needs a visible way in** (wireframe W2, BR-266). Without
        // it, multi-select — half of UC-21 A2 — is reachable only by long
        // press: undiscoverable, and unreachable from a keyboard, which is the
        // channel the web E2E suite drives (AD-04).
        //
        // It appears only when there is something to select **under the
        // active filter** — the unfiltered list can be non-empty while the
        // body shows a filtered emptiness, and a Select that then silently
        // does nothing is a live-looking dead end. Disappears while
        // selecting, because the bar already offers the way out.
        if (!selection.isActive &&
            (batches.value?.any(
                  (TrashBatchEntity batch) => filter.admits(batch.itemType),
                ) ??
                false))
          MxIconButton(
            icon: Icons.checklist,
            semanticLabel: l10n.trashSelectAction,
            tooltip: l10n.trashSelectAction,
            onPressed: () => _beginSelection(ref, batches.value!, filter),
          ),
      ],
      padding: EdgeInsets.zero,
      subheader: selection.isActive
          ? null
          : TrashFilterBarWidget(
              filter: filter,
              onChanged: (value) => _setFilter(ref, value),
            ),
      body: MxAsyncView<List<TrashBatchEntity>>(
        value: batches,
        loadingLabel: l10n.trashTitle,
        error: (error, _) => MxErrorState(
          // The "Couldn't …" phrase is the headline, like every sibling
          // screen-level failure; the screen name alone told the user
          // nothing about what went wrong.
          title: l10n.trashLoadErrorTitle,
          message: l10n.trashLoadFailed,
          retryLabel: l10n.trashRetryAction,
          onRetry: () => ref.invalidate(trashBatchesProvider),
        ),
        data: (values) =>
            _TrashBody(filter: filter, selection: selection, batches: values),
      ),
    );
  }
}

/// Turns selection on by taking the first visible row (BR-266).
///
/// **The first row, not an empty selection**, because an empty one has no kind
/// and the bar would have nothing to explain — and because the user pressing
/// Select almost always wants the row they are looking at.
void _beginSelection(
  WidgetRef ref,
  List<TrashBatchEntity> batches,
  TrashFilter filter,
) {
  for (final batch in batches) {
    if (!filter.admits(batch.itemType)) continue;
    _toggleSelection(ref, batch);

    return;
  }
}

/// The three one-line writes the screen's chrome makes.
///
/// Free functions rather than inline `ref.read` calls, so `build` describes the
/// screen and nothing else. It is also what keeps the state-management guard
/// able to read this file: its rule cannot tell a `ref.read` inside a callback
/// from one at the top of `build`, and the shape it asks for is the clearer one.
void _clearSelection(WidgetRef ref) =>
    ref.read(trashSelectionControllerProvider.notifier).clear();

void _setFilter(WidgetRef ref, TrashFilter filter) =>
    ref.read(trashFilterControllerProvider.notifier).set(filter);

void _toggleSelection(WidgetRef ref, TrashBatchEntity batch) =>
    ref.read(trashSelectionControllerProvider.notifier).toggle(batch);

void _report(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        // Announced, not only drawn — the same liveRegion every other
        // dynamically-appearing message in the app carries.
        content: Semantics(liveRegion: true, child: Text(message)),
      ),
    );
}

class _TrashBody extends ConsumerWidget {
  const _TrashBody({
    required this.filter,
    required this.selection,
    required this.batches,
  });

  final TrashFilter filter;
  final TrashSelectionState selection;
  final List<TrashBatchEntity> batches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final visible = <TrashBatchEntity>[
      for (final batch in batches)
        if (filter.admits(batch.itemType)) batch,
    ];

    if (visible.isEmpty) {
      return MxEmptyState(
        icon: Icons.delete_outline,
        title: l10n.trashEmptyTitle,
        // Three empty states, not one: "nothing has been deleted" and "nothing
        // of *this kind* has been deleted" are different facts, and a single
        // line would be wrong for two of the three.
        message: switch (filter) {
          TrashFilter.all => l10n.trashEmptyMessage,
          TrashFilter.cards => l10n.trashEmptyCardsMessage,
          TrashFilter.decks => l10n.trashEmptyDecksMessage,
        },
      );
    }

    // One clock reading for the whole frame, so every countdown on screen is
    // measured against the same instant (AD-06, AD-13).
    final now = ref.watch(clockProvider)();
    final isBusy = ref.watch(trashPurgeControllerProvider).isSubmitting;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            // `lg`, the one number every scrollable list settled on (D21).
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            itemCount: visible.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return const _RetentionNotice();

              final batch = visible[index - 1];

              return TrashRowWidget(
                batch: batch,
                now: now,
                isSelecting: selection.isActive,
                isSelected: selection.contains(batch.batchId),
                canSelect: selection.admits(batch),
                onToggleSelection: () => _toggleSelection(ref, batch),
                onRestore: () => _restore(context, ref, batch),
                onMenu: () => showTrashRowMenu(
                  context,
                  onPurge: () => _purge(context, ref, <String>[batch.batchId]),
                ),
              );
            },
          ),
        ),
        if (selection.isActive)
          TrashSelectionBarWidget(
            selectedCount: selection.batchIds.length,
            selectedType: selection.itemType,
            isBusy: isBusy,
            onRestore: () => _restoreSelected(context, ref, visible),
            onPurge: () => _purge(
              context,
              ref,
              selection.batchIds.toList(growable: false),
            ),
          ),
      ],
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    TrashBatchEntity batch,
  ) async {
    final target = await showTrashRestoreTargetSheet(context, batch: batch);
    if (target == null || !context.mounted) return;

    await _restoreOne(context, ref, batchId: batch.batchId, target: target);
  }

  /// One restore, reported where it happened.
  ///
  /// The controller is a family on the batch, so a refusal belongs to the row
  /// the user acted on rather than to the screen — which is what lets a
  /// multi-row restore stop at the first refusal and name it.
  Future<bool> _restoreOne(
    BuildContext context,
    WidgetRef ref, {
    required String batchId,
    required TrashRestoreTarget target,
  }) async {
    final provider = trashRestoreControllerProvider(batchId);
    ref.read(provider.notifier).reset();
    // The outcome comes back from `submit` rather than from a second read: the
    // controller is an autoDispose family, so reading it after the await can
    // find a fresh notifier holding its initial state.
    final outcome = await ref.read(provider.notifier).submit(target);
    if (!context.mounted) return false;

    final failure = outcome.failure;
    if (failure != null) {
      _report(context, context.trashWriteFailure(failure));

      return false;
    }
    _report(context, context.l10n.trashRestoredMessage);

    return true;
  }

  /// Restores a whole selection into **one** target (BR-266).
  ///
  /// The picker opens for the first selected batch and the answer is applied to
  /// each in turn: they are all the same kind by construction, so one
  /// destination is a real answer for all of them. A per-batch picker would ask
  /// the same question N times for a set the user chose as one thing.
  Future<void> _restoreSelected(
    BuildContext context,
    WidgetRef ref,
    List<TrashBatchEntity> visible,
  ) async {
    final selected = <TrashBatchEntity>[
      for (final batch in visible)
        if (selection.contains(batch.batchId)) batch,
    ];
    if (selected.isEmpty) return;

    final target = await showTrashRestoreTargetSheet(
      context,
      batch: selected.first,
    );
    if (target == null || !context.mounted) return;

    for (final batch in selected) {
      final restored = await _restoreOne(
        context,
        ref,
        batchId: batch.batchId,
        target: target,
      );
      // The first refusal stops the run and has already been reported;
      // continuing would leave the user with a partial result and one message
      // that did not name which items moved.
      if (!restored) return;
      if (!context.mounted) return;
    }

    _clearSelection(ref);
  }

  Future<void> _purge(
    BuildContext context,
    WidgetRef ref,
    List<String> batchIds,
  ) async {
    final confirmed = await showTrashPurgeDialog(
      context,
      count: batchIds.length,
    );
    if (!confirmed || !context.mounted) return;

    final controller = ref.read(trashPurgeControllerProvider.notifier)..reset();
    final outcome = await controller.submit(batchIds);
    if (!context.mounted) return;

    // **Reported at the call site, not from a listener.** Only here is the
    // count known, and a purge that announced "Restored" — which one shared
    // listener over three commands did — is the worst thing this screen could
    // say on the one path that cannot be undone.
    final failure = outcome.failure;
    if (failure != null) {
      _report(context, context.trashWriteFailure(failure));

      return;
    }
    // Cleared only once the write has committed (BR-167): a selection dropped
    // optimistically is one the user cannot get back when it is refused.
    _clearSelection(ref);
    _report(context, context.l10n.trashPurgedMessage(batchIds.length));
  }
}

class _RetentionNotice extends StatelessWidget {
  const _RetentionNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        mxScreenGutter(context),
        AppSpacing.sm,
        mxScreenGutter(context),
        AppSpacing.md,
      ),
      child: Text(
        context.l10n.trashRetentionNotice,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
