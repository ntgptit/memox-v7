import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../support/card_import_labels_widget.dart';

/// One preview row (M4.12 states 3–4): source number, Front and Back in
/// aligned columns, a trailing status glyph — and, when the row is invalid
/// or a duplicate, the typed reason on its own line so the user knows *why*
/// without decoding a colour.
///
/// A checkpoint, not an editor: long content ellipsizes. At 320dp or large
/// type the two columns stack — Front over Back — instead of overflowing,
/// decided by measuring the available width, not by a device list.
class CardImportRowPreviewWidget extends StatelessWidget {
  const CardImportRowPreviewWidget({required this.row, super.key});

  final CardImportRowPreview row;

  /// Below this many logical pixels the two content columns stack. The
  /// number is the narrowest width at which two ~10-character Korean/Latin
  /// cells stay legible side by side at 1.0× type; the stacked fallback is
  /// what actually guarantees no overflow at any width or scale.
  static const double _twoColumnMinWidth = 280;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (IconData statusIcon, Color statusColor) = switch (row.status) {
      CardImportRowStatus.ready => (Icons.check, colors.secondary),
      CardImportRowStatus.invalid => (Icons.close, colors.error),
      CardImportRowStatus.duplicateExisting ||
      CardImportRowStatus.duplicateInFile => (
        Icons.copy_outlined,
        colors.tertiary,
      ),
      CardImportRowStatus.blank => (Icons.remove, colors.onSurfaceVariant),
    };

    // The reason line: a typed refusal for invalid rows, the duplicate's
    // scope for duplicates — words, never colour alone (W7).
    final String? reason = switch (row.status) {
      CardImportRowStatus.invalid => context.cardImportRowIssueLabel(row),
      CardImportRowStatus.duplicateExisting ||
      CardImportRowStatus.duplicateInFile => context.cardImportRowStatusLabel(
        row.status,
      ),
      _ => null,
    };
    final reasonColor = row.status == CardImportRowStatus.invalid
        ? colors.error
        : colors.tertiary;

    final frontText = _CellText(value: row.front, isSecondary: false);
    final backText = _CellText(value: row.back, isSecondary: true);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: AppSpacing.xl,
            child: Text(
              '${row.sourceRowNumber}',
              style: context.texts.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    final isStacked =
                        constraints.maxWidth < _twoColumnMinWidth * scale;
                    if (isStacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[frontText, backText],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        Expanded(child: frontText),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: backText),
                      ],
                    );
                  },
                ),
                if (reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      reason,
                      style: context.texts.bodySmall?.copyWith(
                        color: reasonColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // The glyph is decoration over the words above; a screen reader
          // hears the status through the reason line and the summary chips.
          ExcludeSemantics(
            child: Icon(statusIcon, size: AppSpacing.lg, color: statusColor),
          ),
        ],
      ),
    );
  }
}

/// One content cell: the value ellipsized, or the localized "(empty)"
/// stand-in in italics so a blank never reads as a rendering bug.
class _CellText extends StatelessWidget {
  const _CellText({required this.value, required this.isSecondary});

  final String value;

  /// Back renders on the quieter colour so the pair scans as term → meaning.
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (value.isEmpty) {
      return Text(
        context.l10n.cardImportEmptyCellLabel,
        style: context.texts.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: colors.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      value,
      style: isSecondary
          ? context.texts.bodyMedium?.copyWith(color: colors.onSurfaceVariant)
          : context.texts.bodyMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
