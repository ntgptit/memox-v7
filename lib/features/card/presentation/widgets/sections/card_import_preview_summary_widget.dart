import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../../controllers/card_import_draft_controller.dart';
import '../items/card_import_row_preview_widget.dart';
import '../support/card_import_labels_widget.dart';

/// The duplicate-policy command, a free function for the same reason the
/// step's are: a `ref.read` written inline in `build()` is indistinguishable
/// from the unsubscribed read the guard forbids.
void _updateDuplicateChoice(
  WidgetRef ref,
  String deckId, {
  required bool value,
}) => ref
    .read(cardImportDuplicateChoiceProvider(deckId).notifier)
    .update(shouldIncludeDuplicates: value);

/// How many preview rows render before the "…and N more" footer takes over
/// (wireframe W3's 10–20 band). Display truncation only: the counts and the
/// commit always cover every row.
const int kCardImportPreviewRowLimit = 15;

/// The counts, the duplicate policy, and the first rows (UC-10 step 5).
class CardImportPreviewSummaryWidget extends ConsumerWidget {
  const CardImportPreviewSummaryWidget({
    required this.deckId,
    required this.preview,
    required this.shouldIncludeDuplicates,
    super.key,
  });

  final String deckId;
  final CardImportPreview preview;
  final bool shouldIncludeDuplicates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shown = preview.rows.take(kCardImportPreviewRowLimit).toList();
    final hiddenCount = preview.rows.length - shown.length;

    final importable = preview.importableCount(
      shouldIncludeDuplicates: shouldIncludeDuplicates,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The numbered heading with the readiness verdict beside it
        // (state 3): what the classification concluded, before the rows
        // prove it.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.cardImportPreviewHeading,
                style: context.texts.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              l10n.cardImportPreviewReadyOfTotal(importable, preview.totalRows),
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // One chip per status that actually occurred (state 4): a glyph, the
        // word and the count together, never colour alone (W7). Ready always
        // renders — "Ready · 0" is the honest headline of an all-broken file.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            _StatusChip(
              status: CardImportRowStatus.ready,
              count: preview.readyCount,
            ),
            if (preview.invalidCount > 0)
              _StatusChip(
                status: CardImportRowStatus.invalid,
                count: preview.invalidCount,
              ),
            if (preview.duplicateCount > 0)
              _StatusChip(
                status: CardImportRowStatus.duplicateExisting,
                count: preview.duplicateCount,
              ),
            if (preview.blankCount > 0)
              _StatusChip(
                status: CardImportRowStatus.blank,
                count: preview.blankCount,
              ),
          ],
        ),
        SwitchListTile(
          value: shouldIncludeDuplicates,
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.cardImportIncludeDuplicatesLabel,
            style: context.texts.bodyMedium,
          ),
          onChanged: (value) =>
              _updateDuplicateChoice(ref, deckId, value: value),
        ),
        for (final row in shown) CardImportRowPreviewWidget(row: row),
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.cardImportMoreRowsLabel(hiddenCount),
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// One status chip (state 4): the status word, its count, and the container
/// pair its rows use — plus the glyph, so colour never carries the meaning
/// alone. The two duplicate kinds share one chip word; the row detail is
/// where "already in deck" and "duplicate in file" tell themselves apart.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.count});

  final CardImportRowStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (
      IconData icon,
      Color background,
      Color foreground,
    ) = switch (status) {
      CardImportRowStatus.ready => (
        Icons.check,
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      CardImportRowStatus.invalid => (
        Icons.error_outline,
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      CardImportRowStatus.duplicateExisting ||
      CardImportRowStatus.duplicateInFile => (
        Icons.copy_outlined,
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      CardImportRowStatus.blank => (
        Icons.remove,
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
      ),
    };
    final label = switch (status) {
      CardImportRowStatus.duplicateExisting ||
      CardImportRowStatus.duplicateInFile =>
        context.l10n.cardImportStatusDuplicateChipLabel,
      _ => context.cardImportRowStatusLabel(status),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppSpacing.lg, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              context.l10n.cardImportStatusCountChip(label, count),
              style: context.texts.labelMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
