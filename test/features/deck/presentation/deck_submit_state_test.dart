import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/failures/deck_validation_failure.dart';
import 'package:memox/features/deck/presentation/states/deck_submit_state.dart';

/// The presentation half of the validation flow: it **reads** problems, it does
/// not derive them.
///
/// `deckSubmitFailure` used to take the raw name alongside the failure and run the
/// domain rule again to work out which field to mark. That made presentation a
/// third owner of BR-01, and the two owners could disagree with nothing to catch
/// it. The signature no longer accepts the raw input at all, so re-deriving is not
/// something a future edit can reintroduce by accident.
void main() {
  group('problems come from the failure', () {
    test('a name problem lands on the name field', () {
      final state = deckSubmitFailure(
        const ValidationFailure(
          message: 'diagnostic',
          problems: <Enum>{DeckValidationProblem.nameTooLong},
        ),
      );

      expect(state.nameProblem, DeckValidationProblem.nameTooLong);
      expect(state.isSchedulerMissing, isFalse);
      expect(state.failure, isNull);
    });

    test('the reported problem is the one in the failure, not one re-derived', () {
      // The failure says `nameTooLong`. Nothing in this call could re-derive that
      // — there is no raw input to check — so the state can only be reporting what
      // it was told. This is the case that would have broken if presentation kept
      // its own copy of the rule and the two disagreed.
      final state = deckSubmitFailure(
        const ValidationFailure(
          message: 'diagnostic',
          problems: <Enum>{DeckValidationProblem.nameTooLong},
        ),
      );

      expect(state.nameProblem, isNot(DeckValidationProblem.nameEmpty));
      expect(state.nameProblem, DeckValidationProblem.nameTooLong);
    });

    test('both fields survive one attempt', () {
      final state = deckSubmitFailure(
        const ValidationFailure(
          message: 'diagnostic',
          problems: <Enum>{
            DeckValidationProblem.nameEmpty,
            DeckValidationProblem.schedulerMissing,
          },
        ),
      );

      expect(state.nameProblem, DeckValidationProblem.nameEmpty);
      expect(state.isSchedulerMissing, isTrue);
    });
  });

  group('anything that is not a field problem stays a failure', () {
    test('a non-validation failure is kept whole', () {
      const failure = DatabaseFailure(message: 'disk');

      final state = deckSubmitFailure(failure);

      expect(state.failure, same(failure));
      expect(state.problems, isEmpty);
    });

    test('a validation failure with no Deck problems is kept, not dropped', () {
      // `problems` is `Set<Enum>` in `core/`, so a value from another feature is
      // representable. Keeping the failure means such a case surfaces as an error
      // rather than as an empty form with no explanation.
      final state = deckSubmitFailure(
        const ValidationFailure(
          message: 'diagnostic',
          problems: <Enum>{_ForeignProblem.somethingElse},
        ),
      );

      expect(state.problems, isEmpty);
      expect(state.failure, isA<ValidationFailure>());
    });
  });
}

enum _ForeignProblem { somethingElse }
