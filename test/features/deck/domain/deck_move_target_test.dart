import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_move_failure.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../presentation/support/fake_deck_repository.dart';

/// `buildDeckMoveTargets`, which decides what the move picker offers (UC-09).
///
/// Pure input, pure output, no database. That is the point of putting the rule
/// in a function: every rejection reason UC-09 lists gets a case here, and the
/// repository's own transaction-time checks are tested separately against real
/// SQLite. Both exist on purpose — this one explains, that one is what makes
/// the write safe.
void main() {
  /// A tree: rootA (eight-box) → branch → leaf, plus rootB on the same
  /// scheduler and rootC on SM-2.
  ///
  /// `createdAt` is staggered so the returned order is deterministic; the sort
  /// is by root then creation time.
  ({
    DeckEntity rootA,
    DeckEntity branch,
    DeckEntity leaf,
    DeckEntity rootB,
    DeckEntity rootC,
    List<DeckEntity> all,
  })
  buildTree() {
    DateTime at(int minute) => DateTime.utc(2026, 1, 1, 0, minute);

    final rootA = fakeRootDeck(id: 'a', name: 'A', createdAt: at(1));
    final branch = fakeSubDeck(
      id: 'a-branch',
      name: 'Branch',
      parentId: 'a',
      rootId: 'a',
      contentType: DeckContentType.deck,
      createdAt: at(2),
    );
    final leaf = fakeSubDeck(
      id: 'a-leaf',
      name: 'Leaf',
      parentId: 'a-branch',
      rootId: 'a',
      createdAt: at(3),
    );
    final rootB = fakeRootDeck(id: 'b', name: 'B', createdAt: at(4));
    final rootC = fakeRootDeck(
      id: 'c',
      name: 'C',
      schedulerType: SchedulerType.sm2,
      createdAt: at(5),
    );

    return (
      rootA: rootA,
      branch: branch,
      leaf: leaf,
      rootB: rootB,
      rootC: rootC,
      all: <DeckEntity>[rootA, branch, leaf, rootB, rootC],
    );
  }

  DeckMoveRejection? rejectionFor(List<DeckMoveTarget> targets, String id) =>
      targets.firstWhere((target) => target.deck.id == id).rejection;

  group('scope', () {
    test('a root deck has nowhere to go', () {
      // UC-09 A2. Moving a root would need scheduler columns on a non-root
      // (BR-06), so it is a new decision rather than a move — and offering an
      // empty picker is more honest than offering targets that all fail.
      final tree = buildTree();

      final targets = buildDeckMoveTargets(
        source: tree.rootA,
        allDecks: tree.all,
      );

      expect(targets, isEmpty);
    });

    test('every deck in the database appears, eligible or not', () {
      // The picker shows rejected rows with a reason rather than hiding them:
      // a deck that is simply absent leaves the user hunting for it.
      final tree = buildTree();

      final targets = buildDeckMoveTargets(
        source: tree.leaf,
        allDecks: tree.all,
      );

      expect(
        targets.map((target) => target.deck.id),
        containsAll(<String>['a', 'a-branch', 'a-leaf', 'b', 'c']),
      );
    });
  });

  group('rejection reasons', () {
    test('the source itself (BR-70)', () {
      final tree = buildTree();

      final targets = buildDeckMoveTargets(
        source: tree.branch,
        allDecks: tree.all,
      );

      expect(rejectionFor(targets, 'a-branch'), DeckMoveRejection.itself);
    });

    test('a descendant of the source — the cycle guard (BR-69)', () {
      final tree = buildTree();

      final targets = buildDeckMoveTargets(
        source: tree.branch,
        allDecks: tree.all,
      );

      expect(rejectionFor(targets, 'a-leaf'), DeckMoveRejection.ownDescendant);
    });

    test('the current parent, because the move would do nothing', () {
      final tree = buildTree();

      final targets = buildDeckMoveTargets(
        source: tree.leaf,
        allDecks: tree.all,
      );

      expect(
        rejectionFor(targets, 'a-branch'),
        DeckMoveRejection.alreadyParent,
      );
    });

    test('a deck fixed to cards (BR-64)', () {
      final tree = buildTree();
      final cardDeck = fakeSubDeck(
        id: 'b-cards',
        name: 'Cards',
        parentId: 'b',
        rootId: 'b',
        contentType: DeckContentType.card,
      );

      final targets = buildDeckMoveTargets(
        source: tree.leaf,
        allDecks: <DeckEntity>[...tree.all, cardDeck],
      );

      expect(rejectionFor(targets, 'b-cards'), DeckMoveRejection.holdsCards);
    });

    test('a root on a different scheduler (BR-73, BR-74)', () {
      // Never silently converted: there is no defensible mapping between a box
      // number and an ease factor, so the move is refused and the user is left
      // to reset progress deliberately.
      final tree = buildTree();

      final targets = buildDeckMoveTargets(
        source: tree.leaf,
        allDecks: tree.all,
      );

      expect(rejectionFor(targets, 'c'), DeckMoveRejection.differentScheduler);
    });

    test('a root on a different generation (BR-74)', () {
      final tree = buildTree();
      final resetRoot = fakeRootDeck(
        id: 'd',
        name: 'D',
        schedulerGeneration: 2,
      );

      final targets = buildDeckMoveTargets(
        source: tree.leaf,
        allDecks: <DeckEntity>[...tree.all, resetRoot],
      );

      expect(rejectionFor(targets, 'd'), DeckMoveRejection.differentGeneration);
    });

    test('a target that would push the tree past ten levels (BR-55)', () {
      // A chain of nine, plus a two-tall subtree, is eleven — refused. The
      // arithmetic is targetDepth + subtreeHeight, exactly as UC-09 step 2
      // spells it out.
      final chain = <DeckEntity>[fakeRootDeck(id: 'r1', name: 'r1')];
      for (var level = 2; level <= 9; level++) {
        chain.add(
          fakeSubDeck(
            id: 'r$level',
            name: 'r$level',
            parentId: 'r${level - 1}',
            rootId: 'r1',
            contentType: DeckContentType.deck,
          ),
        );
      }
      final sourceParent = fakeSubDeck(
        id: 's1',
        name: 's1',
        parentId: 'r1',
        rootId: 'r1',
        contentType: DeckContentType.deck,
      );
      final source = fakeSubDeck(
        id: 's2',
        name: 's2',
        parentId: 's1',
        rootId: 'r1',
        contentType: DeckContentType.deck,
      );
      final sourceChild = fakeSubDeck(
        id: 's3',
        name: 's3',
        parentId: 's2',
        rootId: 'r1',
      );

      final targets = buildDeckMoveTargets(
        source: source,
        allDecks: <DeckEntity>[...chain, sourceParent, source, sourceChild],
      );

      // Depth 9 + height 2 = 11 → refused.
      expect(rejectionFor(targets, 'r9'), DeckMoveRejection.tooDeep);
      // Depth 8 + height 2 = 10 → exactly the limit, allowed.
      expect(rejectionFor(targets, 'r8'), isNull);
    });
  });

  group('eligibility', () {
    test('a sibling root on the same scheduler is a valid target', () {
      final tree = buildTree();

      final targets = buildDeckMoveTargets(
        source: tree.leaf,
        allDecks: tree.all,
      );

      expect(rejectionFor(targets, 'b'), isNull);
      expect(
        targets.firstWhere((target) => target.deck.id == 'b').isEligible,
        isTrue,
      );
    });

    test('depth is reported so the picker can show hierarchy', () {
      final tree = buildTree();

      final targets = buildDeckMoveTargets(
        source: tree.leaf,
        allDecks: tree.all,
      );

      expect(targets.firstWhere((t) => t.deck.id == 'a').depth, 1);
      expect(targets.firstWhere((t) => t.deck.id == 'a-branch').depth, 2);
      expect(targets.firstWhere((t) => t.deck.id == 'a-leaf').depth, 3);
    });
  });

  group('corrupt data', () {
    test('a cycle does not hang the walk', () {
      // Two decks each claiming the other as parent. Nothing should be able to
      // produce this, but a build that loops here would freeze the app rather
      // than refuse a move — so the walks deduplicate by id.
      final left = fakeSubDeck(
        id: 'x',
        name: 'x',
        parentId: 'y',
        rootId: 'x',
        contentType: DeckContentType.deck,
      );
      final right = fakeSubDeck(
        id: 'y',
        name: 'y',
        parentId: 'x',
        rootId: 'x',
        contentType: DeckContentType.deck,
      );

      final targets = buildDeckMoveTargets(
        source: left,
        allDecks: <DeckEntity>[left, right],
      );

      expect(targets, hasLength(2));
    });

    test('a missing root refuses rather than guessing', () {
      final orphan = fakeSubDeck(
        id: 'o',
        name: 'o',
        parentId: 'gone',
        rootId: 'gone',
      );
      final other = fakeRootDeck(id: 'ok', name: 'ok');

      final targets = buildDeckMoveTargets(
        source: orphan,
        allDecks: <DeckEntity>[orphan, other],
      );

      expect(rejectionFor(targets, 'ok'), DeckMoveRejection.differentScheduler);
    });
  });

  group('BR-01 name rule', () {
    test('nameProblem and validateName agree', () {
      // One implementation, two entry points. If they diverged, a form would
      // accept a name the repository then rejects — an error with no field to
      // point at.
      expect(DeckEntity.nameProblem('  '), DeckNameProblem.empty);
      expect(
        DeckEntity.nameProblem('a' * (DeckEntity.maxNameLength + 1)),
        DeckNameProblem.tooLong,
      );
      expect(DeckEntity.nameProblem('  Japanese  '), isNull);
      expect(DeckEntity.validateName('  Japanese  '), 'Japanese');
      expect(() => DeckEntity.validateName('   '), throwsA(isA<Object>()));
    });
  });
}
