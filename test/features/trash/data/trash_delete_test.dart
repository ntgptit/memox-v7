// `isNull`/`isNotNull` are matchers here; drift exports column predicates by
// the same names.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/trash/domain/models/trash_item_type_model.dart';

import '../../../database/invariant_queries.dart';
import '../../../database/support/test_database.dart';
import 'support/trash_harness.dart';

/// The soft-delete decision table (BR-256…BR-260), against real SQLite.
void main() {
  final h = installTrashHarness();

  group('one card', () {
    test('the row stays, invisible, in a batch of its own', () async {
      final tree = await h.seedTree(cardCount: 2);

      await h.cardRepository.deleteCard(tree.cardIds.first);

      // Kept: content, study state and history are what a restore brings back
      // (BR-259), so none of them may be cascaded away by a delete.
      expect(await h.countAll('cards'), 2);
      expect(await h.countAll('card_study_states'), 2);
      // Hidden: the deck reads one card, not two (BR-257).
      expect(await h.cardBatchOf(tree.cardIds.first), isNotNull);
      expect(await h.cardBatchOf(tree.cardIds.last), isNull);

      final batch = await h.onlyBatch();
      expect(batch.itemType, TrashItemType.card);
      expect(batch.cardCount, 1);
      expect(batch.deckCount, 0);
    });

    test('a bulk delete makes one batch per card (BR-256)', () async {
      final tree = await h.seedTree(cardCount: 3);

      await h.cardRepository.deleteCards(tree.cardIds);

      // Three rows in Trash, not one: the item root is singular, and a user who
      // deletes three may want one back.
      final batches = await h.batches();
      expect(batches, hasLength(3));
      expect(batches.map((batch) => batch.itemType).toSet(), <TrashItemType>{
        TrashItemType.card,
      });
    });

    test('the deck goes back to unset once nothing active is left', () async {
      final tree = await h.seedTree(cardCount: 2);
      expect(await h.contentTypeOf(tree.leaf.id), 'card');

      await h.cardRepository.deleteCard(tree.cardIds.first);
      // One still visible, so the type stands (BR-260).
      expect(await h.contentTypeOf(tree.leaf.id), 'card');

      await h.cardRepository.deleteCard(tree.cardIds.last);
      // Tombstones are not content: the deck is empty as far as the user is
      // concerned, so it unlocks.
      expect(await h.contentTypeOf(tree.leaf.id), 'unset');
    });

    test('deleting a card already in Trash is refused', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);

      // The selection is describing a database that has moved on; a second
      // batch for the same row would be a Trash entry that restores nothing.
      await expectLater(
        h.cardRepository.deleteCard(tree.cardIds.single),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(await h.countBatches(), 1);
    });
  });

  group('one deck', () {
    test('the whole active subtree joins one batch (BR-258)', () async {
      final tree = await h.seedTree(cardCount: 2);

      await h.deckRepository.deleteDeck(tree.branch.id);

      final batchId = await h.deckBatchOf(tree.branch.id);
      expect(batchId, isNotNull);
      expect(await h.deckBatchOf(tree.leaf.id), batchId);
      for (final cardId in tree.cardIds) {
        expect(await h.cardBatchOf(cardId), batchId);
      }
      // The root is not in it — the delete started below it.
      expect(await h.deckBatchOf(tree.root.id), isNull);

      final batch = await h.onlyBatch();
      expect(batch.itemType, TrashItemType.deck);
      expect(batch.deckCount, 2);
      expect(batch.cardCount, 2);
    });

    test('a descendant already in Trash keeps its older batch', () async {
      final tree = await h.seedTree();
      await h.cardRepository.deleteCard(tree.cardIds.single);
      final firstBatch = await h.cardBatchOf(tree.cardIds.single);

      h.now = h.now.add(const Duration(days: 1));
      await h.deckRepository.deleteDeck(tree.branch.id);

      // **The card does not join the deck's batch** (BR-258). It was deleted
      // separately, so restoring the deck must leave it where it is — and the
      // deck's own count says so.
      expect(await h.cardBatchOf(tree.cardIds.single), firstBatch);
      final batches = await h.batches();
      expect(batches, hasLength(2));
      final deckBatch = batches.firstWhere(
        (batch) => batch.itemType == TrashItemType.deck,
      );
      expect(deckBatch.cardCount, 0);
      expect(deckBatch.deckCount, 2);
    });

    test('the parent unsets when its last visible child goes', () async {
      final tree = await h.seedTree();
      expect(await h.contentTypeOf(tree.branch.id), 'deck');

      await h.deckRepository.deleteDeck(tree.leaf.id);

      expect(await h.contentTypeOf(tree.branch.id), 'unset');
      // A root is `deck` forever (BR-58), even with nothing under it.
      expect(await h.contentTypeOf(tree.root.id), 'deck');
    });

    test('deleting a root leaves it a root', () async {
      final tree = await h.seedTree();

      await h.deckRepository.deleteDeck(tree.root.id);

      expect(await h.parentOf(tree.root.id), isNull);
      expect(await h.rootOf(tree.root.id), tree.root.id);
      expect((await h.onlyBatch()).isRootDeck, isTrue);
    });

    test('a depth-10 tree is marked to the last level', () async {
      // The walk has no depth cap on purpose: a cap turns corrupt data into a
      // subtree half marked, which is a batch that cannot be restored whole.
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parse('Deep').name!,
        schedulerType: SchedulerType.eightBox,
      );
      var parentId = root.id;
      final chain = <String>[root.id];
      for (var level = 2; level <= 10; level++) {
        final deck = await h.deckRepository.createSubDeck(
          name: DeckName.parse('L$level').name!,
          parentDeckId: parentId,
        );
        chain.add(deck.id);
        parentId = deck.id;
      }

      await h.deckRepository.deleteDeck(chain[1]);

      final batchId = await h.deckBatchOf(chain[1]);
      for (final deckId in chain.skip(1)) {
        expect(await h.deckBatchOf(deckId), batchId, reason: deckId);
      }
    });
  });

  group('sessions (BR-259)', () {
    /// An open session on [deckId], with [cardId] in its queue.
    Future<void> openSession({
      required String id,
      required String deckId,
      required String rootDeckId,
      required String cardId,
    }) async {
      await insertSession(h.db, id: id, deckId: deckId, rootDeckId: rootDeckId);
      await h.db.customStatement(
        'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
        "position, status, available_at, answers_in_session, is_revealed) "
        "VALUES ('$id', 'self_assess', 1, '$cardId', 0, 'pending', 0, 0, 0)",
      );
    }

    Future<({String status, String? reason})> sessionState(String id) async {
      final row = await h.db
          .customSelect(
            'SELECT status, end_reason FROM study_sessions WHERE id = ?',
            variables: <Variable<Object>>[Variable<String>(id)],
          )
          .getSingle();

      return (
        status: row.read<String>('status'),
        reason: row.read<String?>('end_reason'),
      );
    }

    test('a session on the deleted deck is invalidated', () async {
      final tree = await h.seedTree();
      await openSession(
        id: 'session-1',
        deckId: tree.leaf.id,
        rootDeckId: tree.root.id,
        cardId: tree.cardIds.single,
      );

      await h.deckRepository.deleteDeck(tree.leaf.id);

      final state = await sessionState('session-1');
      expect(state.status, 'invalidated');
      // Stored, never inferred — and its own value, because a reset is a
      // different event that Undo does not reverse.
      expect(state.reason, 'content_deleted');
    });

    test('a root session holding the card is invalidated too', () async {
      // The case a deck-side lookup alone would miss: the session's `deck_id`
      // is the root, which the deletion never touches.
      final tree = await h.seedTree();
      await openSession(
        id: 'session-2',
        deckId: tree.root.id,
        rootDeckId: tree.root.id,
        cardId: tree.cardIds.single,
      );

      await h.cardRepository.deleteCard(tree.cardIds.single);

      expect((await sessionState('session-2')).status, 'invalidated');
    });

    test('a session on another tree is left alone', () async {
      final tree = await h.seedTree(prefix: 'a ');
      final other = await h.seedTree(prefix: 'b ');
      await openSession(
        id: 'session-3',
        deckId: other.leaf.id,
        rootDeckId: other.root.id,
        cardId: other.cardIds.single,
      );

      await h.deckRepository.deleteDeck(tree.leaf.id);

      expect((await sessionState('session-3')).status, 'in_progress');
    });
  });

  test('every invariant holds after a subtree deletion', () async {
    final tree = await h.seedTree(cardCount: 2);
    await h.cardRepository.deleteCard(tree.cardIds.first);
    h.now = h.now.add(const Duration(days: 1));
    await h.deckRepository.deleteDeck(tree.branch.id);

    expect(await h.invariantOffenders(invariantQueries), isEmpty);
  });
}
