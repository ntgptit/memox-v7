import 'package:drift/drift.dart' show TableUpdate, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';

import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// The badge's other number (BR-150): cards still on the learning chain.
///
/// **New and due are the two disjoint sets of BR-142**, and every test here is
/// a version of that fact measured against real SQLite: New is
/// `learned_at IS NULL` (BR-90), Due is `learned_at IS NOT NULL AND
/// due_at <= now`, and no card may be counted by both — the aggregate that
/// merged them was exactly the defect that hid the Study button on a deck of
/// twenty unlearned cards.
void main() {
  final harness = installDeckRepositoryHarness();
  final now = testNow;

  Future<List<DeckSummary>> rootLevel() async =>
      (await harness.deckRepository
              .watchDeckList(parentDeckId: null, now: now)
              .first)
          .decks;

  Future<List<DeckSummary>> levelUnder(String deckId) async =>
      (await harness.deckRepository
              .watchDeckList(parentDeckId: deckId, now: now)
              .first)
          .decks;

  group('the root aggregate', () {
    test('counts unlearned cards at every depth of the tree (BR-90)', () async {
      final tree = await harness.seedTree();
      for (final deckId in <String>[
        tree.root.id,
        tree.branch.id,
        tree.leaf.id,
      ]) {
        await insertCard(harness.db, id: 'card-$deckId', deckId: deckId);
        await insertReviewState(harness.db, cardId: 'card-$deckId');
      }

      final summaries = await rootLevel();

      expect(summaries.single.newCardCount, 3);
      expect(summaries.single.hasNewCards, isTrue);
    });

    test('new and due are disjoint, and sum to what has a state', () async {
      final tree = await harness.seedTree();
      // One of each: never learned, learned and overdue, learned and not yet.
      await insertCard(harness.db, id: 'fresh', deckId: tree.leaf.id);
      await insertReviewState(harness.db, cardId: 'fresh');
      await insertCard(harness.db, id: 'overdue', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'overdue',
        dueAt: now.subtract(const Duration(minutes: 1)),
      );
      await insertCard(harness.db, id: 'later', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'later',
        dueAt: now.add(const Duration(days: 1)),
      );

      final summary = (await rootLevel()).single;

      // 'fresh' is New and only New; 'overdue' is Due and only Due; 'later' is
      // neither — a merged predicate cannot produce this triple.
      expect(summary.newCardCount, 1);
      expect(summary.dueCardCount, 1);
      expect(summary.totalCardCount, 3);
    });

    test('a card created into the tree raises New and leaves Due', () async {
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'first', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'first',
        dueAt: now.subtract(const Duration(minutes: 5)),
      );
      final before = (await rootLevel()).single;

      await insertCard(harness.db, id: 'second', deckId: tree.leaf.id);
      // Born unlearned, with no schedule (BR-09, BR-149).
      await insertReviewState(harness.db, cardId: 'second');
      // Raw inserts notify no stream, and drift replays a cached result to a
      // new subscriber — so the second read must be told the tables moved, the
      // way the real write path tells it (see 'a card added deep in the tree'
      // in deck_repository_summary_test.dart).
      harness.db.notifyUpdates(<TableUpdate>{
        TableUpdate.onTable(harness.db.cards),
        TableUpdate.onTable(harness.db.cardStudyStates),
      });
      final after = (await rootLevel()).single;

      expect(after.newCardCount, before.newCardCount + 1);
      expect(after.dueCardCount, before.dueCardCount);
    });

    test('finishing the learning chain moves the card out of New '
        '(BR-142)', () async {
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'c1', deckId: tree.leaf.id);
      await insertReviewState(harness.db, cardId: 'c1');
      expect((await rootLevel()).single.newCardCount, 1);

      // What a completed learning chain writes: `learned_at` and a schedule,
      // together (BR-152).
      await harness.db.customUpdate(
        'UPDATE card_study_states SET learned_at = ?, due_at = ? '
        'WHERE card_id = ?',
        variables: <Variable<Object>>[
          Variable<DateTime>(now),
          Variable<DateTime>(now.add(const Duration(days: 1))),
          const Variable<String>('c1'),
        ],
      );
      harness.db.notifyUpdates(<TableUpdate>{
        TableUpdate.onTable(harness.db.cardStudyStates),
      });

      final summary = (await rootLevel()).single;
      expect(summary.newCardCount, 0);
      // Due tomorrow, so not due yet either: the card left both badges.
      expect(summary.dueCardCount, 0);
      expect(summary.totalCardCount, 1);
    });
  });

  group('the child-level aggregate', () {
    test('counts each child branch’s own subtree', () async {
      final tree = await harness.seedTree();
      // Two on the branch's subtree (one deep), none elsewhere.
      await insertCard(harness.db, id: 'b1', deckId: tree.branch.id);
      await insertReviewState(harness.db, cardId: 'b1');
      await insertCard(harness.db, id: 'l1', deckId: tree.leaf.id);
      await insertReviewState(harness.db, cardId: 'l1');

      final children = await levelUnder(tree.root.id);
      final branch = children.singleWhere(
        (DeckSummary summary) => summary.deck.id == tree.branch.id,
      );

      expect(branch.newCardCount, 2);
    });

    test('agrees with the root about the same tree', () async {
      // The parity the two statements owe each other: the flat GROUP BY at the
      // root and the recursive walk below it count New two different ways, and
      // nothing in the type system says they must match.
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'b1', deckId: tree.branch.id);
      await insertReviewState(harness.db, cardId: 'b1');
      await insertCard(harness.db, id: 'l1', deckId: tree.leaf.id);
      await insertReviewState(harness.db, cardId: 'l1');
      await insertCard(harness.db, id: 'l2', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'l2',
        dueAt: now.subtract(const Duration(minutes: 1)),
      );

      final root = (await rootLevel()).single;
      final children = await levelUnder(tree.root.id);
      final childNewSum = children.fold<int>(
        0,
        (int sum, DeckSummary summary) => sum + summary.newCardCount,
      );

      expect(root.newCardCount, 2);
      expect(childNewSum, root.newCardCount);
    });
  });
}
