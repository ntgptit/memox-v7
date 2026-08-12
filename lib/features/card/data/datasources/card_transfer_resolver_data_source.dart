import 'package:flutter/foundation.dart' show compute;

import '../../../../core/error/failure.dart';
import '../../domain/failures/card_transfer_failure.dart';
import '../../domain/models/card_transfer_document_model.dart';
import '../../domain/models/card_transfer_format_model.dart';
import '../../domain/models/card_transfer_source_model.dart';
import 'card_delimited_transfer_data_source.dart';
import 'card_xlsx_transfer_data_source.dart';

/// One decode strategy: bytes of one format in, the shared raw document out.
///
/// Every decoder emits the same [CardTransferDocument], which is the whole
/// point of the boundary — mapping, preview and commit read one shape, and a
/// future *encoder* strategy is this contract's mirror (records in, bytes
/// out) added beside it rather than through it. Decoders know nothing about
/// pickers, mapping, validation or the database.
abstract interface class CardTransferDecoder {
  CardTransferDocument decodeBytes(List<int> bytes);
}

/// The registry: the one place a format chooses its decoder (M99.19).
///
/// Every [CardTransferFormat] value resolves to exactly one strategy —
/// exhaustively, so adding a format fails to compile until it is decided
/// here, and nowhere else in UI, use case or repository may switch on
/// format. CSV and TSV share the delimited strategy, configured apart only
/// by their delimiter contract.
CardTransferDecoder cardTransferDecoderFor(CardTransferFormat format) =>
    switch (format) {
      CardTransferFormat.csv => const CardDelimitedTransferDataSource.detect(),
      CardTransferFormat.tsv => const CardDelimitedTransferDataSource.tab(),
      CardTransferFormat.xlsx => const CardXlsxTransferDataSource(),
    };

/// Decodes any source into the raw document — the top-level function the
/// transfer repository hands to `compute`, so a large workbook never stalls
/// the frame the Preview button was pressed on.
///
/// The switch here is on *source kind* (file vs pasted text), not format:
/// pasted text has no extension to resolve, and its contract is delimited
/// detection. Format dispatch stays in [cardTransferDecoderFor] alone.
CardTransferDocument decodeCardTransferSource(CardTransferSource source) {
  final document = switch (source) {
    CardTransferFileSource(:final bytes, :final format) =>
      cardTransferDecoderFor(format).decodeBytes(bytes),
    CardTransferTextSource(:final text) =>
      const CardDelimitedTransferDataSource.detect().decodeText(text),
  };

  final hasAnyRow = document.sheets.any(
    (CardTransferSheet sheet) => !sheet.isEmpty,
  );
  if (!hasAnyRow) {
    throw const ValidationFailure(
      message: 'The import source holds no data rows.',
      problems: <Enum>{CardTransferProblem.emptySource},
    );
  }

  return document;
}

/// The isolate-hopping wrapper the repository calls. On web `compute`
/// degrades to running in place, which is the accepted cost of keeping the
/// E2E channel building.
Future<CardTransferDocument> decodeCardTransferSourceOffThread(
  CardTransferSource source,
) => compute(decodeCardTransferSource, source);
