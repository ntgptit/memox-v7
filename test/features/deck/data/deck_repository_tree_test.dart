import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

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
          name: DeckName.parseOrThrow('Leaf2'),
          parentDeckId: tree.branch.id,
        );
        await h.cardRepository.createCard(
          deckId: tree.leaf.id,
          front: 'a',
          back: 'a',
        );
        await h.cardRepository.createCard(
          deckId: leaf2.id,
          front: 'b',
          back: 'b',
        );
        await h.cardRepository.createCard(
          deckId: leaf2.id,
          front: 'c',
          back: 'c',
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
        front: 'f',
        back: 'b',
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
      expect(await h.countAll('card_review_states'), 0);
      expect(await h.countAll('study_sessions'), 0);
    });

    test('deleting a branch keeps the rest of the tree', () async {
      final tree = await h.seedTree();
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: 'f',
        back: 'b',
      );

      await h.deckRepository.deleteDeck(tree.branch.id);

      expect(await h.rawDeck(tree.root.id), isNotNull);
      expect(await h.rawDeck(tree.branch.id), isNull);
      expect(await h.rawDeck(tree.leaf.id), isNull);
      expect(await h.countAll('cards'), 0);
    });
  });

  group('resetContentType', () {
    test('succeeds on an empty sub-deck (BR-68)', () async {
      final tree = await h.seedTree();
      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: 'f',
        back: 'b',
      );
      await h.cardRepository.deleteCard(card.id);
      // BR-67: still 'card' after the delete...
      expect(await h.contentTypeOf(tree.leaf.id), 'card');

      // ...until the explicit reset (BR-68).
      await h.deckRepository.resetContentType(tree.leaf.id);
      expect(await h.contentTypeOf(tree.leaf.id), 'unset');
    });

    test('is blocked while the deck still has a card', () async {
      final tree = await h.seedTree();
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: 'f',
        back: 'b',
      );

      await expectLater(
        h.deckRepository.resetContentType(tree.leaf.id),
        throwsA(isA<ConflictFailure>()),
      );
      expect(await h.contentTypeOf(tree.leaf.id), 'card');
    });

    test('is blocked while the deck still has a child deck', () async {
      final tree = await h.seedTree();

      await expectLater(
        h.deckRepository.resetContentType(tree.branch.id),
        throwsA(isA<ConflictFailure>()),
      );
      expect(await h.contentTypeOf(tree.branch.id), 'deck');
    });

    test('is blocked on a root — a root is deck forever (BR-58)', () async {
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parseOrThrow('Root'),
        schedulerType: SchedulerType.eightBox,
      );

      await expectLater(
        h.deckRepository.resetContentType(root.id),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('deleting the last child deck does not auto-reset (BR-67)', () async {
      final tree = await h.seedTree();
      await h.deckRepository.deleteDeck(tree.leaf.id);

      expect(await h.contentTypeOf(tree.branch.id), 'deck');
    });
  });
}
