import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_export_file_name_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';

/// BR-180: the name is derived, sanitized, dated from an injected clock, and
/// never typed by the user.
void main() {
  test('the cap never splits a surrogate pair (BR-180)', () {
    // A deck named with emoji, arranged so the 60-code-unit cut lands between
    // the two halves of one. Cutting there used to leave a lone surrogate —
    // not a character, not encodable as UTF-8, and handed straight to the
    // platform channel that names the shared file.
    final name = '${'a' * 59}🍎🍎🍎';

    final sanitized = sanitizeCardExportName(name);

    expect(sanitized.length, 59, reason: 'the cut backed off the pair');
    expect(
      sanitized.codeUnits.every((int unit) => unit < 0xD800 || unit > 0xDBFF),
      isTrue,
      reason: 'no unpaired high surrogate survives',
    );
    // Round-tripping through UTF-8 is what a platform channel does, and a lone
    // surrogate does not survive it intact.
    expect(utf8.decode(utf8.encode(sanitized)), sanitized);
  });

  test('an even cut keeps whole emoji', () {
    final name = '${'a' * 58}🍎🍎';

    final sanitized = sanitizeCardExportName(name);

    expect(sanitized.length, 60);
    expect(sanitized.endsWith('🍎'), isTrue);
  });

  // Fixed on purpose — a name that changes with the wall clock is a test that
  // fails at midnight and passes on a rerun.
  final date = DateTime.utc(2026, 8, 13, 6, 30);

  String nameFor(
    String deckName, {
    CardTransferFormat format = CardTransferFormat.csv,
  }) => cardExportFileName(deckName: deckName, format: format, date: date);

  test('an ordinary deck name keeps its spelling, plus date and extension', () {
    expect(nameFor('Korean Verbs'), 'Korean Verbs_2026-08-13.csv');
    expect(nameFor('Từ vựng N3'), 'Từ vựng N3_2026-08-13.csv');
  });

  test('one extension per format', () {
    expect(nameFor('Deck'), endsWith('.csv'));
    expect(nameFor('Deck', format: CardTransferFormat.tsv), endsWith('.tsv'));
    expect(nameFor('Deck', format: CardTransferFormat.xlsx), endsWith('.xlsx'));
  });

  test('the date comes from the argument, never the wall clock', () {
    expect(
      cardExportFileName(
        deckName: 'Deck',
        format: CardTransferFormat.csv,
        date: DateTime.utc(2001, 2, 3),
      ),
      'Deck_2001-02-03.csv',
    );
  });

  group('sanitize (BR-180)', () {
    test('path separators are removed, never turned into folders', () {
      expect(sanitizeCardExportName('a/b'), 'ab');
      expect(sanitizeCardExportName(r'a\b'), 'ab');
      expect(sanitizeCardExportName('../../etc/passwd'), 'etcpasswd');
      expect(nameFor('../secrets'), isNot(contains('/')));
    });

    test('control characters are removed', () {
      expect(sanitizeCardExportName('a\u0001b\u007Fc'), 'abc');
      expect(sanitizeCardExportName('line\nbreak'), 'line break');
    });

    test('filesystem-invalid characters are removed', () {
      expect(sanitizeCardExportName('a:b*c?d"e<f>g|h'), 'abcdefgh');
    });

    test('whitespace runs collapse and the edges are trimmed', () {
      expect(sanitizeCardExportName('  a   b  '), 'a b');
      expect(sanitizeCardExportName('a\t\t b'), 'a b');
    });

    test('leading and trailing dots go, so the file is never hidden', () {
      expect(sanitizeCardExportName('...deck...'), 'deck');
      expect(sanitizeCardExportName('..'), kCardExportFallbackName);
    });

    test('a name that sanitizes to nothing falls back to "cards"', () {
      expect(sanitizeCardExportName('///'), kCardExportFallbackName);
      expect(sanitizeCardExportName('   '), kCardExportFallbackName);
      expect(sanitizeCardExportName(''), kCardExportFallbackName);
      expect(nameFor(r'<>:"|?*/\'), 'cards_2026-08-13.csv');
    });

    test('a long name is capped and leaves no trailing space', () {
      final long = 'Korean vocabulary ' * 20;
      final sanitized = sanitizeCardExportName(long);

      expect(sanitized.length, kCardExportNameMaxLength);
      expect(sanitized.trim(), sanitized);
      expect(nameFor(long), endsWith('_2026-08-13.csv'));
    });

    test('a long name of a single word is still capped', () {
      final sanitized = sanitizeCardExportName('명사' * 100);

      expect(sanitized.length, kCardExportNameMaxLength);
    });
  });
}
