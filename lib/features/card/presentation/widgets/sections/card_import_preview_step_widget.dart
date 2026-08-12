import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_error_state.dart';
import '../../../../../shared/widgets/mx_loading_state.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../../../domain/models/card_transfer_document_model.dart';
import '../../../domain/models/card_transfer_field_model.dart';
import '../../controllers/card_import_draft_controller.dart';
import '../../controllers/card_import_query_controller.dart';
import '../items/card_import_mapping_row_widget.dart';
import '../items/card_import_row_preview_widget.dart';
import '../support/card_import_labels_widget.dart';

/// Free functions rather than inline reads in `build()`, the same shape
/// every widget in this feature uses for its commands.
void _selectSheet(WidgetRef ref, String deckId, String? name) =>
    ref.read(cardImportSheetChoiceProvider(deckId).notifier).select(name);

void _updateHeaderChoice(WidgetRef ref, String deckId, {required bool value}) =>
    ref
        .read(cardImportHeaderChoiceProvider(deckId).notifier)
        .update(hasHeader: value);

void _assignColumn(
  WidgetRef ref,
  String deckId,
  int column,
  CardTransferField? field,
) => ref
    .read(cardImportMappingDraftProvider(deckId).notifier)
    .assign(column, field);

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

/// Step 2 — sheet, header, mapping and the classified rows (UC-10 steps 4–5).
class CardImportPreviewStepWidget extends ConsumerWidget {
  const CardImportPreviewStepWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(cardImportDocumentProvider(deckId));

    return document.when(
      loading: () =>
          MxLoadingState(semanticsLabel: context.l10n.cardImportParsingLabel),
      error: (error, _) => MxErrorState(
        title: context.l10n.cardImportParseErrorTitle,
        message: error is Failure
            ? context.cardImportFailureLabel(error)
            : context.l10n.cardListError,
      ),
      data: (parsed) => _LoadedPreview(deckId: deckId, document: parsed),
    );
  }
}

class _LoadedPreview extends ConsumerWidget {
  const _LoadedPreview({required this.deckId, required this.document});

  final String deckId;
  final CardTransferDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetName = ref.watch(cardImportSheetChoiceProvider(deckId));
    final hasHeader = ref.watch(cardImportHeaderChoiceProvider(deckId));
    final mapping = ref.watch(cardImportMappingDraftProvider(deckId));
    final shouldIncludeDuplicates = ref.watch(
      cardImportDuplicateChoiceProvider(deckId),
    );
    final preview = ref.watch(cardImportPreviewProvider(deckId));

    final sheet = document.sheetNamed(sheetName);
    final headerCells = sheet != null && hasHeader && sheet.rows.isNotEmpty
        ? sheet.rows.first.cells
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (document.hasSheetChoice) ...<Widget>[
          _SheetSelector(
            document: document,
            selected: sheet?.name,
            onSelect: (name) => _selectSheet(ref, deckId, name),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        SwitchListTile(
          value: hasHeader,
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.l10n.cardImportHeaderToggleLabel,
            style: context.texts.bodyMedium,
          ),
          onChanged: (value) => _updateHeaderChoice(ref, deckId, value: value),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.cardImportMappingHeading,
          style: context.texts.labelLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var column = 0; column < (sheet?.columnCount ?? 0); column++)
          CardImportMappingRowWidget(
            column: column,
            headerText: hasHeader && column < headerCells.length
                ? headerCells[column]
                : '',
            field: mapping.fieldOf(column),
            onAssign: (field) => _assignColumn(ref, deckId, column, field),
          ),
        if (!mapping.isComplete)
          Text(
            context.l10n.cardImportMappingRequiredNote,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.error,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        preview.when(
          loading: () => MxLoadingState(
            semanticsLabel: context.l10n.cardImportParsingLabel,
          ),
          error: (error, _) => MxErrorState(
            title: context.l10n.cardImportParseErrorTitle,
            message: error is Failure
                ? context.cardImportFailureLabel(error)
                : context.l10n.cardListError,
          ),
          data: (rows) => _PreviewSummary(
            deckId: deckId,
            preview: rows,
            shouldIncludeDuplicates: shouldIncludeDuplicates,
          ),
        ),
      ],
    );
  }
}

class _SheetSelector extends StatelessWidget {
  const _SheetSelector({
    required this.document,
    required this.selected,
    required this.onSelect,
  });

  final CardTransferDocument document;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            context.l10n.cardImportSheetLabel,
            style: context.texts.bodyMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              onChanged: onSelect,
              items: <DropdownMenuItem<String>>[
                for (final sheet in document.sheets)
                  if (!sheet.isEmpty)
                    DropdownMenuItem<String>(
                      value: sheet.name,
                      child: Text(
                        sheet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The counts, the duplicate policy, and the first rows (UC-10 step 5).
class _PreviewSummary extends ConsumerWidget {
  const _PreviewSummary({
    required this.deckId,
    required this.preview,
    required this.shouldIncludeDuplicates,
  });

  final String deckId;
  final CardImportPreview preview;
  final bool shouldIncludeDuplicates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shown = preview.rows.take(kCardImportPreviewRowLimit).toList();
    final hiddenCount = preview.rows.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.cardImportSummaryTotalLabel(preview.totalRows),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportSummaryReadyLabel(preview.readyCount),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportSummaryDuplicateLabel(preview.duplicateCount),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportSummaryInvalidLabel(preview.invalidCount),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportSummaryBlankLabel(preview.blankCount),
                style: context.texts.bodyMedium,
              ),
            ],
          ),
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
