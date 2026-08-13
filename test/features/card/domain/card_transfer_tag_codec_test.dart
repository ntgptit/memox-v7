import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_document_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_mapping_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_tag_codec_model.dart';
import 'package:memox/features/card/domain/usecases/build_card_import_preview_use_case.dart';

/// BR-176: one tags codec, both directions, and legacy cells still decode the
/// way they always did.
void main() {
  group('encode', () {
    test('joins on ";" and escapes ";" and "\\" inside a tag', () {
      expect(CardTransferTagCodec.encode(const <String>['a', 'b']), 'a;b');
      expect(CardTransferTagCodec.encode(const <String>['a;b']), r'a\;b');
      expect(CardTransferTagCodec.encode(const <String>[r'a\b']), r'a\\b');
      expect(CardTransferTagCodec.encode(const <String>[r'a\;b']), r'a\\\;b');
    });

    test('an empty list is an empty cell, not a placeholder (BR-179)', () {
      expect(CardTransferTagCodec.encode(const <String>[]), '');
    });

    test('a trailing backslash is escaped, so it cannot eat the separator', () {
      expect(
        CardTransferTagCodec.encode(const <String>[r'ends\', 'next']),
        r'ends\\;next',
      );
    });
  });

  group('decode', () {
    test('unescapes only before ";" and "\\"', () {
      expect(CardTransferTagCodec.decode(r'a\;b'), <String>['a;b']);
      expect(CardTransferTagCodec.decode(r'a\\b'), <String>[r'a\b']);
      expect(CardTransferTagCodec.decode(r'a\\\;b'), <String>[r'a\;b']);
    });

    test('a backslash before an ordinary character survives verbatim', () {
      // The legacy case: nothing written before this codec escaped anything,
      // so `C:\path` is content and not a broken escape.
      expect(CardTransferTagCodec.decode(r'C:\path'), <String>[r'C:\path']);
      expect(CardTransferTagCodec.decode(r'a\b;c'), <String>[r'a\b', 'c']);
    });

    test('a trailing backslash survives verbatim', () {
      expect(CardTransferTagCodec.decode(r'ends\'), <String>[r'ends\']);
      expect(CardTransferTagCodec.decode(r'a;ends\'), <String>['a', r'ends\']);
    });

    test('empty pieces are spacing, not tags', () {
      expect(CardTransferTagCodec.decode(''), isEmpty);
      expect(CardTransferTagCodec.decode(';;'), isEmpty);
      expect(CardTransferTagCodec.decode('a;;b;'), <String>['a', 'b']);
      expect(CardTransferTagCodec.decode(';a'), <String>['a']);
    });

    test('whitespace-only pieces are kept for the caller to judge', () {
      // The import path skips them after trimming; the codec does not decide
      // what a blank-looking tag means.
      expect(CardTransferTagCodec.decode('a; ;b'), <String>['a', ' ', 'b']);
    });
  });

  test('round-trips every awkward name (BR-176)', () {
    const awkward = <String>[
      'plain',
      'has;semicolon',
      r'has\backslash',
      r'both\;together',
      r'ends\',
      r'\starts',
      ';;;',
      r'\\\\',
      'danh từ',
      '동사',
      'with space',
      'a;b;c',
    ];

    // The whole list at once, then each name alone — a codec can be right
    // about one tag and wrong about where the next one begins.
    expect(CardTransferTagCodec.decode(CardTransferTagCodec.encode(awkward)), [
      ...awkward,
    ]);
    for (final name in awkward) {
      expect(
        CardTransferTagCodec.decode(
          CardTransferTagCodec.encode(<String>[name]),
        ),
        <String>[name],
        reason: name,
      );
    }
  });

  group('the import path uses the codec (BR-176)', () {
    final mapping = CardTransferMapping.fromHeader(const <String>[
      'front',
      'back',
      'tags',
    ]);

    List<String> tagsOf(String cell) {
      final preview = classifyImportRows(
        sheet: CardTransferSheet(
          name: '',
          rows: <CardTransferRow>[
            const CardTransferRow(
              sourceRowNumber: 1,
              cells: <String>['front', 'back', 'tags'],
            ),
            CardTransferRow(
              sourceRowNumber: 2,
              cells: <String>['사과', 'apple', cell],
            ),
          ],
        ),
        mapping: mapping,
        hasHeaderRow: true,
        existingKeys: const <CardImportDuplicateKey>{},
      );

      expect(preview.readyCount, 1, reason: cell);

      return preview.records.single.tags.map((tag) => tag.value).toList();
    }

    test('a legacy plain cell decodes exactly as before', () {
      expect(tagsOf('noun;verb'), <String>['noun', 'verb']);
      expect(tagsOf('noun; verb ;;'), <String>['noun', 'verb']);
    });

    test('a legacy cell with a stray backslash keeps it', () {
      expect(tagsOf(r'C:\path;verb'), <String>[r'C:\path', 'verb']);
      expect(tagsOf(r'trailing\'), <String>[r'trailing\']);
    });

    test('an escaped separator is now one tag, not two', () {
      expect(tagsOf(r'a\;b'), <String>['a;b']);
      expect(tagsOf(r'a\\;b'), <String>[r'a\', 'b']);
    });
  });
}
