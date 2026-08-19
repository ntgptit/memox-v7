import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/trash/domain/failures/trash_conflict_failure.dart';
import 'package:memox/features/trash/domain/models/trash_restore_target_model.dart';

import '../../../database/invariant_queries.dart';
import 'support/trash_harness.dart';

/// Restore and Undo (BR-261, BR-262, BR-263), against real SQLite.
/// Undo (BR-263), split from `trash_restore_test.dart` at the 400-line
/// guard on its own group boundary.
void main() {
  final h = installTrashHarness();

  TrashDeckTarget deckTarget(String id) =>
      TrashDeckTarget(deckId: id, name: '', parentName: null);

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
