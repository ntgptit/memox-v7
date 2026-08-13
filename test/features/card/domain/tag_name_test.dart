import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';

/// BR-93 — a tag name that cannot be constructed invalid, and the fold that
/// makes its uniqueness mean what the rule says.
void main() {
  group('parse (BR-93)', () {
    test('trims once, and the trimmed value is what persists', () {
      final parsed = TagName.parse('  noun  ');

      expect(parsed.problem, isNull);
      expect(parsed.name?.value, 'noun');
    });

    test('empty and whitespace-only are the same refusal', () {
      for (final raw in <String>['', '   ', '\n\t ']) {
        expect(
          TagName.parse(raw).problem,
          TagValidationProblem.nameEmpty,
          reason: 'input ${raw.codeUnits}',
        );
      }
    });

    test('an interior control character is refused (BR-93)', () {
      // **The invariant the tag queries already depended on.** `cardListItems`
      // and `exportCardsInDeck` both concatenate a card's tag names with
      // `char(31)` and split them apart in Dart, on the stated grounds that a
      // name can never hold one. Nothing enforced it: `trim` does not touch
      // U+001F, so a name carrying one used to parse cleanly, reach the
      // database, and come back out as two tags — or, when it sat at the end,
      // as an empty piece that failed the export whole.
      for (final raw in <String>[
        'a\u{1F}b', // the unit separator both tag queries join with
        'a\u{0}b',
        'a\u{7F}b',
        'a\u{A}b', // interior, so trim never reaches it
      ]) {
        expect(
          TagName.parse(raw).problem,
          TagValidationProblem.nameHasControlCharacter,
          reason: 'input ${raw.codeUnits}',
        );
      }
    });

    test('a name padded with control whitespace is cleaned, not refused', () {
      // Trim runs first, so the rule above bites on interior characters only —
      // a tag pasted with a trailing newline is still an ordinary tag.
      final parsed = TagName.parse('\t noun \n');

      expect(parsed.problem, isNull);
      expect(parsed.name?.value, 'noun');
    });

    test('exactly the limit passes, one over is refused', () {
      final atLimit = 'x' * TagName.maxLength;

      expect(TagName.parse(atLimit).problem, isNull);
      expect(
        TagName.parse('$atLimit!').problem,
        TagValidationProblem.nameTooLong,
      );
    });

    test('the limit is measured after trimming, not before', () {
      final padded = ' ${'x' * TagName.maxLength} ';

      expect(padded.length, greaterThan(TagName.maxLength));
      expect(TagName.parse(padded).problem, isNull);
    });

    test('a refused name yields no value at all', () {
      // Never truncated: a tag cut to 50 characters is a tag the user did not
      // create, and it would be indistinguishable from one they did.
      expect(TagName.parse('x' * 51).name, isNull);
    });
  });

  group('folding is what uniqueness compares (BR-93)', () {
    test('case alone does not make a different tag', () {
      final a = TagName.parse('Noun').name!;
      final b = TagName.parse('noun').name!;

      expect(a.collidesWith(b), isTrue);
      expect(a, b, reason: 'equality follows the fold, not the spelling');
    });

    test('the spelling the user typed is kept, not the fold', () {
      // The chip renders what they wrote; only the comparison is folded.
      final parsed = TagName.parse('TOPIK II').name!;

      expect(parsed.value, 'TOPIK II');
      expect(parsed.folded, 'topik ii');
    });

    test('Vietnamese diacritics fold — the case SQLite NOCASE gets wrong', () {
      // This is the whole reason `name_folded` is a stored column. SQLite's
      // NOCASE collation folds ASCII only, so `Động từ` and `động từ` compare
      // as different under it and both would be inserted.
      final upper = TagName.parse('Động từ').name!;
      final lower = TagName.parse('động từ').name!;

      expect(upper.collidesWith(lower), isTrue);
      expect(upper.folded, lower.folded);
      expect(
        upper.folded,
        'động từ',
        reason: 'the fold lowercases without stripping the diacritics',
      );
    });

    test('two genuinely different names do not collide', () {
      final a = TagName.parse('noun').name!;
      final b = TagName.parse('nouns').name!;

      expect(a.collidesWith(b), isFalse);
      expect(a, isNot(b));
    });

    test('names that differ only by surrounding space are the same tag', () {
      final a = TagName.parse('noun').name!;
      final b = TagName.parse('  NOUN ').name!;

      expect(a.collidesWith(b), isTrue);
    });
  });

  test('the two limits are the ones the rules state', () {
    // Pinned so that changing a rule's number without changing the rule is
    // caught here rather than in a screen.
    expect(kTagNameMaxLength, 50);
    expect(kMaxTagsPerCard, 10);
  });
}
