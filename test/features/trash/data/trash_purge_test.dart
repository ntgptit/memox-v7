import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/trash/domain/failures/trash_conflict_failure.dart';
import 'package:memox/features/trash/domain/models/trash_retention_model.dart';

import '../../../database/invariant_queries.dart';
import 'support/trash_harness.dart';

/// Retention and purge (BR-190, BR-191), against real SQLite.
void main() {
  final h = installTrashHarness();

  group('the thirty-day boundary (BR-190)', () {
    test('one microsecond short is still restorable', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);

      h.now = h.now
          .add(TrashRetention.window)
          .subtract(const Duration(microseconds: 1));
      final purged = await h.trashRepository.purgeExpired(h.now);

      expect(purged, 0);
      expect(await h.countBatches(), 1);
      expect(await h.countAll('cards'), 1);
    });

    test('exactly thirty days goes', () async {
      // `<= cutoff`, and this is the assertion that pins which side of the
      // boundary the equality falls on.
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);

      h.now = h.now.add(TrashRetention.window);
      final purged = await h.trashRepository.purgeExpired(h.now);

      expect(purged, 1);
      expect(await h.countBatches(), 0);
      expect(await h.countAll('cards'), 0);
    });

    test('the sweep is idempotent', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      h.now = h.now.add(TrashRetention.window);

      expect(await h.trashRepository.purgeExpired(h.now), 1);
      // Startup, resume and opening Trash can all fire within a millisecond of
      // each other; the second must find nothing and change nothing.
      expect(await h.trashRepository.purgeExpired(h.now), 0);
      expect(await h.trashRepository.purgeExpired(h.now), 0);
    });

    test('a younger batch is left alone by the sweep', () async {
      final tree = await h.seedTree(cardCount: 2);
      await h.cardRepository.deleteCard(tree.cardIds.first);
      h.now = h.now.add(const Duration(days: 20));
      await h.cardRepository.deleteCard(tree.cardIds.last);

      h.now = h.now.add(const Duration(days: 11));
      final purged = await h.trashRepository.purgeExpired(h.now);

      expect(purged, 1);
      expect(await h.cardBatchOf(tree.cardIds.last), isNotNull);
      expect(await h.countAll('cards'), 1);
    });
  });

  group('what a purge takes with it (BR-191)', () {
    test('the cascade reaches state, history and queue rows', () async {
      final tree = await h.seedTree();
      final cardId = tree.cardIds.single;
      await h.cardRepository.deleteCard(cardId);
      final batch = await h.onlyBatch();

      await h.trashRepository.purge(<String>[batch.batchId]);

      expect(await h.countAll('cards'), 0);
      expect(await h.countAll('card_study_states'), 0);
      expect(await h.countBatches(), 0);
    });

    test('a deck purge takes its whole batch and nothing else', () async {
      final tree = await h.seedTree(cardCount: 2, prefix: 'a ');
      final other = await h.seedTree(prefix: 'b ');
      await h.deckRepository.deleteDeck(tree.branch.id);
      final batch = await h.onlyBatch();

      await h.trashRepository.purge(<String>[batch.batchId]);

      // The other tree is untouched: three decks and one card.
      expect(await h.countAll('cards'), 1);
      expect(await h.deckBatchOf(other.leaf.id), isNull);
      expect(await h.rootOf(other.root.id), other.root.id);
    });

    test('a batch whose cascade would reach another is refused', () async {
      // The precondition BR-191 exists for: purging the deck would cascade
      // through `parent_deck_id`, which has never heard of a batch.
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      h.now = h.now.add(const Duration(days: 1));
      await h.deckRepository.deleteDeck(tree.branch.id);

      final batches = await h.batches();
      final deckBatch = batches
          .firstWhere((batch) => batch.deckCount > 0)
          .batchId;

      await expectLater(
        h.trashRepository.purge(<String>[deckBatch]),
        throwsA(
          isA<ConflictFailure>().having(
            (failure) => failure.reason,
            'reason',
            TrashConflictReason.purgeWouldTakeAnotherBatch,
          ),
        ),
      );
      // Refused whole: both batches are still there.
      expect(await h.countBatches(), 2);
      expect(await h.countAll('cards'), 1);
    });

    test('the same pair purges cleanly when both are named', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      h.now = h.now.add(const Duration(days: 1));
      await h.deckRepository.deleteDeck(tree.branch.id);

      final ids = <String>[
        for (final batch in await h.batches()) batch.batchId,
      ];
      await h.trashRepository.purge(ids);

      expect(await h.countBatches(), 0);
      expect(await h.countAll('cards'), 0);
      // The root survives: it was never in either batch.
      expect(await h.rootOf(tree.root.id), tree.root.id);
    });

    test('the sweep skips a blocked batch instead of failing', () async {
      // Nobody asked for a sweep, so one protected batch must not stop the
      // others — the opposite of a user-requested purge.
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      // Twenty days later the deck goes, so at day 31 only the card is past
      // retention and the deck's cascade would reach nothing protected.
      h.now = h.now.add(const Duration(days: 20));
      await h.deckRepository.deleteDeck(tree.branch.id);

      h.now = h.now.add(const Duration(days: 11));
      final purged = await h.trashRepository.purgeExpired(h.now);

      expect(purged, 1);
      expect(await h.countBatches(), 1);
      // The deck batch stayed, whole.
      expect(await h.deckBatchOf(tree.branch.id), isNotNull);
    });

    test('naming a batch that is already gone is refused', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final batch = await h.onlyBatch();
      await h.trashRepository.purge(<String>[batch.batchId]);

      await expectLater(
        h.trashRepository.purge(<String>[batch.batchId]),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  test('every invariant holds after a sweep', () async {
    final tree = await h.seedTree(cardCount: 2);
    await h.cardRepository.deleteCard(tree.cardIds.first);
    h.now = h.now.add(const Duration(days: 1));
    await h.deckRepository.deleteDeck(tree.branch.id);

    h.now = h.now.add(TrashRetention.window);
    await h.trashRepository.purgeExpired(h.now);

    expect(await h.invariantOffenders(invariantQueries), isEmpty);
    expect(await h.countBatches(), 0);
  });
}
