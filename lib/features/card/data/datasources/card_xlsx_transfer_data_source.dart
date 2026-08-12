import 'package:excel/excel.dart' as xlsx;

import '../../../../core/error/failure.dart';
import '../../domain/failures/card_transfer_failure.dart';
import '../../domain/models/card_transfer_document_model.dart';
import 'card_transfer_resolver_data_source.dart';

/// The XLSX strategy (M99.19): cell data only, into the same raw document
/// shape the delimited strategy emits.
///
/// A formula cell contributes nothing rather than being evaluated, and
/// macros are never executed because nothing here runs content of any kind.
/// The database does not exist from where this class stands.
final class CardXlsxTransferDataSource implements CardTransferDecoder {
  const CardXlsxTransferDataSource();

  @override
  CardTransferDocument decodeBytes(List<int> bytes) {
    xlsx.Excel workbook;
    try {
      workbook = xlsx.Excel.decodeBytes(bytes);
    } on Object {
      // The package throws differently for corrupt archives, password
      // protection and truncated files; the recovery is the same re-export,
      // so one typed value covers them (UC-10 E1).
      throw const ValidationFailure(
        message: 'The workbook could not be opened.',
        problems: <Enum>{CardTransferProblem.unreadableFile},
      );
    }

    return CardTransferDocument(
      sheets: <CardTransferSheet>[
        for (final entry in workbook.tables.entries)
          CardTransferSheet(
            name: entry.key,
            rows: <CardTransferRow>[
              for (var i = 0; i < entry.value.rows.length; i++)
                CardTransferRow(
                  sourceRowNumber: i + 1,
                  cells: <String>[
                    for (final data in entry.value.rows[i])
                      cellValueToText(data?.value),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

/// The cell-to-string rules, stated once and unit-tested (UC-10):
/// numbers print without a trailing `.0`, booleans as `true`/`false`, dates
/// as ISO — and never via a blind `toString()` that could leak a package's
/// internal class name if a new cell kind appears.
String cellValueToText(xlsx.CellValue? value) {
  return switch (value) {
    null => '',
    xlsx.TextCellValue(:final value) => _flattenSpan(value),
    xlsx.IntCellValue(:final value) => value.toString(),
    xlsx.DoubleCellValue(:final value) =>
      value == value.roundToDouble() && value.isFinite
          ? value.toInt().toString()
          : value.toString(),
    xlsx.BoolCellValue(:final value) => value ? 'true' : 'false',
    xlsx.DateCellValue(:final year, :final month, :final day) =>
      '$year-${_two(month)}-${_two(day)}',
    xlsx.TimeCellValue(:final hour, :final minute, :final second) =>
      '${_two(hour)}:${_two(minute)}:${_two(second)}',
    xlsx.DateTimeCellValue() => value.asDateTimeUtc().toIso8601String(),
    // Cell data only: the formula is not evaluated, and its text is not the
    // cell's data.
    xlsx.FormulaCellValue() => '',
  };
}

String _flattenSpan(xlsx.TextSpan span) {
  final buffer = StringBuffer(span.text ?? '');
  for (final child in span.children ?? const <xlsx.TextSpan>[]) {
    buffer.write(_flattenSpan(child));
  }

  return buffer.toString();
}

String _two(int part) => part.toString().padLeft(2, '0');
