import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/data/mappers/study_config_mapper.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';
import 'package:memox/features/study/domain/usecases/save_study_options_use_case.dart';

import 'support/fake_study_repository.dart';

/// The two study options, their bounds, and the config that must never block
/// studying (BR-147, BR-148).
void main() {
  group('the card limit type', () {
    test('rejects what is not a number at all', () {
      // The field is text, so this is a real input rather than a defensive
      // check — and leaving it to the caller would put a third of the rule
      // outside the type.
      expect(
        StudyCardLimit.parse('twenty').problem,
        StudyCardLimitProblem.notANumber,
      );
      expect(StudyCardLimit.parse('').problem, isNotNull);
    });

    test('rejects both ends of the range', () {
      expect(StudyCardLimit.parse('0').problem, StudyCardLimitProblem.tooSmall);
      expect(
        StudyCardLimit.parse('${kMaxCardLimit + 1}').problem,
        StudyCardLimitProblem.tooLarge,
      );
    });

    test('accepts the bounds themselves and trims', () {
      expect(StudyCardLimit.parse(' 1 ').limit?.value, kMinCardLimit);
      expect(
        StudyCardLimit.parse('$kMaxCardLimit').limit?.value,
        kMaxCardLimit,
      );
    });

    test('a stored value out of range is clamped, not refused', () {
      // A preference that somehow landed out of range is not a reason to refuse
      // to study; the clamp is visible the moment the settings screen opens.
      expect(StudyCardLimit.fromStored(0).value, kMinCardLimit);
      expect(StudyCardLimit.fromStored(10000).value, kMaxCardLimit);
    });
  });

  group('reading study_config', () {
    test('a complete override is read back whole', () {
      final json = studyOptionsOverrideToJson(
        cardLimit: 30,
        newCardOrder: NewCardOrder.random,
      );

      final override = studyOptionsOverrideFromJson(json);

      expect(override.cardLimit, 30);
      expect(override.newCardOrder, NewCardOrder.random);
    });

    test('a partial override leaves the other field to the default', () {
      // Absent means "not overridden", never "overridden to nothing" — the two
      // would be the same value and mean opposite things.
      final override = studyOptionsOverrideFromJson(
        jsonEncode(<String, Object>{kStudyConfigCardLimit: 5}),
      );

      expect(override.cardLimit, 5);
      expect(override.newCardOrder, isNull);
    });

    for (final broken in <String>[
      'not json at all',
      '[]',
      '"a string"',
      '{"card_limit": "thirty"}',
    ]) {
      test('a config that reads as `$broken` falls back to defaults', () {
        // BR-147 has no failure mode: a malformed preference must never be the
        // reason a deck cannot be opened. Every one of these degrades to
        // exactly what a deck with no override already gets.
        expect(studyOptionsOverrideFromJson(broken), kNoStudyOptionsOverride);
      });
    }

    test('an unknown ordering degrades to the default, not to null', () {
      // `NewCardOrder.fromDbValue` is deliberately tolerant: the worst case is
      // cards arriving in the order the user did not pick.
      final override = studyOptionsOverrideFromJson(
        jsonEncode(<String, Object>{kStudyConfigNewCardOrder: 'alphabetical'}),
      );

      expect(override.newCardOrder, NewCardOrder.created);
    });
  });

  group('saving', () {
    test('a valid limit reaches the repository as a parsed type', () async {
      final repository = FakeStudyRepository();

      await SaveStudyOptionsUseCase(repository).call(
        deckId: 'deck-1',
        rawCardLimit: '30',
        newCardOrder: NewCardOrder.random,
      );

      expect(repository.savedOptions.single.cardLimit, 30);
      expect(repository.savedOptions.single.order, NewCardOrder.random);
    });

    test('an invalid limit is refused before any write', () async {
      // The write must not happen at all: a partial save would leave the order
      // changed and the limit not, which is neither of the two things the user
      // asked for.
      final repository = FakeStudyRepository();

      await expectLater(
        SaveStudyOptionsUseCase(repository).call(
          deckId: 'deck-1',
          rawCardLimit: '0',
          newCardOrder: NewCardOrder.random,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (failure) => failure.problems,
            'problems',
            contains(StudyCardLimitProblem.tooSmall),
          ),
        ),
      );
      expect(repository.savedOptions, isEmpty);
    });
  });
}
