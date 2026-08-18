import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/failures/deck_move_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/trash/domain/failures/trash_conflict_failure.dart';
import 'package:memox/features/trash/domain/models/trash_restore_target_model.dart';

import '../../../database/invariant_queries.dart';
import 'support/trash_harness.dart';

/// Restore and Undo (BR-261, BR-262, BR-263), against real SQLite.
void main() {
  final h = installTrashHarness();

  TrashDeckTarget deckTarget(String id) =>
      TrashDeckTarget(deckId: id, name: '', parentName: null);

  group('a card', () {
    test('goes back with its id, state and history intact', () async {
      final tree = await h.seedTree();
      final cardId = tree.cardIds.single;
      await h.cardRepository.deleteCard(cardId);
      final batch = await h.onlyBatch();

      await h.trashRepository.restore(
        batchId: batch.batchId,
        target: deckTarget(tree.leaf.id),
      );

      expect(await h.cardBatchOf(cardId), isNull);
      expect(await h.deckOfCard(cardId), tree.leaf.id);
      // Nothing was recreated, so nothing could be recreated wrongly (BR-262).
      expect(await h.countAll('card_study_states'), 1);
      // The batch owns nothing now, so it must not stay as an empty row.
      expect(await h.countBatches(), 0);
    });

    test('sets an unset target to card in the same write', () async {
      final tree = await h.seedTree();
      final sibling = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Sibling').name!,
        parentDeckId: tree.branch.id,
      );
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final batch = await h.onlyBatch();

      expect(await h.contentTypeOf(sibling.id), 'unset');
      await h.trashRepository.restore(
        batchId: batch.batchId,
        target: deckTarget(sibling.id),
      );

      expect(await h.contentTypeOf(sibling.id), 'card');
      expect(await h.deckOfCard(tree.cardIds.single), sibling.id);
    });

    test('is refused by a deck that holds decks', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final batch = await h.onlyBatch();

      await expectLater(
        h.trashRepository.restore(
          batchId: batch.batchId,
          // `branch` holds `leaf`, so it holds decks (BR-64).
          target: deckTarget(tree.branch.id),
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            TrashConflictReason.targetNoLongerValid,
          ),
        ),
      );
      // Refused means nothing written: the card is still in Trash.
      expect(await h.cardBatchOf(tree.cardIds.single), batch.batchId);
    });

    test('is refused by a deck in another tree (BR-165)', () async {
      final tree = await h.seedTree(prefix: 'a ');
      final other = await h.seedTree(prefix: 'b ');
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final batch = await h.onlyBatch();

      await expectLater(
        h.trashRepository.restore(
          batchId: batch.batchId,
          target: deckTarget(other.leaf.id),
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('is refused by the top level', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final batch = await h.onlyBatch();

      await expectLater(
        h.trashRepository.restore(
          batchId: batch.batchId,
          target: const TrashTopLevelTarget(),
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            TrashConflictReason.targetLevelMismatch,
          ),
        ),
      );
    });
  });

  group('a deck subtree', () {
    test('revives only its own batch (BR-258, BR-262)', () async {
      final tree = await h.seedTree(cardCount: 2);
      await h.cardRepository.deleteCard(tree.cardIds.first);
      final cardBatch = await h.cardBatchOf(tree.cardIds.first);
      h.now = h.now.add(const Duration(days: 1));
      await h.deckRepository.deleteDeck(tree.branch.id);

      final batches = await h.batches();
      final deckBatch = batches
          .firstWhere((batch) => batch.deckCount > 0)
          .batchId;

      await h.trashRepository.restore(
        batchId: deckBatch,
        target: deckTarget(tree.root.id),
      );

      // Back: the subtree and the card that went with it.
      expect(await h.deckBatchOf(tree.branch.id), isNull);
      expect(await h.deckBatchOf(tree.leaf.id), isNull);
      expect(await h.cardBatchOf(tree.cardIds.last), isNull);
      // **Still in Trash: the card deleted earlier.** Restoring a parent
      // undoes one deletion, not every deletion that ever touched the tree.
      expect(await h.cardBatchOf(tree.cardIds.first), cardBatch);
      expect(await h.countBatches(), 1);
    });

    test('rewrites root_deck_id for tombstones inside it too', () async {
      // The half of BR-262 that only invariant 6 would catch: a branch deleted
      // earlier still lives under the restored deck, and must point at the tree
      // it now sits in.
      final source = await h.seedTree(prefix: 'a ');
      final destination = await h.seedTree(prefix: 'b ');
      await h.deckRepository.deleteDeck(source.leaf.id);
      h.now = h.now.add(const Duration(days: 1));
      await h.deckRepository.deleteDeck(source.branch.id);

      final batches = await h.batches();
      final outerBatch = batches
          .firstWhere((batch) => batch.deckCount == 1 && batch.cardCount == 0)
          .batchId;

      await h.trashRepository.restore(
        batchId: outerBatch,
        target: deckTarget(destination.root.id),
      );

      expect(await h.rootOf(source.branch.id), destination.root.id);
      // The tombstoned leaf moved with its parent, even though it is still
      // hidden.
      expect(await h.rootOf(source.leaf.id), destination.root.id);
      expect(await h.invariantOffenders(invariantQueries), isEmpty);
    });

    test('is refused when the target tree uses another scheduler', () async {
      final source = await h.seedTree(prefix: 'a ');
      final other = await h.seedTree(
        prefix: 'b ',
        scheduler: SchedulerType.sm2,
      );
      await h.deckRepository.deleteDeck(source.leaf.id);
      final batch = await h.onlyBatch();

      await expectLater(
        h.trashRepository.restore(
          batchId: batch.batchId,
          target: deckTarget(other.branch.id),
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            DeckMoveRejection.differentScheduler,
          ),
        ),
      );
    });

    test('is refused when it would nest past ten levels (BR-55)', () async {
      final tree = await h.seedTree();
      await h.deckRepository.deleteDeck(tree.leaf.id);
      final batch = await h.onlyBatch();

      // A chain to level 10, so nothing may be added under its tip.
      var parentId = tree.root.id;
      for (var level = 2; level <= 10; level++) {
        final deck = await h.deckRepository.createSubDeck(
          name: DeckName.parse('L$level').name!,
          parentDeckId: parentId,
        );
        parentId = deck.id;
      }

      await expectLater(
        h.trashRepository.restore(
          batchId: batch.batchId,
          target: deckTarget(parentId),
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            DeckMoveRejection.tooDeep,
          ),
        ),
      );
    });

    test('a root deck restores only to the top level (BR-261)', () async {
      final tree = await h.seedTree();
      final other = await h.seedTree(prefix: 'b ');
      await h.deckRepository.deleteDeck(tree.root.id);
      final batch = await h.onlyBatch();

      await expectLater(
        h.trashRepository.restore(
          batchId: batch.batchId,
          target: deckTarget(other.root.id),
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            TrashConflictReason.targetLevelMismatch,
          ),
        ),
      );

      await h.trashRepository.restore(
        batchId: batch.batchId,
        target: const TrashTopLevelTarget(),
      );

      expect(await h.deckBatchOf(tree.root.id), isNull);
      expect(await h.parentOf(tree.root.id), isNull);
    });

    test('restoring to the original parent is allowed', () async {
      // `alreadyParent` is a no-op guard for a move and the normal case for a
      // restore — putting the subtree back where it came from.
      final tree = await h.seedTree();
      await h.deckRepository.deleteDeck(tree.leaf.id);
      final batch = await h.onlyBatch();

      await h.trashRepository.restore(
        batchId: batch.batchId,
        target: deckTarget(tree.branch.id),
      );

      expect(await h.parentOf(tree.leaf.id), tree.branch.id);
    });
  });

  group('the target picker', () {
    test('offers only decks the write would accept', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final batch = await h.onlyBatch();

      final targets = await h.trashRepository
          .watchRestoreTargets(batch.batchId)
          .first;

      final ids = targets.map((target) => target.deckId).toSet();
      // The origin qualifies — it is `card`-typed and in the same tree — and a
      // deck holding decks does not.
      expect(ids, contains(tree.leaf.id));
      expect(ids, isNot(contains(tree.branch.id)));
      expect(ids, isNot(contains(tree.root.id)));
    });

    test('offers exactly the top level for a deleted root', () async {
      final tree = await h.seedTree();
      await h.deckRepository.deleteDeck(tree.root.id);
      final batch = await h.onlyBatch();

      final targets = await h.trashRepository
          .watchRestoreTargets(batch.batchId)
          .first;

      expect(targets, hasLength(1));
      expect(targets.single, isA<TrashTopLevelTarget>());
    });
  });

  group('undo (BR-263)', () {
    test('puts a card back where it was, without a target', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final batch = await h.onlyBatch();

      await h.trashRepository.undo(batch.batchId);

      expect(await h.deckOfCard(tree.cardIds.single), tree.leaf.id);
      expect(await h.contentTypeOf(tree.leaf.id), 'card');
      expect(await h.countBatches(), 0);
    });

    test('puts a subtree back under its old parent', () async {
      final tree = await h.seedTree();
      await h.deckRepository.deleteDeck(tree.leaf.id);
      final batch = await h.onlyBatch();

      await h.trashRepository.undo(batch.batchId);

      expect(await h.parentOf(tree.leaf.id), tree.branch.id);
      expect(await h.contentTypeOf(tree.branch.id), 'deck');
    });

    test('is refused with one reason when the old place is gone', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final batch = await h.onlyBatch();
      // The deck the card came from goes to Trash as well.
      await h.deckRepository.deleteDeck(tree.leaf.id);

      await expectLater(
        h.trashRepository.undo(batch.batchId),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            // One reason, whatever the underlying refusal: the user chose
            // nothing, so the copy has to point them at Trash.
            TrashConflictReason.undoOriginUnavailable,
          ),
        ),
      );
      expect(await h.cardBatchOf(tree.cardIds.single), batch.batchId);
    });
  });

  test('a purged batch cannot be restored', () async {
    final tree = await h.seedTree();
    await h.cardRepository.deleteCard(tree.cardIds.single);
    final batch = await h.onlyBatch();
    await h.trashRepository.purge(<String>[batch.batchId]);

    await expectLater(
      h.trashRepository.restore(
        batchId: batch.batchId,
        target: deckTarget(tree.leaf.id),
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('every invariant holds after a restore', () async {
    final tree = await h.seedTree(cardCount: 2);
    await h.deckRepository.deleteDeck(tree.branch.id);
    final batch = await h.onlyBatch();
    await h.trashRepository.restore(
      batchId: batch.batchId,
      target: deckTarget(tree.root.id),
    );

    expect(await h.invariantOffenders(invariantQueries), isEmpty);
  });
}
