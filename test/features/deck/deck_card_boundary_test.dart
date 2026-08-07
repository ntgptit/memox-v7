import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Deck/Card boundary introduced in M4.9a and completed in M4.9b, pinned
/// as source facts so a convenience method cannot quietly re-merge the two
/// responsibilities.
///
/// Complements the guard: these are cross-file claims ("this contract does
/// not mention that operation") that a per-file regex rule cannot own.
///
/// **Comments are stripped before matching.** These checks look for text in
/// source, and prose is source too — a doc comment that explains why a file is
/// *not* `part of` something contained the words `part of` and failed the check
/// that the file is not a part. That is not a hypothetical; it happened, and it is
/// the same defect class as a guard that passes because it scanned nothing: what
/// the check measures has to be the code.
///
/// String literals are **not** stripped. Doing that correctly means most of a
/// lexer, and no check here is plausibly tripped by one — the claim this file
/// makes is "no comment can fake or break these", not "nothing can".
void main() {
  /// Source with its comments removed: `//` to end of line, `--` to end of line
  /// for `.drift`, and `/* … */` however many lines it spans.
  String read(String path) {
    final source = File(path).readAsStringSync();
    final lineComment = path.endsWith('.drift') ? r'(?://|--)' : '//';

    return source
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .replaceAll(RegExp('$lineComment.*'), '');
  }

  const cardOperations = <String>[
    'watchCardsByDeck',
    'createCard',
    'updateCard',
    'deleteCard',
  ];

  test('DeckRepository exposes no card CRUD', () {
    final contract = read(
      'lib/features/deck/domain/repositories/deck_repository.dart',
    );

    for (final operation in cardOperations) {
      expect(
        contract,
        isNot(contains('$operation(')),
        reason: 'DeckRepository must not declare $operation',
      );
    }
  });

  test('CardRepository owns exactly the card operations', () {
    final contract = read(
      'lib/features/card/domain/repositories/card_repository.dart',
    );

    for (final operation in cardOperations) {
      expect(contract, contains('$operation('));
    }
    // And none of the deck-tree ones.
    for (final operation in <String>[
      'createRootDeck',
      'createSubDeck',
      'moveDeck',
      'resetContentType',
    ]) {
      expect(
        contract,
        isNot(contains('$operation(')),
        reason: 'CardRepository must not declare $operation',
      );
    }
  });

  test('the implementations do not cross-implement', () {
    final deckImpl = read(
      'lib/features/deck/data/repositories/deck_repository_impl.dart',
    );
    expect(deckImpl, isNot(contains('implements CardRepository')));
    expect(deckImpl, isNot(contains('CardDao')));
    // The old shape must not come back: card writes as a part of deck impl.
    expect(
      File(
        'lib/features/deck/data/repositories/card_write_deck_repository_impl.dart',
      ).existsSync(),
      isFalse,
      reason:
          'card operations live in features/card, '
          'not in a part of DeckRepositoryImpl',
    );
    final cardImpl = read(
      'lib/features/card/data/repositories/card_repository_impl.dart',
    );
    expect(cardImpl, isNot(contains('part of')));
    expect(
      cardImpl,
      isNot(anyOf(contains('features/deck/data/'), contains('../deck/data/'))),
      reason: 'Card data must not import Deck data',
    );
  });

  test('DeckDao carries no card CRUD; CardDao carries it all', () {
    final deckDao = read('lib/features/deck/data/datasources/deck_dao.dart');
    for (final member in <String>[
      'insertCard(',
      'updateCardById(',
      'deleteCardById(',
      'insertReviewState(',
      'cardById(',
      'watchCardsByDeck(',
    ]) {
      expect(
        deckDao,
        isNot(contains(member)),
        reason: 'DeckDao must not declare $member',
      );
    }

    final cardDao = read('lib/features/card/data/datasources/card_dao.dart');
    for (final member in <String>[
      'insertCard(',
      'updateCardById(',
      'deleteCardById(',
      'insertReviewState(',
      'cardById(',
      'studyStateByCard(',
      'watchCardsByDeck(',
    ]) {
      expect(cardDao, contains(member));
    }
  });

  test('Card source ownership lives outside features/deck', () {
    for (final path in <String>[
      'lib/features/deck/domain/entities/card_entity.dart',
      'lib/features/deck/domain/repositories/card_repository.dart',
      'lib/features/deck/domain/entities/card_study_state_entity.dart',
      'lib/features/deck/data/mappers/card_mapper.dart',
      'lib/features/deck/data/repositories/card_repository_impl.dart',
      'lib/features/deck/data/card_study_state_mapper.dart',
      'lib/features/deck/data/local/card_dao.dart',
    ]) {
      expect(
        File(path).existsSync(),
        isFalse,
        reason: '$path belongs under lib/features/card',
      );
    }
  });

  test('no production recursion hides behind a depth cap', () {
    // The business limit lives in DeckEntity.maxTreeDepth and the write
    // guards; production subtree SQL must not quietly truncate instead.
    final deckQueries = read('lib/core/database/queries/deck.drift');

    expect(
      deckQueries,
      isNot(contains('depth < 64')),
      reason: 'a hardcoded walk cap silently truncates corrupt subtrees',
    );
    // The probes bound their walk by parameter, derived from the domain
    // constant at the call site.
    expect(deckQueries, contains(':maxWalk'));
  });
}
