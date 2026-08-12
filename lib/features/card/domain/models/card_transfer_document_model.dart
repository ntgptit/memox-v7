/// Stage 1 of the import pipeline: what a decode produced, before mapping
/// and before validation — rows of strings with their source position, and
/// nothing else.
///
/// Every decoder emits this same shape: CSV, TSV and pasted text as a single
/// nameless sheet, XLSX as one sheet per worksheet. Everything downstream —
/// mapping, preview, commit — reads this model and never a package's cell
/// type, which is what keeps the card business independent of which format
/// carried the rows.
library;

/// One row as the source held it: the 1-based row number the user's file
/// shows, and the cells as strings.
///
/// Cells are strings by the time they reach domain: the XLSX decoder owns
/// the cell-value-to-string rules (numbers, booleans, dates), so no layer
/// above it ever sees a package's cell type.
final class CardTransferRow {
  const CardTransferRow({required this.sourceRowNumber, required this.cells});

  /// 1-based, counted in the source — including the header row if there is
  /// one — so an invalid row's number matches what the user sees in Excel.
  final int sourceRowNumber;

  final List<String> cells;

  /// True when every cell is empty after trimming — the row BR-169 skips
  /// without counting it as an error.
  bool get isBlank => cells.every((String cell) => cell.trim().isEmpty);
}

/// One sheet's rows. CSV, TSV and pasted text decode to a single sheet whose
/// name is empty; only XLSX can have several (UC-10 A2).
final class CardTransferSheet {
  const CardTransferSheet({required this.name, required this.rows});

  final String name;
  final List<CardTransferRow> rows;

  bool get isEmpty => rows.every((CardTransferRow row) => row.isBlank);

  /// The widest row — how many source columns the mapping step offers.
  int get columnCount => rows.fold(
    0,
    (int widest, CardTransferRow row) =>
        row.cells.length > widest ? row.cells.length : widest,
  );
}

/// Everything one decode produced (UC-10 step 3).
final class CardTransferDocument {
  const CardTransferDocument({required this.sheets});

  final List<CardTransferSheet> sheets;

  /// The sheet UC-10 A2 selects by default: the first non-empty one, or the
  /// first at all so an all-empty workbook still has a name to show next to
  /// its "empty sheet" message.
  CardTransferSheet? get defaultSheet {
    for (final sheet in sheets) {
      if (!sheet.isEmpty) return sheet;
    }

    return sheets.isEmpty ? null : sheets.first;
  }

  CardTransferSheet? sheetNamed(String? name) {
    if (name == null) return defaultSheet;
    for (final sheet in sheets) {
      if (sheet.name == name) return sheet;
    }

    return defaultSheet;
  }

  /// Whether the sheet picker is worth showing: only when more than one
  /// sheet actually holds data (UC-10 A2).
  bool get hasSheetChoice =>
      sheets.where((CardTransferSheet sheet) => !sheet.isEmpty).length > 1;
}
