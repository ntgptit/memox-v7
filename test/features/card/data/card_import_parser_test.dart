import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/datasources/card_transfer_resolver_data_source.dart';
import 'package:memox/features/card/data/datasources/card_xlsx_transfer_data_source.dart';
import 'package:memox/features/card/domain/failures/card_transfer_failure.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_document_model.dart';

/// The parser's contract, on synthetic fixtures only — no personal data.
void main() {
  CardTransferFileSource file(
    String name,
    List<int> bytes, {
    CardTransferFormat? format,
  }) => CardTransferFileSource(
    name: name,
    bytes: Uint8List.fromList(bytes),
    format: format ?? CardTransferFormat.fromFileName(name)!,
  );

  List<List<String>> cellsOf(CardTransferDocument document) => <List<String>>[
    for (final row in document.sheets.first.rows) row.cells,
  ];

  CardTransferProblem? problemOf(Object failure) => failure is ValidationFailure
      ? failure.problems.whereType<CardTransferProblem>().firstOrNull
      : null;

  group('CSV', () {
    test('comma, LF', () {
      final doc = decodeCardTransferSource(
        file('a.csv', utf8.encode('front,back\n사과,apple\n')),
      );

      expect(cellsOf(doc), <List<String>>[
        <String>['front', 'back'],
        <String>['사과', 'apple'],
      ]);
    });

    test('semicolon and CRLF detect too', () {
      final doc = decodeCardTransferSource(
        file('a.csv', utf8.encode('front;back\r\n사과;apple\r\n')),
      );

      expect(cellsOf(doc)[1], <String>['사과', 'apple']);
    });

    test('a UTF-8 BOM is stripped, not read into the first header', () {
      final doc = decodeCardTransferSource(
        file('a.csv', <int>[
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode('front,back\nx,y'),
        ]),
      );

      expect(cellsOf(doc).first.first, 'front');
    });

    test('quoted commas, escaped quotes and newlines inside quotes', () {
      final doc = decodeCardTransferSource(
        file(
          'a.csv',
          utf8.encode('front,back\n"a, b","say ""hi"""\n"line1\nline2",tail\n'),
        ),
      );

      final rows = cellsOf(doc);
      expect(rows[1], <String>['a, b', 'say "hi"']);
      expect(rows[2], <String>['line1\nline2', 'tail']);
    });

    test('non-UTF-8 bytes refuse with invalidEncoding (BR-173)', () {
      // Latin-1 'é' — a lone 0xE9 is not valid UTF-8.
      expect(
        () => decodeCardTransferSource(
          file('a.csv', <int>[0x66, 0xE9, 0x2C, 0x67]),
        ),
        throwsA(
          predicate(
            (Object? e) => problemOf(e!) == CardTransferProblem.invalidEncoding,
          ),
        ),
      );
    });

    test('an empty file refuses with emptySource', () {
      expect(
        () => decodeCardTransferSource(file('a.csv', utf8.encode('  \n \n'))),
        throwsA(
          predicate(
            (Object? e) => problemOf(e!) == CardTransferProblem.emptySource,
          ),
        ),
      );
    });

    test('inconsistent column counts parse row by row, no crash', () {
      final doc = decodeCardTransferSource(
        file('a.csv', utf8.encode('a,b,c\nonly-one\nx,y\n')),
      );

      expect(cellsOf(doc)[1], <String>['only-one']);
      expect(cellsOf(doc)[2], <String>['x', 'y']);
    });
  });

  group('TSV', () {
    test('tab-delimited, and commas stay inside cells', () {
      final doc = decodeCardTransferSource(
        file('a.tsv', utf8.encode('front\tback\n사과, red\tapple\n')),
      );

      expect(cellsOf(doc)[1], <String>['사과, red', 'apple']);
    });
  });

  group('pasted text', () {
    test('parses like CSV, delimiter detected', () {
      final doc = decodeCardTransferSource(
        const CardTransferTextSource(text: 'front,back\n사과,apple'),
      );

      expect(cellsOf(doc)[1], <String>['사과', 'apple']);
    });

    test('empty text refuses with emptySource', () {
      expect(
        () =>
            decodeCardTransferSource(const CardTransferTextSource(text: '   ')),
        throwsA(
          predicate(
            (Object? e) => problemOf(e!) == CardTransferProblem.emptySource,
          ),
        ),
      );
    });
  });

  group('XLSX', () {
    Uint8List workbookBytes(void Function(xlsx.Excel) build) {
      final workbook = xlsx.Excel.createExcel();
      build(workbook);

      return Uint8List.fromList(workbook.save()!);
    }

    test('one sheet of text cells', () {
      final bytes = workbookBytes((workbook) {
        final sheet = workbook.sheets.values.first;
        sheet.appendRow(<xlsx.CellValue?>[
          xlsx.TextCellValue('front'),
          xlsx.TextCellValue('back'),
        ]);
        sheet.appendRow(<xlsx.CellValue?>[
          xlsx.TextCellValue('사과'),
          xlsx.TextCellValue('apple'),
        ]);
      });

      final doc = decodeCardTransferSource(file('a.xlsx', bytes));
      expect(doc.sheets.first.rows.last.cells, <String>['사과', 'apple']);
    });

    test('multiple sheets survive, and the default is the first '
        'non-empty', () {
      final bytes = workbookBytes((workbook) {
        // The created workbook has one default sheet, left empty on purpose.
        final second = workbook['Words'];
        second.appendRow(<xlsx.CellValue?>[xlsx.TextCellValue('사과')]);
      });

      final doc = decodeCardTransferSource(file('a.xlsx', bytes));
      expect(doc.sheets.length, greaterThan(1));
      expect(doc.defaultSheet!.name, 'Words');
    });

    test('blank cells read as empty strings', () {
      final bytes = workbookBytes((workbook) {
        workbook.sheets.values.first.appendRow(<xlsx.CellValue?>[
          xlsx.TextCellValue('사과'),
          null,
          xlsx.TextCellValue('apple'),
        ]);
      });

      final doc = decodeCardTransferSource(file('a.xlsx', bytes));
      expect(doc.sheets.first.rows.single.cells[1], '');
    });

    test('corrupt bytes refuse with unreadableFile', () {
      expect(
        () => decodeCardTransferSource(
          file('a.xlsx', List<int>.generate(64, (i) => i)),
        ),
        throwsA(
          predicate(
            (Object? e) => problemOf(e!) == CardTransferProblem.unreadableFile,
          ),
        ),
      );
    });
  });

  group('cell-to-string rules', () {
    test('numbers, booleans, dates and formulas', () {
      expect(cellValueToText(null), '');
      expect(cellValueToText(xlsx.TextCellValue('한국')), '한국');
      expect(cellValueToText(const xlsx.IntCellValue(42)), '42');
      // A whole double prints as an integer — Excel stores 42 as 42.0, and
      // "42.0" as a card front would be an artifact, not the user's data.
      expect(cellValueToText(const xlsx.DoubleCellValue(42)), '42');
      expect(cellValueToText(const xlsx.DoubleCellValue(2.5)), '2.5');
      expect(cellValueToText(const xlsx.BoolCellValue(true)), 'true');
      expect(
        cellValueToText(
          const xlsx.DateCellValue(year: 2026, month: 8, day: 12),
        ),
        '2026-08-12',
      );
      // Formulas are never evaluated; the cell contributes nothing.
      expect(cellValueToText(const xlsx.FormulaCellValue('=SUM(A1)')), '');
    });
  });
}
