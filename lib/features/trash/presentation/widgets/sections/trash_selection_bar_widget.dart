import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../../domain/models/trash_item_type_model.dart';

/// The bar that appears while rows are selected (BR-266, wireframe T7).
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
      // **No `SafeArea` of its own.** `MxContentShell` already wraps the whole
      // body in one, and the bar is a Column sibling of the list rather than
      // something stacked over it — so the inner one resolved to zero while
      // reading as the bar owning the bottom inset. It would become
      // load-bearing again if this bar were ever mounted outside the shell.
      child: Padding(
        // The screen gutter, not a fixed `lg`: G1 asks for one left edge across
        // the chips, the retention notice and every row, and all of those step
        // down to 12 below 360dp where a literal stays at 16.
        padding: EdgeInsets.fromLTRB(
          mxScreenGutter(context),
          AppSpacing.md,
          mxScreenGutter(context),
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(switch (selectedType) {
              TrashItemType.card => l10n.trashSelectionCardsOnly,
              TrashItemType.deck => l10n.trashSelectionDecksOnly,
              null => l10n.trashSelectionCount(selectedCount),
            }, style: context.texts.bodySmall!.inked(context, AppInk.quiet)),
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
    );
  }
}
