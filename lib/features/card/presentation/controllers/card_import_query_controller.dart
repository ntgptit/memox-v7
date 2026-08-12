import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/retry_policy.dart';
import '../../domain/failures/card_transfer_failure.dart';
import '../../domain/models/card_import_preview_model.dart';
import '../../domain/models/card_transfer_source_model.dart';
import '../../domain/models/card_transfer_document_model.dart';
import '../providers/card_import_use_case_provider.dart';
import '../states/card_import_state.dart';
import 'card_import_draft_controller.dart';

part 'card_import_query_controller.g.dart';

/// The parsed document for one deck's draft (UC-10 step 3).
///
/// Parsing runs when this is first watched — which happens when the Preview
/// step mounts, i.e. when the user pressed `Preview import` (wireframe I4) —
/// and again only when the effective source changes. Typing in the paste box
/// never reaches here, because the text provider is written at the button,
/// not per keystroke.
///
/// Automatic retry is off like every local read: while Riverpod retries, the
/// state is `AsyncLoading`, so a parse failure would spin instead of showing
/// the typed error panel the step draws.
@Riverpod(retry: noAutomaticRetry)
Future<CardTransferDocument> cardImportDocument(Ref ref, String deckId) {
  final kind = ref.watch(cardImportSourceChoiceProvider(deckId));
  final source = switch (kind) {
    CardImportSourceKind.upload =>
      ref.watch(cardImportFilePickChoiceProvider(deckId)).file,
    CardImportSourceKind.paste => _textSourceOf(
      ref.watch(cardImportPastedTextProvider(deckId)),
    ),
  };
  if (source == null) {
    // Defensive: the screen gates the Preview step on a source existing, so
    // reaching this is a deep link into half a draft — same copy as an empty
    // file, same recovery (go back and choose one).
    throw const ValidationFailure(
      message: 'No import source has been chosen.',
      problems: <Enum>{CardTransferProblem.emptySource},
    );
  }

  return ref.watch(parseCardTransferUseCaseProvider)(source);
}

CardTransferSource? _textSourceOf(String text) =>
    text.trim().isEmpty ? null : CardTransferTextSource(text: text);

/// The preview for the draft as it stands (UC-10 step 5): one repository
/// read for the deck's existing duplicate keys, then a pure classification.
/// Rebuilds when the document, sheet, header flag or mapping moves — each of
/// those changes what the rows *mean*.
@Riverpod(retry: noAutomaticRetry)
Future<CardImportPreview> cardImportPreview(Ref ref, String deckId) async {
  final document = await ref.watch(cardImportDocumentProvider(deckId).future);
  final sheetName = ref.watch(cardImportSheetChoiceProvider(deckId));
  final hasHeader = ref.watch(cardImportHeaderChoiceProvider(deckId));
  final mapping = ref.watch(cardImportMappingDraftProvider(deckId));

  final sheet = document.sheetNamed(sheetName);
  if (sheet == null || sheet.isEmpty) {
    throw const ValidationFailure(
      message: 'The chosen sheet holds no data rows.',
      problems: <Enum>{CardTransferProblem.emptySheet},
    );
  }

  return ref.watch(buildCardImportPreviewUseCaseProvider)(
    deckId: deckId,
    sheet: sheet,
    mapping: mapping,
    hasHeaderRow: hasHeader,
  );
}
