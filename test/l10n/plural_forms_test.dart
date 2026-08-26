import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every English string that puts a number in front of a countable noun must
/// choose a form for one.
///
/// **The defect this closes.** `{deckCount} decks · {cardCount} cards` shipped
/// on the library header, so a new user with one deck read `1 decks · 0 cards`
/// on the first screen the app ever shows them. Twenty strings were in the same
/// shape — bulk actions, import counts, and every screen-reader label on the
/// deck hero, which announced `1 cards due today`.
///
/// **Why a scan and not twenty more assertions.** The twenty were fixed in one
/// pass; the twenty-first has not been written yet. Asserting each rendered
/// string would document what was fixed, and would say nothing about the next
/// message somebody adds to the ARB. This reads the ARB itself and fails on the
/// shape, so the rule survives the person who wrote it.
///
/// It deliberately does **not** look at Vietnamese: Vietnamese does not inflect
/// for number, so `1 thẻ` and `20 thẻ` are both right and a plural block there
/// would be a single arm dressed as a choice.
void main() {
  /// Nouns whose English plural is the `-s` form, as they appear in the ARB.
  ///
  /// A list rather than a rule, because English is not regular and a heuristic
  /// here would flag `{count} due` and `{percent}% learned`, which are an
  /// adjective and a unit and are correct as they stand.
  const countableNouns = <String>{
    'card',
    'cards',
    'deck',
    'decks',
    'sub-deck',
    'sub-decks',
    'row',
    'rows',
    'day',
    'days',
    'tag',
    'tags',
    'character',
    'characters',
  };

  /// Keys allowed to name a countable noun with no plural form, and why.
  const exempt = <String, String>{
    // `max` is `DeckName.maxLength`, a compile-time constant of 100. A plural
    // here would be a branch that can never be taken.
    'deckNameTooLongError': 'the count is a constant, never 1',
    // `max` is `kMaxTagsPerCard`, a compile-time constant of 10, and the string
    // is only rendered *at* the cap — so the one-arm is unreachable twice over.
    'cardEditorTagCapReached': 'the count is a constant, never 1',
  };

  late final Map<String, dynamic> arb;

  setUpAll(() {
    final file = File('lib/l10n/app_en.arb');
    expect(file.existsSync(), isTrue, reason: 'missing lib/l10n/app_en.arb');
    arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  /// The `int` placeholders declared for [key].
  List<String> intPlaceholders(String key) {
    final meta = arb['@$key'];
    if (meta is! Map<String, dynamic>) return const <String>[];
    final placeholders = meta['placeholders'];
    if (placeholders is! Map<String, dynamic>) return const <String>[];

    return <String>[
      for (final entry in placeholders.entries)
        if (entry.value is Map && (entry.value as Map)['type'] == 'int')
          entry.key,
    ];
  }

  test('a number in front of a countable noun has a form for one', () {
    final offenders = <String>[];

    for (final entry in arb.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key.startsWith('@') || value is! String) continue;
      if (exempt.containsKey(key)) continue;

      for (final placeholder in intPlaceholders(key)) {
        // Already a choice: the message picks its own wording per count.
        if (value.contains('{$placeholder, plural,')) continue;

        // The word the number is standing in front of, if any.
        final match = RegExp(
          '\\{$placeholder\\}\\s+([A-Za-z-]+)',
        ).firstMatch(value);
        final noun = match?.group(1)?.toLowerCase();
        if (noun == null || !countableNouns.contains(noun)) continue;

        offenders.add('$key: "$value"');
        break;
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These read "1 cards" when the count is 1. Give the placeholder a '
          'plural form, or add the key to `exempt` with the reason:\n'
          '${offenders.join('\n')}',
    );
  });

  test('the exemptions still exist, so the list cannot rot', () {
    for (final key in exempt.keys) {
      expect(
        arb.containsKey(key),
        isTrue,
        reason: '$key is exempt from the plural rule but no longer exists',
      );
    }
  });
}
