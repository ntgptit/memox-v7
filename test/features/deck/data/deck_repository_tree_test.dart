import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/error/failure.dart';

import '../../card/data/support/card_text_fixture.dart';
import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// Tree-shape integration tests on a real SQLite database: deletion impact
/// counts (BR-04), cascade deletes (BR-03) and the explicit content-type
/// reset (BR-67, BR-68). Part of the suite rooted in
/// `deck_repository_impl_test.dart`.
void main() {
  final h = installDeckRepositoryHarness();

  group('deleteDeck and getDeletionImpact', () {
    test(
      'impact counts descendants and cards across the whole subtree (BR-04)',
      () async {
        final tree = await h.seedTree();
        final leaf2 = await h.deckRepository.createSubDeck(
          name: DeckName.parse('Leaf2').name!,
          parentDeckId: tree.branch.id,
        );
        await h.cardRepository.createCard(
          deckId: tree.leaf.id,
          front: cardText('a'),
          back: cardText('a', side: CardSide.back),
        );
        await h.cardRepository.createCard(
          deckId: leaf2.id,
          front: cardText('b'),
          back: cardText('b', side: CardSide.back),
        );
        await h.cardRepository.createCard(
          deckId: leaf2.id,
          front: cardText('c'),
          back: cardText('c', side: CardSide.back),
        );

        final rootImpact = await h.deckRepository.getDeletionImpact(
          tree.root.id,
        );
        expect(rootImpact.descendantDeckCount, 3);
        expect(rootImpact.cardCount, 3);

        final branchImpact = await h.deckRepository.getDeletionImpact(
          tree.branch.id,
        );
        expect(branchImpact.descendantDeckCount, 2);
        expect(branchImpact.cardCount, 3);

        final leafImpact = await h.deckRepository.getDeletionImpact(leaf2.id);
        expect(leafImpact.descendantDeckCount, 0);
        expect(leafImpact.cardCount, 2);
      },
    );

    test('deleting a root cascades the entire tree (BR-03)', () async {
      final tree = await h.seedTree();
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('f'),
        back: cardText('b', side: CardSide.back),
      );
      await insertSession(
        h.db,
        id: 'session-1',
        deckId: tree.root.id,
        rootDeckId: tree.root.id,
      );

      await h.deckRepository.deleteDeck(tree.root.id);

      expect(await h.countAll('decks'), 0);
      expect(await h.countAll('cards'), 0);
      expect(await h.countAll('card_study_states'), 0);
      expect(await h.countAll('study_sessions'), 0);
    });

    test('deleting a branch keeps the rest of the tree', () async {
      final tree = await h.seedTree();
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('f'),
        back: cardText('b', side: CardSide.back),
      );

      await h.deckRepository.deleteDeck(tree.branch.id);

      expect(await h.rawDeck(tree.root.id), isNotNull);
      expect(await h.rawDeck(tree.branch.id), isNull);
      expect(await h.rawDeck(tree.leaf.id), isNull);
      expect(await h.countAll('cards'), 0);
    });
  });

  group('content_type follows the direct children (BR-163)', () {
    test('deleting the last child deck unsets a non-root parent', () async {
      // The transition BR-67 used to forbid. `branch` holds exactly `leaf`;
      // once `leaf` is gone the branch describes nothing, so the type goes
      // with it — in the same transaction as the delete.
      final tree = await h.seedTree();
      await h.deckRepository.deleteDeck(tree.leaf.id);

      expect(await h.contentTypeOf(tree.branch.id), 'unset');
    });

    test('deleting one of several child decks keeps the type', () async {
      final tree = await h.seedTree();
      await h.deckRepository.createSubDeck(
        name: DeckName.parse('Sibling').name!,
        parentDeckId: tree.branch.id,
      );

      await h.deckRepository.deleteDeck(tree.leaf.id);

      expect(await h.contentTypeOf(tree.branch.id), 'deck');
    });

    test('deleting the last child under a root leaves the root deck', () async {
      // A root is `deck` forever (BR-58), and an empty root is ordinary.
      final tree = await h.seedTree();
      await h.deckRepository.deleteDeck(tree.branch.id);

      expect(await h.contentTypeOf(tree.root.id), 'deck');
    });

    test('a deck that still holds a card keeps card after a sibling '
        'delete', () async {
      // The guard against unsetting on the wrong count: `leaf` holds a card,
      // so removing something else must not touch it.
      final tree = await h.seedTree();
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('f'),
        back: cardText('b', side: CardSide.back),
      );
      final sibling = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Sibling').name!,
        parentDeckId: tree.branch.id,
      );

      await h.deckRepository.deleteDeck(sibling.id);

      expect(await h.contentTypeOf(tree.leaf.id), 'card');
      expect(await h.contentTypeOf(tree.branch.id), 'deck');
    });

    test('moving the last child out unsets the source and types the '
        'target', () async {
      // Both ends of one move, one transaction: the target gains its first
      // child and the old parent loses its last.
      final tree = await h.seedTree();
      final target = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Target').name!,
        parentDeckId: tree.root.id,
      );

      await h.deckRepository.moveDeck(
        deckId: tree.leaf.id,
        targetParentDeckId: target.id,
      );

      expect(await h.contentTypeOf(tree.branch.id), 'unset');
      expect(await h.contentTypeOf(target.id), 'deck');
    });

    test('moving a child that leaves a sibling behind keeps the source '
        'typed', () async {
      final tree = await h.seedTree();
      await h.deckRepository.createSubDeck(
        name: DeckName.parse('Stays').name!,
        parentDeckId: tree.branch.id,
      );
      final target = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Target').name!,
        parentDeckId: tree.root.id,
      );

      await h.deckRepository.moveDeck(
        deckId: tree.leaf.id,
        targetParentDeckId: target.id,
      );

      expect(await h.contentTypeOf(tree.branch.id), 'deck');
    });

    test('a refused move changes neither parent nor either type', () async {
      // UC-09 E1: moving a deck into its own subtree. Everything the move
      // would have written — pointer, root pointers, target type, old-parent
      // type — has to be untouched, which is the rollback this rule shares
      // with every other refused write.
      final tree = await h.seedTree();

      await expectLater(
        h.deckRepository.moveDeck(
          deckId: tree.branch.id,
          targetParentDeckId: tree.leaf.id,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(await h.contentTypeOf(tree.branch.id), 'deck');
      expect(await h.contentTypeOf(tree.leaf.id), 'unset');
      final branch = await h.deckRepository.watchAllDecks().first;
      expect(
        branch
            .firstWhere((DeckEntity d) => d.id == tree.branch.id)
            .parentDeckId,
        tree.root.id,
      );
    });
  });
}
