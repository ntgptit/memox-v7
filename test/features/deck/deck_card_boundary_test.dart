import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Deck/Card boundary introduced in M4.9a and completed in M4.9b, pinned
/// as source facts so a convenience method cannot quietly re-merge the two
/// responsibilities.
///
/// Complements the guard: these are cross-file claims ("this contract does
/// not mention that operation") that a per-file regex rule cannot own.
void main() {
  String read(String path) => File(path).readAsStringSync();

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
    final contract = read('lib/features/card/domain/card_repository.dart');

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
    final cardImpl = read('lib/features/card/data/card_repository_impl.dart');
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

    final cardDao = read('lib/features/card/data/local/card_dao.dart');
    for (final member in <String>[
      'insertCard(',
      'updateCardById(',
      'deleteCardById(',
      'insertReviewState(',
      'cardById(',
      'reviewStateByCard(',
      'watchCardsByDeck(',
    ]) {
      expect(cardDao, contains(member));
    }
  });

  test('Card source ownership lives outside features/deck', () {
    for (final path in <String>[
      'lib/features/deck/domain/entities/card_entity.dart',
      'lib/features/deck/domain/repositories/card_repository.dart',
      'lib/features/deck/domain/entities/card_review_state_entity.dart',
      'lib/features/deck/data/mappers/card_mapper.dart',
      'lib/features/deck/data/repositories/card_repository_impl.dart',
      'lib/features/deck/data/card_review_state_mapper.dart',
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
