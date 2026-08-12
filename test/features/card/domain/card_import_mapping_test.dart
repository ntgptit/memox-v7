import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_transfer_field_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_mapping_model.dart';

/// The mapping rules of BR-169 that live in the type itself: required fields,
/// single-owner destinations, and the auto-map contract.
void main() {
  group('auto-map from a header row', () {
    test('matches the six names case-insensitively', () {
      final mapping = CardTransferMapping.fromHeader(const <String>[
        'FRONT',
        'Back',
        'example',
        'Hint',
        'PRONUNCIATION',
        'tags',
      ]);

      expect(mapping.columnOf(CardTransferField.front), 0);
      expect(mapping.columnOf(CardTransferField.back), 1);
      expect(mapping.columnOf(CardTransferField.example), 2);
      expect(mapping.columnOf(CardTransferField.hint), 3);
      expect(mapping.columnOf(CardTransferField.pronunciation), 4);
      expect(mapping.columnOf(CardTransferField.tags), 5);
      expect(mapping.isComplete, isTrue);
    });

    test('known aliases auto-map, and an unknown header maps nothing', () {
      // "term"/"meaning" name their field unambiguously, so auto-map takes
      // them (UC-10 step 4); a spelling no field clearly owns stays unmapped
      // for the user to decide.
      final mapping = CardTransferMapping.fromHeader(const <String>[
        'term',
        'meaning',
        'notes',
      ]);

      expect(mapping.fieldOf(0), CardTransferField.front);
      expect(mapping.fieldOf(1), CardTransferField.back);
      expect(mapping.fieldOf(2), isNull);
      expect(mapping.isComplete, isTrue);
    });

    test('a duplicated header name maps its first column only', () {
      final mapping = CardTransferMapping.fromHeader(const <String>[
        'front',
        'front',
        'back',
      ]);

      expect(mapping.columnOf(CardTransferField.front), 0);
      expect(mapping.fieldOf(1), isNull);
    });
  });

  group('assign', () {
    test('taking a field from another column keeps one owner (BR-169)', () {
      final mapping = CardTransferMapping.fromHeader(const <String>[
        'front',
        'back',
      ]).assign(1, CardTransferField.front);

      // Column 1 now owns front; column 0 lost it — a destination can never
      // be represented twice, so no validator has to look for the state.
      expect(mapping.columnOf(CardTransferField.front), 1);
      expect(mapping.fieldOf(0), isNull);
      expect(mapping.columnOf(CardTransferField.back), isNull);
      expect(mapping.isComplete, isFalse);
    });

    test('null means Ignore and clears the column', () {
      final mapping = CardTransferMapping.fromHeader(const <String>[
        'front',
        'back',
      ]).assign(0, null);

      expect(mapping.fieldOf(0), isNull);
      expect(mapping.columnOf(CardTransferField.front), isNull);
      expect(mapping.isComplete, isFalse);
    });

    test('isComplete needs both required fields, not just one', () {
      const empty = CardTransferMapping.empty();
      expect(empty.isComplete, isFalse);

      final frontOnly = empty.assign(0, CardTransferField.front);
      expect(frontOnly.isComplete, isFalse);

      final both = frontOnly.assign(1, CardTransferField.back);
      expect(both.isComplete, isTrue);
    });
  });
}
