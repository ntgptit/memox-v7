import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';

import 'support/deck_repository_harness.dart';

/// The 10-level depth limit (BR-55) on a real SQLite database: root is level
/// 1, level 10 is the deepest allowed, and both `createSubDeck` and
/// `moveDeck` refuse — atomically, before any mutation — anything deeper.
/// Also proves the UNION subtree walks stay complete at full depth and
/// terminate on cyclic (corrupt) data instead of hanging or truncating.
void main() {
  final h = installDeckRepositoryHarness();

  group('createSubDeck depth guard', () {
    test('a chain up to level 10 can be created — root is level 1', () async {
      final chain = await h.seedChain(DeckEntity.maxTreeDepth);

      expect(chain, hasLength(DeckEntity.maxTreeDepth));
      // The deepest deck exists and belongs to the same root.
      final deepest = (await h.rawDeck(chain.last.id))!;
      expect(deepest.read<String>('root_deck_id'), chain.first.id);
    });

    test('level 11 is refused', () async {
      final chain = await h.seedChain(DeckEntity.maxTreeDepth);

      await expectLater(
        h.deckRepository.createSubDeck(
          name: DeckName.parse('Too deep').name!,
          parentDeckId: chain.last.id,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test(
      'a refused level 11 mutates nothing — no deck, no content lock',
      () async {
        final chain = await h.seedChain(DeckEntity.maxTreeDepth);
        // The deepest deck is still unset; a successful create would have
        // locked it to 'deck'.
        expect(await h.contentTypeOf(chain.last.id), 'unset');
        final decksBefore = await h.countAll('decks');
        final updatedAtBefore = (await h.rawDeck(
          chain.last.id,
        ))!.read<DateTime>('updated_at');

        await expectLater(
          h.deckRepository.createSubDeck(
            name: DeckName.parse('Too deep').name!,
            parentDeckId: chain.last.id,
          ),
          throwsA(isA<ConflictFailure>()),
        );

        expect(await h.countAll('decks'), decksBefore);
        expect(await h.contentTypeOf(chain.last.id), 'unset');
        expect(
          (await h.rawDeck(chain.last.id))!.read<DateTime>('updated_at'),
          updatedAtBefore,
        );
      },
    );
  });

  group('moveDeck depth guard', () {
    test(
      'a move whose deepest resulting level is exactly 10 succeeds',
      () async {
        // Target chain: root at 1 … deck at level 8. Moving source[1] moves
        // the subtree {source[1], source[2]} — height 2. Deepest resulting
        // level: 8 + 2 = 10.
        final target = await h.seedChain(
          DeckEntity.maxTreeDepth - 2,
          prefix: 'target-',
        );
        final source = await h.seedChain(3, prefix: 'source-');

        await h.deckRepository.moveDeck(
          deckId: source[1].id,
          targetParentDeckId: target.last.id,
        );

        final moved = (await h.rawDeck(source[1].id))!;
        expect(moved.readNullable<String>('parent_deck_id'), target.last.id);
        expect(moved.read<String>('root_deck_id'), target.first.id);
        // The deepest moved node really sits at level 10.
        expect(
          (await h.rawDeck(source[2].id))!.read<String>('root_deck_id'),
          target.first.id,
        );
      },
    );

    test(
      'a move whose deepest resulting level would be 11 is refused',
      () async {
        // Target at level 9 plus a subtree of height 2 → 11.
        final target = await h.seedChain(
          DeckEntity.maxTreeDepth - 1,
          prefix: 'target-',
        );
        final source = await h.seedChain(3, prefix: 'source-');

        await expectLater(
          h.deckRepository.moveDeck(
            deckId: source[1].id,
            targetParentDeckId: target.last.id,
          ),
          throwsA(isA<ConflictFailure>()),
        );
      },
    );

    test(
      'a refused deep move rolls back nothing because nothing ran',
      () async {
        final target = await h.seedChain(
          DeckEntity.maxTreeDepth - 1,
          prefix: 'target-',
        );
        final source = await h.seedChain(3, prefix: 'source-');
        final movedDeck = source[1];
        final targetLeaf = target.last;
        final parentBefore = (await h.rawDeck(movedDeck.id))!;
        final targetBefore = (await h.rawDeck(targetLeaf.id))!;

        await expectLater(
          h.deckRepository.moveDeck(
            deckId: movedDeck.id,
            targetParentDeckId: targetLeaf.id,
          ),
          throwsA(isA<ConflictFailure>()),
        );

        // Untouched: parent pointer, every root pointer in the source subtree,
        // the target's content type, and both updated_at stamps.
        final parentAfter = (await h.rawDeck(movedDeck.id))!;
        expect(
          parentAfter.readNullable<String>('parent_deck_id'),
          parentBefore.readNullable<String>('parent_deck_id'),
        );
        for (final deck in source) {
          expect(
            (await h.rawDeck(deck.id))!.read<String>('root_deck_id'),
            source.first.id,
          );
        }
        expect(
          (await h.rawDeck(targetLeaf.id))!.read<String>('content_type'),
          targetBefore.read<String>('content_type'),
        );
        expect(
          parentAfter.read<DateTime>('updated_at'),
          parentBefore.read<DateTime>('updated_at'),
        );
        expect(
          (await h.rawDeck(targetLeaf.id))!.read<DateTime>('updated_at'),
          targetBefore.read<DateTime>('updated_at'),
        );
      },
    );
  });

  group('subtree walks at full depth and on corrupt data', () {
    test('deletion impact counts a full-depth chain completely', () async {
      final chain = await h.seedChain(DeckEntity.maxTreeDepth);
      await h.cardRepository.createCard(
        deckId: chain.last.id,
        front: 'f',
        back: 'b',
      );

      final impact = await h.deckRepository.getDeletionImpact(chain.first.id);

      // Every level below the root, none silently dropped by a walk cap.
      expect(impact.descendantDeckCount, DeckEntity.maxTreeDepth - 1);
      expect(impact.cardCount, 1);
    });

    test('root rewrite reaches the deepest level of a moved chain', () async {
      // A height-9 chain moved under a fresh root: deepest level 1 + 9 = 10.
      final source = await h.seedChain(
        DeckEntity.maxTreeDepth - 1,
        prefix: 'source-',
      );
      final target = await h.seedChain(1, prefix: 'target-');

      await h.deckRepository.moveDeck(
        deckId: source[1].id,
        targetParentDeckId: target.first.id,
      );

      for (final deck in source.skip(1)) {
        expect(
          (await h.rawDeck(deck.id))!.read<String>('root_deck_id'),
          target.first.id,
          reason: '${deck.id} must point at the new root',
        );
      }
    });

    test('the subtree walk terminates and stays complete on a cycle', () async {
      // Corrupt the tree directly: branch's parent becomes its own child.
      // The UNION walk must return every reachable node exactly once instead
      // of hanging (the old UNION ALL + cap would truncate or loop).
      final tree = await h.seedTree();
      await h.db.customStatement(
        "UPDATE decks SET parent_deck_id = '${tree.leaf.id}' "
        "WHERE id = '${tree.root.id}'",
      );

      final ids = await h.db.subtreeDeckIds(tree.root.id).get();

      expect(ids.toSet(), <String>{tree.root.id, tree.branch.id, tree.leaf.id});
    });

    test(
      'the depth probe refuses a cyclic ancestry instead of guessing',
      () async {
        final tree = await h.seedTree();
        await h.db.customStatement(
          "UPDATE decks SET parent_deck_id = '${tree.leaf.id}' "
          "WHERE id = '${tree.root.id}'",
        );

        // Any depth-guarded write on the corrupt chain must refuse cleanly.
        await expectLater(
          h.deckRepository.createSubDeck(
            name: DeckName.parse('On a cycle').name!,
            parentDeckId: tree.leaf.id,
          ),
          throwsA(isA<ConflictFailure>()),
        );
      },
    );

    test('the cycle guard on moveDeck still works', () async {
      // BR-70 unchanged by the depth work: descendant targets stay blocked.
      final tree = await h.seedTree();

      await expectLater(
        h.deckRepository.moveDeck(
          deckId: tree.branch.id,
          targetParentDeckId: tree.leaf.id,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });
}
