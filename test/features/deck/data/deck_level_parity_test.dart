import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// The two aggregates must agree, at every depth.
///
/// **Why this file exists.** `watchDeckList` is one contract method backed by
/// *two* statements: the root level is a flat `GROUP BY root_deck_id`, and every
/// deeper level is a recursive walk. That split is deliberate — the root's
/// subtree is reachable through a column (BR-56), so paying for recursion there
/// would be paying for nothing — but it means the same number is computed two
/// different ways, and nothing in the type system says they must match.
///
/// The screen makes the mismatch invisible if it ever happens: a root would show
/// 120 cards, opening it would show children summing to 118, and neither number
/// looks wrong on its own. So the invariant is asserted here rather than trusted.
///
/// The invariant, for any deck D:
///
///     subtree(D) == direct_cards(D) + Σ subtree(child of D)
///
/// where `subtree` is the number the level *above* D reports for D. At a root,
/// `direct_cards` is always zero because a root holds only sub-decks (BR-58), so
/// the root's total must equal the sum of its children's.
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

  /// A card in [deckId], with a study state due at [dueAt] — `null` meaning
  /// never learned, which since BR-142 is the *other* set and not due.
  Future<void> card(String id, String deckId, {DateTime? dueAt}) async {
    await insertCard(harness.db, id: id, deckId: deckId);
    await insertReviewState(harness.db, cardId: id, dueAt: dueAt);
  }

  int totalOf(List<DeckSummary> level) => level.fold(
    0,
    (int sum, DeckSummary summary) => sum + summary.totalCardCount,
  );

  int dueOf(List<DeckSummary> level) => level.fold(
    0,
    (int sum, DeckSummary summary) => sum + summary.dueCardCount,
  );

  /// A three-level tree with cards at every depth and a mix of due states.
  ///
  /// Deliberately lopsided: an even tree would pass an implementation that
  /// divided rather than summed.
  Future<({DeckEntity root, DeckEntity branch, DeckEntity leaf})>
  seedLopsided() async {
    final tree = await harness.seedTree();
    // 1 due, 1 not, on the branch.
    await card('b1', tree.branch.id);
    await card('b2', tree.branch.id, dueAt: now.add(const Duration(days: 3)));
    // 3 due, 1 not, on the leaf.
    await card(
      'l1',
      tree.leaf.id,
      dueAt: now.subtract(const Duration(days: 1)),
    );
    await card('l2', tree.leaf.id, dueAt: now);
    await card('l3', tree.leaf.id);
    await card('l4', tree.leaf.id, dueAt: now.add(const Duration(days: 9)));

    return tree;
  }

  group('a root and the level inside it', () {
    test('totals agree', () async {
      final tree = await seedLopsided();

      final root = (await rootLevel()).single;
      final children = await levelUnder(tree.root.id);

      // A root holds only decks (BR-58), so there is no direct-card term.
      expect(root.totalCardCount, 6);
      expect(totalOf(children), root.totalCardCount);
    });

    test('due counts agree', () async {
      final tree = await seedLopsided();

      final root = (await rootLevel()).single;
      final children = await levelUnder(tree.root.id);

      expect(root.dueCardCount, 2);
      expect(dueOf(children), root.dueCardCount);
    });

    test('two roots do not bleed into each other', () async {
      // The recursive CTE seeds from `parent_deck_id = :parentId` and walks down.
      // A join written one degree too loose would pull in the other tree, and a
      // single-root fixture would never notice.
      final first = await harness.seedTree(prefix: 'A-');
      final second = await harness.seedTree(prefix: 'B-');
      await card('a1', first.leaf.id);
      await card('b1', second.leaf.id);
      await card('b2', second.branch.id);

      final roots = await rootLevel();

      expect(roots.map((DeckSummary s) => s.totalCardCount), <int>[1, 2]);
      expect(totalOf(await levelUnder(first.root.id)), 1);
      expect(totalOf(await levelUnder(second.root.id)), 2);
    });
  });

  group('a level inside a level', () {
    test(
      'a branch total equals its own cards plus its children subtrees',
      () async {
        final tree = await seedLopsided();

        final branchAsChild = (await levelUnder(tree.root.id)).single;
        final under = await levelUnder(tree.branch.id);

        // The branch holds 2 cards directly and its only child holds 4.
        expect(branchAsChild.totalCardCount, 6);
        expect(totalOf(under), 4);
        expect(branchAsChild.totalCardCount, 2 + totalOf(under));
      },
    );

    test('a leaf reports itself the same way its parent reports it', () async {
      // The end of the recursion. A CTE that dropped the seed row would report a
      // leaf as zero from above while the leaf's own level looked fine.
      final tree = await seedLopsided();

      final leafAsChild = (await levelUnder(tree.branch.id)).single;

      expect(leafAsChild.totalCardCount, 4);
      expect(leafAsChild.dueCardCount, 2);
      expect(await levelUnder(tree.leaf.id), isEmpty);
    });

    test('the sum holds after a move', () async {
      // A subtree changing parents is the write most likely to break an
      // aggregate: the rows do not change, only where they hang.
      final tree = await seedLopsided();
      final sibling = await harness.deckRepository.createSubDeck(
        name: DeckName.parse('Sibling').name!,
        parentDeckId: tree.root.id,
      );

      await harness.deckRepository.moveDeck(
        deckId: tree.leaf.id,
        targetParentDeckId: sibling.id,
      );

      final root = (await rootLevel()).single;
      final children = await levelUnder(tree.root.id);

      expect(root.totalCardCount, 6, reason: 'nothing was created or deleted');
      expect(totalOf(children), root.totalCardCount);
      expect(
        children.map((DeckSummary s) => s.totalCardCount),
        <int>[2, 4],
        reason: 'the leaf and its four cards moved to the sibling',
      );
    });
  });

  group('the scheduler resolves the same way at both levels', () {
    test('a root and its descendants report one scheduler (BR-06)', () async {
      final tree = await harness.seedTree(scheduler: SchedulerType.sm2);

      final root = (await rootLevel()).single;
      final branch = (await levelUnder(tree.root.id)).single;
      final leaf = (await levelUnder(tree.branch.id)).single;

      expect(root.schedulerType, SchedulerType.sm2);
      expect(branch.schedulerType, SchedulerType.sm2);
      expect(leaf.schedulerType, SchedulerType.sm2);
    });
  });

  group('the due boundary is the same instant at both levels', () {
    test('a root and the level inside it carry one nextDueAt', () async {
      // The controller arms a timer from this. Two levels disagreeing would mean
      // navigating into a deck silently rescheduled the refresh.
      final tree = await seedLopsided();

      final rootSnapshot = await harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now)
          .first;
      final levelSnapshot = await harness.deckRepository
          .watchDeckList(parentDeckId: tree.root.id, now: now)
          .first;

      expect(rootSnapshot.nextDueAt, now.add(const Duration(days: 3)));
      expect(levelSnapshot.nextDueAt, rootSnapshot.nextDueAt);
    });
  });
}
