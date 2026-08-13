import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_error_state.dart';
import '../../../../../shared/widgets/mx_loading_state.dart';
import '../../../domain/models/card_transfer_document_model.dart';
import '../../../domain/models/card_transfer_field_model.dart';
import '../../controllers/card_import_draft_controller.dart';
import '../../controllers/card_import_query_controller.dart';
import '../../states/card_import_state.dart';
import '../items/card_import_mapping_row_widget.dart';
import '../support/card_import_labels_widget.dart';
import 'card_import_preview_summary_widget.dart';
import 'card_import_source_summary_widget.dart';

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

/// Step 2 — sheet, header, mapping and the classified rows (UC-10 steps 4–5).
class CardImportPreviewStepWidget extends ConsumerWidget {
  const CardImportPreviewStepWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(cardImportDocumentProvider(deckId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The chosen source stays as one compact line of context (state 2) —
        // never the whole chooser again, and never the pasted content
        // itself, which is private (BR-173).
        _SourceContext(deckId: deckId, document: document),
        const SizedBox(height: AppSpacing.lg),
        document.when(
          loading: () => _ParsingPanel(deckId: deckId),
          error: (error, _) => MxErrorState(
            title: context.l10n.cardImportParseErrorTitle,
            message: error is Failure
                ? context.cardImportFailureLabel(error)
                : context.l10n.cardListError,
          ),
          data: (parsed) => _LoadedPreview(deckId: deckId, document: parsed),
        ),
      ],
    );
  }
}

/// The compact source line above the preview: filename (or the pasted-text
/// stand-in), format and size, and a status that moves with the decode —
/// parsing first, then how many rows arrived. Context only: no replace, no
/// remove — changing the source from here is a navigation back to Source.
class _SourceContext extends ConsumerWidget {
  const _SourceContext({required this.deckId, required this.document});

  final String deckId;
  final AsyncValue<CardTransferDocument> document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kind = ref.watch(cardImportSourceChoiceProvider(deckId));
    final file = ref.watch(cardImportFilePickChoiceProvider(deckId)).file;
    final sheetName = ref.watch(cardImportSheetChoiceProvider(deckId));
    final hasHeader = ref.watch(cardImportHeaderChoiceProvider(deckId));

    final sheet = document.value?.sheetNamed(sheetName);
    // Detected rows are *data* rows — the header row is a label, not a card,
    // and this number must agree with the "N of N ready" total two sections
    // below (concept states 3-4 count the same way).
    final rawRowCount = sheet?.rows.length ?? 0;
    final dataRowCount = hasHeader && rawRowCount > 0
        ? rawRowCount - 1
        : rawRowCount;
    // No status on a failed parse: the error panel below already says what
    // happened, and "0 rows detected" would contradict it.
    final String? status = document.isLoading
        ? l10n.cardImportFileParsingStatus
        : sheet != null
        ? l10n.cardImportFileRowsDetected(dataRowCount)
        : null;

    if (kind == CardImportSourceKind.upload && file != null) {
      final meta = l10n.cardImportFileMetaLabel(
        file.format.name.toUpperCase(),
        context.cardImportFileSizeLabel(file.bytes.length),
      );

      return CardImportSourceSummaryWidget(
        title: file.name,
        subtitle: status == null
            ? meta
            : l10n.cardImportSourceStatusLine(meta, status),
      );
    }

    return CardImportSourceSummaryWidget(
      title: l10n.cardImportPastedSourceLabel,
      subtitle: status,
    );
  }
}

/// The parse in progress (state 2): one steady panel — a loader, what is
/// being read, and the reassurance that nothing is written until Import is
/// confirmed. Its shape never changes, so rows arriving replace it without
/// the layout jumping.
class _ParsingPanel extends ConsumerWidget {
  const _ParsingPanel({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kind = ref.watch(cardImportSourceChoiceProvider(deckId));

    return MxCard(
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: l10n.cardImportParsingLabel,
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            kind == CardImportSourceKind.upload
                ? l10n.cardImportParsingFileTitle
                : l10n.cardImportParsingPasteTitle,
            style: context.texts.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.cardImportParsingReassurance,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
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
          data: (rows) => CardImportPreviewSummaryWidget(
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
