import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/data/datasources/card_transfer_encoder_resolver_data_source.dart';
import 'package:memox/features/card/data/datasources/card_xlsx_transfer_encoder_data_source.dart';
import 'package:memox/features/card/domain/models/card_transfer_encoder_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_field_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';

import 'support/card_export_fixture.dart';

/// BR-179: six canonical headers, empty cells for absent optional fields, a
/// BOM on the delimited formats, and text — never a formula — in XLSX.
void main() {
  const bom = <int>[0xEF, 0xBB, 0xBF];

  String textOf(Uint8List bytes) => utf8.decode(bytes.sublist(bom.length));

  Uint8List encode(CardTransferFormat format, List<CardTransferRecord> rows) =>
      cardTransferEncoderFor(format).encode(rows);

  group('the resolver (AD-20)', () {
    test('every format resolves to an encoder', () {
      for (final format in CardTransferFormat.values) {
        expect(cardTransferEncoderFor(format), isA<CardTransferEncoder>());
      }
    });

    test('CSV and TSV share one strategy, configured apart', () {
      expect(
        cardTransferEncoderFor(CardTransferFormat.csv).runtimeType,
        cardTransferEncoderFor(CardTransferFormat.tsv).runtimeType,
      );
      expect(
        encode(CardTransferFormat.csv, <CardTransferRecord>[
          exportRecord(front: 'a', back: 'b'),
        ]),
        isNot(
          encode(CardTransferFormat.tsv, <CardTransferRecord>[
            exportRecord(front: 'a', back: 'b'),
          ]),
        ),
      );
    });
  });

  group('the canonical row (BR-175, BR-179)', () {
    test('six headers, in the schema order, lowercase English', () {
      expect(cardTransferHeaderRow, <String>[
        'front',
        'back',
        'example',
        'hint',
        'pronunciation',
        'tags',
      ]);
      expect(cardTransferHeaderRow.length, CardTransferField.values.length);
    });

    test('absent optional fields are empty cells, not placeholders', () {
      expect(cardTransferCellsOf(exportRecord(front: 'a', back: 'b')), <String>[
        'a',
        'b',
        '',
        '',
        '',
        '',
      ]);
    });

    test('the tags cell goes through the shared codec (BR-176)', () {
      final cells = cardTransferCellsOf(
        exportRecord(
          front: 'a',
          back: 'b',
          tags: const <String>['noun', 'has;semi', r'has\slash'],
        ),
      );

      expect(cells.last, r'noun;has\;semi;has\\slash');
    });
  });

  group('delimited (CSV and TSV)', () {
    for (final format in <CardTransferFormat>[
      CardTransferFormat.csv,
      CardTransferFormat.tsv,
    ]) {
      test('$format starts with a UTF-8 BOM (BR-179)', () {
        final bytes = encode(format, <CardTransferRecord>[
          exportRecord(front: 'a', back: 'b'),
        ]);

        expect(bytes.sublist(0, 3), bom);
      });

      test('$format writes the six headers as the first row', () {
        final bytes = encode(format, <CardTransferRecord>[
          exportRecord(front: 'a', back: 'b'),
        ]);
        final delimiter = format == CardTransferFormat.csv ? ',' : '\t';

        expect(
          textOf(bytes).split('\r\n').first,
          cardTransferHeaderRow.join(delimiter),
        );
      });

      test('$format keeps Korean and Vietnamese text intact', () {
        final bytes = encode(format, <CardTransferRecord>[
          exportRecord(
            front: '사과',
            back: 'quả táo',
            tags: const <String>['명사'],
          ),
        ]);

        expect(textOf(bytes), contains('사과'));
        expect(textOf(bytes), contains('quả táo'));
        expect(textOf(bytes), contains('명사'));
      });

      test('$format quotes a cell holding its own delimiter', () {
        final delimiter = format == CardTransferFormat.csv ? ',' : '\t';
        final bytes = encode(format, <CardTransferRecord>[
          exportRecord(front: 'a${delimiter}b', back: 'back'),
        ]);

        expect(textOf(bytes), contains('"a${delimiter}b"'));
      });

      test('$format doubles an embedded quote', () {
        final bytes = encode(format, <CardTransferRecord>[
          exportRecord(front: 'say "hi"', back: 'back'),
        ]);

        expect(textOf(bytes), contains('"say ""hi"""'));
      });

      test('$format quotes CRLF and a bare newline', () {
        final bytes = encode(format, <CardTransferRecord>[
          exportRecord(front: 'line1\r\nline2', back: 'a\nb'),
        ]);
        final text = textOf(bytes);

        expect(text, contains('"line1\r\nline2"'));
        expect(text, contains('"a\nb"'));
      });

      test('$format leaves number-looking text alone', () {
        final bytes = encode(format, <CardTransferRecord>[
          exportRecord(front: '001', back: '1e3', hint: '+84 912 345 678'),
        ]);
        final text = textOf(bytes);

        expect(text, contains('001'));
        expect(text, contains('1e3'));
        expect(text, contains('+84 912 345 678'));
        expect(text, isNot(contains('1000')));
      });

      test('$format writes empty cells for every absent optional field', () {
        final bytes = encode(format, <CardTransferRecord>[
          exportRecord(front: 'a', back: 'b'),
        ]);
        final delimiter = format == CardTransferFormat.csv ? ',' : '\t';

        expect(
          textOf(bytes).split('\r\n')[1],
          'a${delimiter}b$delimiter$delimiter$delimiter$delimiter',
        );
      });
    }
  });

  group('xlsx', () {
    List<List<String>> readBack(Uint8List bytes) {
      final workbook = xlsx.Excel.decodeBytes(bytes);
      final sheet = workbook.tables[kCardExportWorksheetName]!;

      return <List<String>>[
        for (final row in sheet.rows)
          <String>[for (final cell in row) cell?.value?.toString() ?? ''],
      ];
    }

    test('the same records encode to the same content twice over '
        '(BR-177)', () async {
      // **What determinism means here, stated where it can be checked.**
      // BR-177 promises the same *logical* artifact — same records, same
      // order, same cells — and BR-175 explains why it cannot promise the same
      // bytes: `package:archive` stamps every zip entry with the wall clock,
      // so an XLSX written two seconds later differs in twenty bytes it does
      // not own. The delay is what makes that difference visible at all: the
      // DOS timestamp a zip carries has two-second granularity, so a test
      // without it would pass on byte equality by accident and stop being
      // about anything.
      final records = <CardTransferRecord>[
        exportRecord(front: '사과', back: 'quả táo', tags: const <String>['a']),
        exportRecord(front: '배', back: 'pear'),
      ];

      final first = readBack(encode(CardTransferFormat.xlsx, records));
      await Future<void>.delayed(const Duration(seconds: 3));
      final second = readBack(encode(CardTransferFormat.xlsx, records));

      expect(second, first);
    });

    test('one worksheet, with a name the format always accepts', () {
      final bytes = encode(CardTransferFormat.xlsx, <CardTransferRecord>[
        exportRecord(front: 'a', back: 'b'),
      ]);
      final workbook = xlsx.Excel.decodeBytes(bytes);

      expect(workbook.tables.keys, <String>[kCardExportWorksheetName]);
    });

    test('headers first, then one row per record', () {
      final bytes = encode(CardTransferFormat.xlsx, <CardTransferRecord>[
        exportRecord(front: '사과', back: 'quả táo'),
        exportRecord(front: '배', back: 'pear'),
      ]);
      final rows = readBack(bytes);

      expect(rows.first, cardTransferHeaderRow);
      expect(rows[1].take(2), <String>['사과', 'quả táo']);
      expect(rows[2].take(2), <String>['배', 'pear']);
    });

    test('every cell is stored as text — no cell becomes a formula', () {
      final bytes = encode(CardTransferFormat.xlsx, <CardTransferRecord>[
        exportRecord(
          front: '=1+1',
          back: '+84 912 345 678',
          example: '-5',
          hint: '@name',
          pronunciation: '001',
          tags: const <String>['1e3'],
        ),
      ]);
      final workbook = xlsx.Excel.decodeBytes(bytes);
      final row = workbook.tables[kCardExportWorksheetName]!.rows[1];

      for (final cell in row) {
        expect(
          cell?.value,
          isA<xlsx.TextCellValue>(),
          reason: 'cell ${cell?.cellIndex} must be text (BR-179)',
        );
      }
      expect(
        <String>[for (final cell in row) cell!.value!.toString()],
        <String>['=1+1', '+84 912 345 678', '-5', '@name', '001', '1e3'],
      );
    });

    test('absent optional fields stay empty, never a placeholder', () {
      final bytes = encode(CardTransferFormat.xlsx, <CardTransferRecord>[
        exportRecord(front: 'a', back: 'b'),
      ]);
      final row = readBack(bytes)[1];

      expect(row.take(2), <String>['a', 'b']);
      expect(row.skip(2).every((String cell) => cell.isEmpty), isTrue);
    });

    test('escaped tags survive as one cell', () {
      final bytes = encode(CardTransferFormat.xlsx, <CardTransferRecord>[
        exportRecord(
          front: 'a',
          back: 'b',
          tags: const <String>['has;semi', r'has\slash'],
        ),
      ]);

      expect(readBack(bytes)[1].last, r'has\;semi;has\\slash');
    });
  });
}
