import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pressable.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../domain/entities/trash_batch_entity.dart';
import '../../../domain/models/trash_item_type_model.dart';
import '../support/trash_labels_widget.dart';

/// One deletion, as a row (wireframe W2, T4).
///
/// Four facts and one action, in the order a reader asks for them: what it is,
/// when it went, where it was, how long is left. The path is the third line and
/// carries no affordance — it is context, not a destination (BR-267, T5).
///
/// **`Restore` is the row's trailing action and `Delete permanently` is in the
/// overflow** (T6). Rescuing data has to cost fewer taps than destroying it;
/// side by side, the two would be one mis-tap apart and only one of them is
/// reversible.
class TrashRowWidget extends StatelessWidget {
  const TrashRowWidget({
    required this.batch,
    required this.now,
    required this.isSelecting,
    required this.isSelected,
    required this.canSelect,
    required this.onRestore,
    required this.onMenu,
    required this.onToggleSelection,
    super.key,
  });

  final TrashBatchEntity batch;

  /// Read once by the screen and passed down, so every row on one frame
  /// measures its countdown against the same instant (AD-06, AD-13).
  final DateTime now;

  final bool isSelecting;
  final bool isSelected;

  /// False for a row of the kind the selection is not holding (BR-266). The row
  /// stays legible and stops responding, and the selection bar says why.
  final bool canSelect;

  final VoidCallback onRestore;

  /// Opens the row's overflow menu; what it holds is the screen's
  /// business (wireframe T6 keeps purge one tap behind Restore).
  final VoidCallback onMenu;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDimmed = isSelecting && !canSelect;

    return Semantics(
      // One node for the whole row: a screen reader should hear the item, its
      // kind, when it went and how long is left as one sentence rather than as
      // four unrelated labels (R5).
      container: true,
      selected: isSelecting ? isSelected : null,
      label: <String>[
        batch.itemName,
        context.trashItemTypeLabel(batch.itemType),
        l10n.trashDeletedDaysAgo(_daysSince),
        l10n.trashDaysLeft(batch.daysLeftAt(now)),
      ].join(', '),
      child: Opacity(
        opacity: isDimmed ? 0.38 : 1,
        // Full-bleed row: the ripple runs edge to edge, so the shape is none.
        child: MxPressable(
          onTap: isSelecting && canSelect ? onToggleSelection : null,
          onLongPress: canSelect ? onToggleSelection : null,
          shape: MxPressableShape.none,
          child: Padding(
            // The screen gutter, not a fixed token: G1 requires the chips, the
            // notice and every row to share one left edge, and the shell's
            // gutter is 12 below 360dp and 16 above it.
            padding: EdgeInsets.symmetric(
              horizontal: mxScreenGutter(context),
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isSelecting)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    // `secondary`, aligning with the selected-mark decision
                    // recorded on the card tile and the import source step:
                    // dark `primary` measures 3.29:1 as a glyph.
                    child: MxIcon(
                      isSelected
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank,
                      ink: AppInk.secondary,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: MxIcon(
                      batch.itemType == TrashItemType.deck
                          ? Icons.folder_outlined
                          : Icons.style_outlined,
                    ),
                  ),
                // The two leading icons above stay outside this exclusion
                // on purpose: a bare `Icon` self-excludes its glyph, so they
                // contribute no narration — but give one a `semanticLabel`
                // and it must move inside here, or the double narration
                // returns.
                // **Excluded, because the row's label already says all of
                // it.** Without this a reader hears the composed sentence,
                // then every fact again one Text at a time — the exact
                // double narration the card-history rows exclude for. The
                // Restore and menu buttons stay outside the exclusion: they
                // are independently actionable and keep their own labels.
                Expanded(
                  child: ExcludeSemantics(
                    child: _Body(batch: batch, now: now),
                  ),
                ),
                if (!isSelecting) ...<Widget>[
                  MxIconButton(
                    icon: Icons.restore,
                    semanticLabel: l10n.trashRestoreAction,
                    tooltip: l10n.trashRestoreAction,
                    onPressed: onRestore,
                  ),
                  MxIconButton(
                    icon: Icons.more_vert,
                    semanticLabel: l10n.trashRowMenuTitle,
                    tooltip: l10n.trashRowMenuTitle,
                    onPressed: onMenu,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Whole days since the deletion, floored — the row says "today" for anything
  /// under one.
  int get _daysSince => now.difference(batch.deletedAt).inDays;
}

class _Body extends StatelessWidget {
  const _Body({required this.batch, required this.now});

  final TrashBatchEntity batch;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          batch.itemName,
          style: theme.textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        // **`Wrap`, not `Row`.** R1 asks for two things at once — the age may
        // ellipsize, the countdown may not — and a `Row` can only give one of
        // them: the non-flex countdown took its full intrinsic width and
        // overflowed the row outright at 320dp with a large text scale
        // ("Deleted forever today" is ~250dp there). Wrapping puts the
        // countdown on its own line instead, which costs a line and truncates
        // nothing.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            Text(
              l10n.trashDeletedDaysAgo(now.difference(batch.deletedAt).inDays),
              style: context.texts.bodySmall!.inked(context, AppInk.quiet),
            ),
            // **The one number allowed to carry urgency** (T4). Everything else
            // on the row is neutral, so the countdown is what the eye finds.
            Text(
              l10n.trashDaysLeft(batch.daysLeftAt(now)),
              style: context.texts.bodySmall!.inked(context, AppInk.tertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${l10n.trashOriginLabel}  ${context.trashOriginPath(batch)}',
          style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (batch.itemType == TrashItemType.deck) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.trashBatchContents(batch),
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
