import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../../domain/models/trash_item_type_model.dart';

/// The bar that appears while rows are selected (BR-192, wireframe T7).
///
/// It carries the rule as a sentence, not as a disabled state somewhere else:
/// once a card is selected, deck rows stop responding, and this is where the
/// user is told why. Explaining after the fact — a refusal at submit — is
/// teaching a rule with an error.
///
/// **Only `Delete permanently` is destructive** (T10). Restore is the ordinary
/// role, because it is the safe half and colour is the only thing separating
/// the two under a thumb.
class TrashSelectionBarWidget extends StatelessWidget {
  const TrashSelectionBarWidget({
    required this.selectedCount,
    required this.selectedType,
    required this.isBusy,
    required this.onRestore,
    required this.onPurge,
    super.key,
  });

  final int selectedCount;
  final TrashItemType? selectedType;
  final bool isBusy;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        // The bar owns the bottom inset; the list adds its height as padding so
        // the last row is never underneath it (G5).
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                switch (selectedType) {
                  TrashItemType.card => l10n.trashSelectionCardsOnly,
                  TrashItemType.deck => l10n.trashSelectionDecksOnly,
                  null => l10n.trashSelectionCount(selectedCount),
                },
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // **`Wrap`, not `Row`, and that is a correctness fix rather than
              // a nicety.** As a `Row` the destructive text button was the
              // non-flex child, so it took its full intrinsic width first and
              // squeezed `Restore` into an ellipsis at 360dp with a large text
              // scale — leaving "Delete permanently" perfectly legible beside
              // a truncated way out. The safe action must never be the one
              // that loses the space.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  MxActionButton(
                    label: l10n.trashRestoreAction,
                    onPressed: isBusy ? null : onRestore,
                  ),
                  MxTextButton(
                    label: l10n.trashPurgeAction,
                    isDestructive: true,
                    onPressed: isBusy ? null : onPurge,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
