import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/core/state/submit_state.dart';

/// The shared submit state, tested where it lives rather than only through a
/// feature.
///
/// These three getters are the success policy, and the policy has been wrong
/// once: `canSubmit` was `!isSubmitting && !isDone`, which latched shut on any
/// success and would have let an *add another* form accept exactly one entry.
/// Testing it through Deck only would leave the second feature relying on a
/// property nothing asserts at the level it is shared.
enum _TestProblem { nameEmpty, nameTooLong, schedulerMissing }

typedef _State = SubmitState<_TestProblem>;

void main() {
  const Set<_TestProblem> nameProblems = <_TestProblem>{
    _TestProblem.nameEmpty,
    _TestProblem.nameTooLong,
  };

  group('the idle state', () {
    test('has no problems, no failure and no outcome', () {
      const state = _State();

      expect(state.problems, isEmpty);
      expect(state.failure, isNull);
      expect(state.outcome, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.hasProblem, isFalse);
    });

    test('accepts a submit', () {
      expect(const _State().canSubmit, isTrue);
    });
  });

  group('canSubmit — the double-submit guard', () {
    test('is false while a write is in flight', () {
      expect(const _State(isSubmitting: true).canSubmit, isFalse);
    });

    test('latches false after savedAndClose', () {
      // The form is on its way out; a second tap must not write again.
      expect(
        const _State(outcome: SubmitOutcome.savedAndClose).canSubmit,
        isFalse,
      );
    });

    test('stays TRUE after savedAndContinue', () {
      // The whole reason the outcome is an enum. An add-another editor is still
      // open and the next entry must be submittable with nothing having called
      // reset first — the bug the boolean version produced.
      expect(
        const _State(outcome: SubmitOutcome.savedAndContinue).canSubmit,
        isTrue,
      );
    });

    test('stays true after a failure, so it can be retried', () {
      expect(
        const _State(failure: DatabaseFailure(message: 'disk')).canSubmit,
        isTrue,
      );
    });

    test('stays true after a field problem, so it can be corrected', () {
      expect(
        const _State(
          problems: <_TestProblem>{_TestProblem.nameEmpty},
        ).canSubmit,
        isTrue,
      );
    });
  });

  group('the two success transitions are distinguishable', () {
    test('savedAndClose closes and does not clear', () {
      const state = _State(outcome: SubmitOutcome.savedAndClose);

      expect(state.shouldClose, isTrue);
      expect(state.shouldClearDraft, isFalse);
    });

    test('savedAndContinue clears and does not close', () {
      const state = _State(outcome: SubmitOutcome.savedAndContinue);

      expect(state.shouldClose, isFalse);
      expect(state.shouldClearDraft, isTrue);
    });

    test('a failure fires neither, so the draft survives', () {
      const state = _State(failure: DatabaseFailure(message: 'disk'));

      expect(state.shouldClose, isFalse);
      expect(state.shouldClearDraft, isFalse);
    });
  });

  group('problems', () {
    test('several can be present at once', () {
      // The reason this is a Set and not one nullable field. A create-root form
      // with a blank name and no scheduler chosen must mark both; marking
      // whichever check ran first sends the user round twice.
      const state = _State(
        problems: <_TestProblem>{
          _TestProblem.nameEmpty,
          _TestProblem.schedulerMissing,
        },
      );

      expect(state.hasProblem, isTrue);
      expect(state.problems, hasLength(2));
    });

    test('firstProblemOf answers per field', () {
      const state = _State(
        problems: <_TestProblem>{
          _TestProblem.nameTooLong,
          _TestProblem.schedulerMissing,
        },
      );

      expect(state.firstProblemOf(nameProblems), _TestProblem.nameTooLong);
    });

    test('firstProblemOf is null when the field is fine', () {
      // A form whose *other* field is wrong must not show an error under this
      // one — the case a plain `problems.isNotEmpty` check would get wrong.
      const state = _State(
        problems: <_TestProblem>{_TestProblem.schedulerMissing},
      );

      expect(state.firstProblemOf(nameProblems), isNull);
    });
  });

  group('equality', () {
    test('compares the problem set by value, not by identity', () {
      // Load-bearing rather than academic: a widget detects the success
      // transition by comparing the old state with the new one. With identity
      // equality on the Set, every rebuild would look like a change and the
      // close-or-clear side effect would fire repeatedly.
      const a = _State(
        problems: <_TestProblem>{
          _TestProblem.nameEmpty,
          _TestProblem.schedulerMissing,
        },
      );
      // Built through a local so the construction is genuinely not `const`. Two
      // `const` instances would be canonicalized to the same object and the
      // assertion below would pass without comparing anything.
      final problems = <_TestProblem>{}
        ..add(_TestProblem.nameEmpty)
        ..add(_TestProblem.schedulerMissing);
      final b = _State(problems: problems);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different problem set is a different state', () {
      const a = _State(problems: <_TestProblem>{_TestProblem.nameEmpty});
      const b = _State(problems: <_TestProblem>{_TestProblem.nameTooLong});

      expect(a, isNot(b));
    });
  });
}
