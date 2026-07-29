import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/scheduler_type_model.dart';

import 'support/deck_repository_harness.dart';

/// Subtree-move integration tests on a real SQLite database (UC-09,
/// BR-69…BR-74): the recursive root-pointer rewrite, every blocked case, and
/// atomic rollback under an injected mid-move failure. Part of the suite
/// rooted in `deck_repository_impl_test.dart`.
void main() {
  final h = installDeckRepositoryHarness();

  test(
    'moves a three-level subtree and rewrites every root pointer (BR-71)',
    () async {
      final treeA = await h.seedTree(prefix: 'A-');
      final grandLeaf = await h.deckRepository.createSubDeck(
        name: 'A-GrandLeaf',
        parentDeckId: treeA.leaf.id,
      );
      await h.cardRepository.createCard(
        deckId: grandLeaf.id,
        front: 'f',
        back: 'b',
      );
      final treeB = await h.seedTree(prefix: 'B-');

      // Move branch (level 2 of A, itself three levels deep) under B's leaf.
      await h.deckRepository.moveDeck(
        deckId: treeA.branch.id,
        targetParentDeckId: treeB.leaf.id,
      );

      final movedBranch = (await h.rawDeck(treeA.branch.id))!;
      expect(movedBranch.readNullable<String>('parent_deck_id'), treeB.leaf.id);
      // Every node of the moved subtree points at the new root (BR-72).
      for (final id in <String>[treeA.branch.id, treeA.leaf.id, grandLeaf.id]) {
        expect(
          (await h.rawDeck(id))!.read<String>('root_deck_id'),
          treeB.root.id,
          reason: '$id must point at the new root',
        );
      }
      // The old root keeps itself only.
      expect(
        (await h.rawDeck(treeA.root.id))!.read<String>('root_deck_id'),
        treeA.root.id,
      );
      // The target was unset and became deck (BR-62).
      expect(await h.contentTypeOf(treeB.leaf.id), 'deck');
    },
  );

  test('a move within the same root keeps pointers and stays atomic', () async {
    final tree = await h.seedTree();
    final branch2 = await h.deckRepository.createSubDeck(
      name: 'Branch2',
      parentDeckId: tree.root.id,
    );

    await h.deckRepository.moveDeck(
      deckId: tree.leaf.id,
      targetParentDeckId: branch2.id,
    );

    final moved = (await h.rawDeck(tree.leaf.id))!;
    expect(moved.readNullable<String>('parent_deck_id'), branch2.id);
    expect(moved.read<String>('root_deck_id'), tree.root.id);
    expect(await h.contentTypeOf(branch2.id), 'deck');
  });

  test('into itself is blocked (BR-70)', () async {
    final tree = await h.seedTree();

    await expectLater(
      h.deckRepository.moveDeck(
        deckId: tree.branch.id,
        targetParentDeckId: tree.branch.id,
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('into its own descendant is blocked (BR-70)', () async {
    final tree = await h.seedTree();

    await expectLater(
      h.deckRepository.moveDeck(
        deckId: tree.branch.id,
        targetParentDeckId: tree.leaf.id,
      ),
      throwsA(isA<ConflictFailure>()),
    );
    // Nothing moved.
    expect(
      (await h.rawDeck(tree.branch.id))!.readNullable<String>('parent_deck_id'),
      tree.root.id,
    );
  });

  test('into a card deck is blocked (BR-64)', () async {
    final treeA = await h.seedTree(prefix: 'A-');
    final treeB = await h.seedTree(prefix: 'B-');
    await h.cardRepository.createCard(
      deckId: treeB.leaf.id,
      front: 'f',
      back: 'b',
    );

    await expectLater(
      h.deckRepository.moveDeck(
        deckId: treeA.branch.id,
        targetParentDeckId: treeB.leaf.id,
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('across scheduler types is blocked, never converted (BR-74)', () async {
    final treeA = await h.seedTree(prefix: 'A-');
    final treeB = await h.seedTree(prefix: 'B-', scheduler: SchedulerType.sm2);

    await expectLater(
      h.deckRepository.moveDeck(
        deckId: treeA.branch.id,
        targetParentDeckId: treeB.branch.id,
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('across scheduler generations is blocked (BR-74)', () async {
    final treeA = await h.seedTree(prefix: 'A-');
    final treeB = await h.seedTree(prefix: 'B-');
    await h.db.customStatement(
      'UPDATE decks SET scheduler_generation = 2 '
      "WHERE id = '${treeB.root.id}'",
    );

    await expectLater(
      h.deckRepository.moveDeck(
        deckId: treeA.branch.id,
        targetParentDeckId: treeB.branch.id,
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('moving a root itself is blocked (BR-06)', () async {
    final treeA = await h.seedTree(prefix: 'A-');
    final treeB = await h.seedTree(prefix: 'B-');

    await expectLater(
      h.deckRepository.moveDeck(
        deckId: treeA.root.id,
        targetParentDeckId: treeB.branch.id,
      ),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test(
    'a mid-move failure rolls everything back — no pointer left askew (BR-71)',
    () async {
      final treeA = await h.seedTree(prefix: 'A-');
      final treeB = await h.seedTree(prefix: 'B-');
      final targetType = await h.contentTypeOf(treeB.leaf.id);

      // Abort exactly when the subtree rewrite reaches the deepest node —
      // after the parent pointer and content lock were already written.
      await h.db.customStatement(
        'CREATE TRIGGER fail_root_rewrite '
        'BEFORE UPDATE OF root_deck_id ON decks '
        "WHEN NEW.id = '${treeA.leaf.id}' "
        "AND NEW.root_deck_id = '${treeB.root.id}' "
        "BEGIN SELECT RAISE(ABORT, 'injected move failure'); END",
      );

      await expectLater(
        h.deckRepository.moveDeck(
          deckId: treeA.branch.id,
          targetParentDeckId: treeB.leaf.id,
        ),
        throwsA(isA<Failure>()),
      );

      // Untouched, all of it: parent pointer, both root pointers, and the
      // target's content type.
      expect(
        (await h.rawDeck(
          treeA.branch.id,
        ))!.readNullable<String>('parent_deck_id'),
        treeA.root.id,
      );
      expect(
        (await h.rawDeck(treeA.branch.id))!.read<String>('root_deck_id'),
        treeA.root.id,
      );
      expect(
        (await h.rawDeck(treeA.leaf.id))!.read<String>('root_deck_id'),
        treeA.root.id,
      );
      expect(await h.contentTypeOf(treeB.leaf.id), targetType);
    },
  );
}
