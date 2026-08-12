import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../support/card_import_labels_widget.dart';

/// One preview row (UC-10 step 5): source number, a short front/back summary,
/// a status chip, and the typed reason when invalid.
///
/// A summary, deliberately — long content ellipsizes rather than expands,
/// because the preview is a checkpoint, not an editor (wireframe W3).
class CardImportRowPreviewWidget extends StatelessWidget {
  const CardImportRowPreviewWidget({required this.row, super.key});

  final CardImportRowPreview row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color chipBackground, Color chipForeground) = switch (row.status) {
      CardImportRowStatus.ready => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      CardImportRowStatus.invalid => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      CardImportRowStatus.duplicateExisting ||
      CardImportRowStatus.duplicateInFile => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      CardImportRowStatus.blank => (
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.cardImportRowNumberLabel(
                        row.sourceRowNumber,
                      ),
                      style: context.texts.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _summaryOf(row),
                      style: context.texts.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // The chip is text, not colour alone (W7): the word carries the
              // status for anyone the palette does not reach.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    context.cardImportRowStatusLabel(row.status),
                    style: context.texts.labelSmall?.copyWith(
                      color: chipForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (row.status == CardImportRowStatus.invalid)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                context.cardImportRowIssueLabel(row),
                style: context.texts.bodySmall?.copyWith(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }

  String _summaryOf(CardImportRowPreview row) {
    if (row.front.isEmpty && row.back.isEmpty) return '—';
    if (row.back.isEmpty) return row.front;
    if (row.front.isEmpty) return row.back;

    return '${row.front} → ${row.back}';
  }
}
