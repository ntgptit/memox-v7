import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/failures/deck_validation_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';

/// BR-01, where it now lives — and the fact that it lives in exactly one place.
///
/// The rule used to be `DeckEntity.nameProblem` plus `DeckEntity.validateName`,
/// and for one submit it was evaluated three times: the use case called it, the
/// repository called `validateName` again, and the screen re-derived the problem
/// from the raw input to work out which field to mark. Three owners, free to
/// disagree, while the documentation said there was one.
///
/// `DeckName` is now the only implementation. These tests are the rule's tests; no
/// other layer has any to duplicate.
void main() {
  group('the rule', () {
    test('an empty name is refused', () {
      expect(DeckName.parse('').problem, DeckValidationProblem.nameEmpty);
      expect(DeckName.parse('').name, isNull);
    });

    test('a whitespace-only name is refused', () {
      // The trim is what makes this empty, and the trim happens here.
      expect(
        DeckName.parse('   \t \n ').problem,
        DeckValidationProblem.nameEmpty,
      );
    });

    test('exactly the limit passes', () {
      final parsed = DeckName.parse('x' * DeckName.maxLength);

      expect(parsed.problem, isNull);
      expect(parsed.name?.value.length, DeckName.maxLength);
    });

    test('one over the limit is refused, never truncated', () {
      final parsed = DeckName.parse('x' * (DeckName.maxLength + 1));

      expect(parsed.problem, DeckValidationProblem.nameTooLong);
      // The absence of a `name` is the guarantee: there is no truncated value for
      // a caller to persist by accident.
      expect(parsed.name, isNull);
    });

    test('the limit is measured after trimming, not before', () {
      // 200 characters of content with padding either side is a *valid* name,
      // and would be over the limit if the check ran on the raw string.
      final parsed = DeckName.parse('  ${'x' * DeckName.maxLength}  ');

      expect(parsed.problem, isNull);
      expect(parsed.name?.value.length, DeckName.maxLength);
    });
  });

  group('normalisation happens once, here', () {
    test('the parsed value is trimmed', () {
      expect(DeckName.parse('  My deck  ').name?.value, 'My deck');
    });

    test('inner whitespace is left alone', () {
      // Trim, not collapse. BR-01 says nothing about interior spacing, and
      // rewriting what the user typed is not this type's business.
      expect(DeckName.parse('  My   deck  ').name?.value, 'My   deck');
    });

    test('parsing an already-parsed value changes nothing', () {
      // The property that makes a second trim harmless *and* pointless: no layer
      // downstream needs to know whether normalisation already ran.
      final once = DeckName.parse('  My deck  ').name!;
      final twice = DeckName.parse(once.value).name!;

      expect(twice, once);
      expect(twice.value, 'My deck');
    });
  });

  group('value semantics', () {
    test('two names with the same text are equal', () {
      expect(DeckName.parse('a').name, DeckName.parse('  a  ').name);
      expect(
        DeckName.parse('a').name.hashCode,
        DeckName.parse('  a  ').name.hashCode,
      );
    });

    test('different text is not equal', () {
      expect(DeckName.parse('a').name, isNot(DeckName.parse('b').name));
    });
  });
}
