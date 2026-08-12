import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_transfer_mapping_model.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_document_model.dart';
import 'package:memox/features/card/domain/usecases/build_card_import_preview_use_case.dart';

/// BR-169 and BR-170 applied to rows — pure classification, no repository.
void main() {
  CardTransferSheet sheet(List<List<String>> rows) => CardTransferSheet(
    name: '',
    rows: <CardTransferRow>[
      for (var i = 0; i < rows.length; i++)
        CardTransferRow(sourceRowNumber: i + 1, cells: rows[i]),
    ],
  );

  final mapping = CardTransferMapping.fromHeader(const <String>[
    'front',
    'back',
    'tags',
    'hint',
  ]);

  CardImportPreview classify(
    List<List<String>> rows, {
    Set<CardImportDuplicateKey> existing = const <CardImportDuplicateKey>{},
    bool hasHeader = true,
  }) => classifyImportRows(
    sheet: sheet(rows),
    mapping: mapping,
    hasHeaderRow: hasHeader,
    existingKeys: existing,
  );

  const header = <String>['front', 'back', 'tags', 'hint'];

  group('required fields (BR-169)', () {
    test('a full row is ready; only-front and only-back are invalid', () {
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', '', ''],
        <String>['배', '', '', ''],
        <String>['', 'pear', '', ''],
      ]);

      expect(preview.readyCount, 1);
      expect(preview.invalidCount, 2);
      expect(
        preview.rows[1].cardProblems,
        contains(CardValidationProblem.backEmpty),
      );
      expect(
        preview.rows[2].cardProblems,
        contains(CardValidationProblem.frontEmpty),
      );
    });

    test('a wholly blank row is skipped, not an error', () {
      final preview = classify(<List<String>>[
        header,
        <String>['', '', '', ''],
        <String>['사과', 'apple', '', ''],
      ]);

      expect(preview.blankCount, 1);
      expect(preview.invalidCount, 0);
      expect(preview.rows.first.status, CardImportRowStatus.blank);
    });

    test('a front without Hangul is not rejected for it', () {
      // Loanwords, numbers and symbols are legal fronts (BR-169): content
      // guidance is not a validation rule.
      final preview = classify(<List<String>>[
        header,
        <String>['OK', 'okay', '', ''],
        <String>['42', 'forty-two', '', ''],
      ]);

      expect(preview.readyCount, 2);
    });

    test('a short row reads missing cells as empty instead of crashing', () {
      // Inconsistent column count: the row has fewer cells than the mapping
      // expects, and the verdict is missingBack — not a range error.
      final preview = classify(<List<String>>[
        header,
        <String>['사과'],
      ]);

      expect(preview.invalidCount, 1);
      expect(
        preview.rows.single.cardProblems,
        contains(CardValidationProblem.backEmpty),
      );
    });

    test('details go through their value objects: an over-long hint refuses '
        'the row', () {
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', '', 'h' * 2100],
      ]);

      expect(preview.invalidCount, 1);
      expect(
        preview.rows.single.cardProblems,
        contains(CardValidationProblem.hintTooLong),
      );
    });

    test('the header row itself is data when hasHeader is off', () {
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', '', ''],
      ], hasHeader: false);

      // "front"/"back" parse as a legal card — the toggle only decides
      // whether row 1 is data (UC-10 A3).
      expect(preview.totalRows, 2);
      expect(preview.readyCount, 2);
    });
  });

  group('tags cell (BR-169, BR-93, BR-94)', () {
    test('splits on semicolons, trims, folds duplicates', () {
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', 'Fruit; food ;FRUIT;; ', ''],
      ]);

      final entry = preview.records.single;
      expect(entry.tags.map((t) => t.value), <String>['Fruit', 'food']);
    });

    test('an eleventh distinct tag refuses the row', () {
      final tags = List<String>.generate(11, (i) => 'tag$i').join(';');
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', tags, ''],
      ]);

      expect(preview.invalidCount, 1);
      expect(
        preview.rows.single.tagProblems,
        contains(TagValidationProblem.tooManyTags),
      );
    });

    test('a comma does not split tags — it is CSV territory', () {
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', 'red, sweet', ''],
      ]);

      // One tag whose value contains the comma, not two.
      expect(preview.records.single.tags, hasLength(1));
    });
  });

  group('duplicates (BR-170)', () {
    test('a folded collision with the deck marks duplicateExisting', () {
      final key = cardImportDuplicateKey(
        frontFolded: '사과',
        backFolded: 'apple',
      );
      final preview = classify(
        <List<String>>[
          header,
          <String>['사과', 'APPLE', '', ''],
        ],
        existing: <CardImportDuplicateKey>{key},
      );

      expect(preview.rows.single.status, CardImportRowStatus.duplicateExisting);
      expect(preview.duplicateCount, 1);
      // Duplicates stay in the record list: the commit applies the policy
      // against the database as it stands then, not this snapshot.
      expect(preview.records, hasLength(1));
    });

    test('a repeat within the file marks the later row only', () {
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', '', ''],
        <String>['사과', 'Apple', '', ''],
      ]);

      expect(preview.rows[0].status, CardImportRowStatus.ready);
      expect(preview.rows[1].status, CardImportRowStatus.duplicateInFile);
    });

    test('importableCount follows the include-duplicates policy', () {
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', '', ''],
        <String>['사과', 'apple', '', ''],
        <String>['배', 'pear', '', ''],
      ]);

      expect(preview.importableCount(shouldIncludeDuplicates: false), 2);
      expect(preview.importableCount(shouldIncludeDuplicates: true), 3);
    });

    test('a card in another deck is not a duplicate here', () {
      // The existing-keys set is *scoped to the target deck* by the
      // repository read; classification sees only those, so an other-deck
      // collision never reaches it. An empty set is that case.
      final preview = classify(<List<String>>[
        header,
        <String>['사과', 'apple', '', ''],
      ]);

      expect(preview.rows.single.status, CardImportRowStatus.ready);
    });
  });
}
