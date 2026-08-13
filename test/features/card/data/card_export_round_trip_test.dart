import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/data/datasources/card_transfer_encoder_resolver_data_source.dart';
import 'package:memox/features/card/data/datasources/card_transfer_resolver_data_source.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_mapping_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/usecases/build_card_import_preview_use_case.dart';

import 'support/card_export_fixture.dart';

/// AD-20's round-trip expectation, through production code end to end:
/// production encoder → production decoder resolver → production auto-map →
/// production row classification.
///
/// **No oracle of this test's own.** A helper that re-implemented the decode
/// would only prove the encoder agrees with a second thing written by the same
/// hand at the same time; the point of the assertion is that the *import*
/// pipeline — the one users actually run — reads what export wrote.
void main() {
  /// The other half of the pipeline, exactly as Import runs it: decode the
  /// bytes with the format's registered decoder, auto-map the header row, then
  /// classify the rows through the card value objects.
  List<CardTransferRecord> importBack(
    Uint8List bytes,
    CardTransferFormat format,
  ) {
    final document = cardTransferDecoderFor(format).decodeBytes(bytes);
    final sheet = document.defaultSheet!;
    final mapping = CardTransferMapping.fromHeader(sheet.rows.first.cells);

    expect(
      mapping.isComplete,
      isTrue,
      reason: 'auto-map must recognise the canonical headers ($format)',
    );

    final preview = classifyImportRows(
      sheet: sheet,
      mapping: mapping,
      hasHeaderRow: true,
      existingKeys: const <CardImportDuplicateKey>{},
    );

    expect(
      preview.invalidCount,
      0,
      reason: 'no exported row may come back invalid ($format)',
    );
    expect(preview.duplicateCount, 0, reason: 'the fixture has no duplicates');

    return preview.records;
  }

  void expectSameRecord(
    CardTransferRecord actual,
    CardTransferRecord expected,
    String reason,
  ) {
    expect(actual.front.value, expected.front.value, reason: '$reason front');
    expect(actual.back.value, expected.back.value, reason: '$reason back');
    expect(
      actual.example?.value,
      expected.example?.value,
      reason: '$reason example',
    );
    expect(actual.hint?.value, expected.hint?.value, reason: '$reason hint');
    expect(
      actual.pronunciation?.value,
      expected.pronunciation?.value,
      reason: '$reason pronunciation',
    );
    expect(
      actual.tags.map((tag) => tag.value).toList(),
      expected.tags.map((tag) => tag.value).toList(),
      reason: '$reason tags',
    );
  }

  final records = <CardTransferRecord>[
    exportRecord(
      front: '사과',
      back: 'quả táo',
      example: '사과를 먹다',
      hint: 'trái cây',
      pronunciation: '[sa.gwa]',
      tags: const <String>['danh từ', '명사'],
    ),
    exportRecord(
      front: 'a,b;c',
      back: 'say "hi", then leave',
      example: 'line1\r\nline2',
      hint: 'a\nb',
      pronunciation: r'back\slash',
      tags: const <String>['has;semi', r'has\slash', r'ends\'],
    ),
    exportRecord(
      front: '001',
      back: '1e3',
      pronunciation: '+84 912 345 678',
      tags: const <String>['số'],
    ),
    exportRecord(front: 'no optional fields', back: 'at all'),
    exportRecord(
      front: '=1+1',
      back: '+plus -minus @at',
      tags: const <String>['formula'],
    ),
  ];

  for (final format in CardTransferFormat.values) {
    test('$format: every field and every tag survives the round trip', () {
      final bytes = cardTransferEncoderFor(format).encode(records);
      final decoded = importBack(bytes, format);

      expect(decoded.length, records.length, reason: 'row count ($format)');
      for (var i = 0; i < records.length; i++) {
        expectSameRecord(decoded[i], records[i], '$format row $i');
      }
    });

    test('$format: a deck of heavily tagged cards still reads back '
        '(BR-176)', () {
      // **The counterexample the five records above cannot reach.** BR-94
      // allows ten tags, and ten tags is nine `;` in the tags cell against the
      // six columns' five delimiters. Delimiter detection counts raw
      // characters, so on a file this app wrote the tags cell can outvote the
      // column structure and the importer stops being able to read its own
      // export — the exact round trip BR-176 exists to guarantee.
      //
      // Every format, not just CSV: TSV and XLSX pin their delimiter and must
      // stay unaffected, which is what makes this a regression test for the
      // detector rather than for the encoders.
      final many = <CardTransferRecord>[
        for (var i = 0; i < 3; i++)
          exportRecord(
            front: 'front $i',
            back: 'back $i',
            tags: <String>[for (var t = 0; t < kMaxTagsPerCard; t++) 'tag$t'],
          ),
      ];

      final bytes = cardTransferEncoderFor(format).encode(many);
      final decoded = importBack(bytes, format);

      expect(decoded.length, many.length, reason: 'row count ($format)');
      for (var i = 0; i < many.length; i++) {
        expectSameRecord(decoded[i], many[i], '$format tagged row $i');
      }
    });

    test('$format: the file carries content only (BR-175)', () {
      final bytes = cardTransferEncoderFor(format).encode(records);
      final document = cardTransferDecoderFor(format).decodeBytes(bytes);

      // Six columns and no more is the structural half of BR-175: there is no
      // column an id, a timestamp or a due date could be hiding in.
      for (final row in document.defaultSheet!.rows) {
        expect(
          row.cells.length,
          lessThanOrEqualTo(6),
          reason: 'row ${row.sourceRowNumber} ($format)',
        );
      }
    });
  }
}
