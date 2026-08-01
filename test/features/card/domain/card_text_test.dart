import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';

/// BR-07 and BR-08, at the type that owns them.
///
/// These used to live in `test/features/deck/domain/deck_domain_test.dart` —
/// card rules inside deck's tree — because the rule was a static on
/// `CardEntity` and the repository called it a second time on the way in. Two
/// owners of one rule, which is what `CardText`'s private constructor ends: an
/// invalid side cannot be built, so no layer below this one can be handed one.
void main() {
  group('one side', () {
    test('an empty front is refused, keyed to that side', () {
      final parsed = CardText.parse('', side: CardSide.front);

      expect(parsed.text, isNull);
      expect(parsed.problem, CardValidationProblem.frontEmpty);
    });

    test('whitespace-only is empty, and the back reports its own value', () {
      final parsed = CardText.parse(' \n ', side: CardSide.back);

      expect(parsed.text, isNull);
      expect(parsed.problem, CardValidationProblem.backEmpty);
    });

    test('exactly the limit passes, and the value is trimmed', () {
      final text = 'x' * kCardSideMaxLength;
      final parsed = CardText.parse(' $text ', side: CardSide.front);

      expect(parsed.problem, isNull);
      expect(parsed.text?.value, text);
    });

    test('one over the limit is refused, never truncated', () {
      final parsed = CardText.parse(
        'x' * (kCardSideMaxLength + 1),
        side: CardSide.back,
      );

      expect(parsed.text, isNull);
      expect(parsed.problem, CardValidationProblem.backTooLong);
      // The point of reporting rather than truncating: a card silently cut to
      // 2000 characters is content the user believes they saved.
    });

    test('the limit is measured after trimming, not before', () {
      final padded = ' ${'x' * kCardSideMaxLength} ';

      expect(padded.length, greaterThan(kCardSideMaxLength));
      expect(CardText.parse(padded, side: CardSide.front).problem, isNull);
    });

    test('two texts with the same value are the same value object', () {
      final a = CardText.parse('  same  ', side: CardSide.front).text;
      final b = CardText.parse('same', side: CardSide.back).text;

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('both sides at once', () {
    // **The case the old shape could not express.** `CardEntity.validateSide`
    // threw on the first bad side, so a form submitted with two blank fields —
    // the ordinary state of an empty editor — reported one problem, and the
    // user fixed it and submitted again to discover the second.
    test('two blank fields report two problems from one call', () {
      expect(
        () => parseCardSides(rawFront: '', rawBack: '   '),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            <Enum>{
              CardValidationProblem.frontEmpty,
              CardValidationProblem.backEmpty,
            },
          ),
        ),
      );
    });

    test('a mixed pair reports the rule each side broke', () {
      expect(
        () => parseCardSides(
          rawFront: '',
          rawBack: 'x' * (kCardSideMaxLength + 1),
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure f) => f.problems,
            'problems',
            <Enum>{
              CardValidationProblem.frontEmpty,
              CardValidationProblem.backTooLong,
            },
          ),
        ),
      );
    });

    test('a valid pair comes back trimmed, with no failure', () {
      final sides = parseCardSides(rawFront: '  front ', rawBack: ' back  ');

      expect(sides.front.value, 'front');
      expect(sides.back.value, 'back');
    });

    test('the message never carries the card content', () {
      // AD-08: card content is private data and must not reach a log. The
      // message is a diagnostic naming the rules, and the screen renders ARB
      // copy chosen from `problems`.
      const privateContent = 'mitochondria';
      try {
        parseCardSides(rawFront: privateContent, rawBack: '');
        fail('expected a ValidationFailure');
      } on ValidationFailure catch (failure) {
        expect(failure.message, isNot(contains(privateContent)));
        expect(failure.message, contains(CardValidationProblem.backEmpty.name));
      }
    });
  });

  group('the problem sets stay in step with the enum', () {
    test('every problem belongs to exactly one side', () {
      // A fifth problem added without extending a set would leave a screen
      // unable to decide which input to mark.
      for (final CardValidationProblem problem
          in CardValidationProblem.values) {
        final inFront = kCardFrontProblems.contains(problem);
        final inBack = kCardBackProblems.contains(problem);

        expect(
          inFront ^ inBack,
          isTrue,
          reason: '${problem.name} is in neither side set, or in both',
        );
      }
    });

    test('each side produces only its own problems', () {
      for (final CardSide side in CardSide.values) {
        final owned = side == CardSide.front
            ? kCardFrontProblems
            : kCardBackProblems;

        expect(owned, contains(side.emptyProblem));
        expect(owned, contains(side.tooLongProblem));
      }
    });
  });
}
