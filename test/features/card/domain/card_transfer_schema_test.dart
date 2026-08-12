import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/data/datasources/card_transfer_resolver_data_source.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_field_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_mapping_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/features/card/domain/usecases/build_card_import_preview_use_case.dart';

/// The canonical transfer schema (M99.19): the contract Export will encode
/// against, pinned while Import is its only user.
void main() {
  group('canonical schema', () {
    test('field order is stable and the headers are lowercase English', () {
      // The file contract: a future encoder writes exactly these, in exactly
      // this order, whatever locale the app runs in. UI labels localize;
      // the schema never does.
      expect(
        CardTransferField.values
            .map((CardTransferField f) => f.canonicalHeader)
            .toList(),
        <String>['front', 'back', 'example', 'hint', 'pronunciation', 'tags'],
      );
    });

    test('headers resolve case-insensitively and unknown names resolve to '
        'nothing', () {
      expect(CardTransferField.fromHeader(' FRONT '), CardTransferField.front);
      expect(CardTransferField.fromHeader('Tags'), CardTransferField.tags);
      // Aliases are decode-side convenience; localized or ambiguous names
      // still resolve to nothing.
      expect(CardTransferField.fromHeader('Term'), CardTransferField.front);
      expect(CardTransferField.fromHeader('mặt trước'), isNull);
      expect(CardTransferField.fromHeader('notes'), isNull);
    });

    test('front and back are the required pair; the rest map optionally', () {
      final required = CardTransferMapping.fromHeader(const <String>[
        'front',
        'back',
      ]);
      expect(required.isComplete, isTrue);

      final optionalOnly = CardTransferMapping.fromHeader(const <String>[
        'example',
        'hint',
        'pronunciation',
        'tags',
      ]);
      expect(optionalOnly.isComplete, isFalse);
    });

    test('the tags separator is the semicolon, stated once', () {
      expect(kCardTransferTagsSeparator, ';');
    });
  });

  group('format parity', () {
    // One data set, three representations. After decoding and mapping, all
    // three must yield the same canonical records — which is what makes the
    // formats representation only, and what a future encoder round-trips
    // against.
    const front = '사과';
    const back = 'apple, red';
    const tags = 'fruit;food';

    Uint8List xlsxBytes() {
      final workbook = xlsx.Excel.createExcel();
      final sheet = workbook.sheets.values.first;
      sheet.appendRow(<xlsx.CellValue?>[
        xlsx.TextCellValue('front'),
        xlsx.TextCellValue('back'),
        xlsx.TextCellValue('tags'),
      ]);
      sheet.appendRow(<xlsx.CellValue?>[
        xlsx.TextCellValue(front),
        xlsx.TextCellValue(back),
        xlsx.TextCellValue(tags),
      ]);

      return Uint8List.fromList(workbook.save()!);
    }

    test('CSV, TSV and XLSX decode the same data to equivalent records', () {
      final sources = <String, CardTransferSource>{
        'csv': CardTransferFileSource(
          name: 'a.csv',
          bytes: Uint8List.fromList(
            utf8.encode('front,back,tags\n$front,"$back",$tags\n'),
          ),
          format: CardTransferFormat.csv,
        ),
        'tsv': CardTransferFileSource(
          name: 'a.tsv',
          bytes: Uint8List.fromList(
            utf8.encode('front\tback\ttags\n$front\t$back\t$tags\n'),
          ),
          format: CardTransferFormat.tsv,
        ),
        'xlsx': CardTransferFileSource(
          name: 'a.xlsx',
          bytes: xlsxBytes(),
          format: CardTransferFormat.xlsx,
        ),
      };

      for (final entry in sources.entries) {
        final document = decodeCardTransferSource(entry.value);
        final sheet = document.defaultSheet!;
        final mapping = CardTransferMapping.fromHeader(sheet.rows.first.cells);
        final preview = classifyImportRows(
          sheet: sheet,
          mapping: mapping,
          hasHeaderRow: true,
          existingKeys: const <CardImportDuplicateKey>{},
        );

        final record = preview.records.single;
        expect(record.front.value, front, reason: entry.key);
        expect(record.back.value, back, reason: entry.key);
        expect(record.tags.map((t) => t.value).toList(), <String>[
          'fruit',
          'food',
        ], reason: entry.key);
      }
    });

    test('every format value resolves to exactly one decoder', () {
      // Exhaustive by the switch, but stated as data so a new enum value
      // must arrive with a registry decision and a test run.
      for (final format in CardTransferFormat.values) {
        expect(cardTransferDecoderFor(format), isNotNull, reason: format.name);
      }
    });
  });
}
