import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;

import '../../../../core/error/failure.dart';
import '../../domain/failures/card_export_failure.dart';
import '../../domain/models/card_transfer_encoder_model.dart';
import '../../domain/models/card_transfer_record_model.dart';

/// The worksheet every export writes into.
///
/// Safe by construction: XLSX forbids `: \ / ? * [ ]` in a sheet name and caps
/// it at 31 characters, so a constant is the only spelling that cannot break
/// the workbook — deriving it from the deck name would put user text into a
/// structural position with its own escaping rules.
const String kCardExportWorksheetName = 'cards';

/// The XLSX encode strategy (M99.21) — the mirror of
/// `CardXlsxTransferDataSource`.
///
/// **Every cell is written as text, and that is the whole rule** (BR-179).
/// A spreadsheet reading `=1+1`, `+84 912 345 678`, `-5` or `@name` from a
/// general-typed cell evaluates it: the first becomes a formula, the phone
/// number becomes a number, and the user's content is gone from the file they
/// exported to keep it. `TextCellValue` stores the characters and nothing
/// else, so `001` stays `001` and a leading `=` stays a leading `=`.
///
/// One worksheet, and only one: the workbook the package creates comes with a
/// default sheet, which is deleted after ours exists so the file a user opens
/// has no empty second tab.
///
/// The database does not exist from where this class stands.
final class CardXlsxTransferEncoderDataSource implements CardTransferEncoder {
  const CardXlsxTransferEncoderDataSource();

  @override
  Uint8List encode(List<CardTransferRecord> records) {
    final workbook = xlsx.Excel.createExcel();
    // Touching the sheet by name is what creates it; the default sheet can
    // only be removed once a second one exists, which is why this order
    // matters.
    final sheet = workbook[kCardExportWorksheetName];
    for (final name in workbook.tables.keys.toList()) {
      if (name == kCardExportWorksheetName) continue;
      workbook.delete(name);
    }
    workbook.setDefaultSheet(kCardExportWorksheetName);

    final rows = <List<String>>[
      cardTransferHeaderRow,
      for (final record in records) cardTransferCellsOf(record),
    ];
    for (var row = 0; row < rows.length; row++) {
      final cells = rows[row];
      for (var column = 0; column < cells.length; column++) {
        sheet.updateCell(
          xlsx.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
          xlsx.TextCellValue(cells[column]),
        );
      }
    }

    final bytes = workbook.encode();
    if (bytes == null) {
      // The package returns null rather than throwing when it cannot build the
      // archive. Half a workbook must never reach the share sheet, so this is
      // a typed encode failure (UC-11 E4) and not an empty file.
      throw const ValidationFailure(
        message: 'The workbook could not be written.',
        problems: <Enum>{CardExportProblem.encodeFailed},
      );
    }

    return Uint8List.fromList(bytes);
  }
}
