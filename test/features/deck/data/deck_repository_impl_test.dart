import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// Deck-creation integration tests on a real SQLite database: root decks
/// (UC-02) and sub-decks with the first-child content lock (UC-08, BR-62).
///
/// Nothing is mocked; rollbacks are injected with real SQL triggers
/// (`RAISE(ABORT)`), so a "rolled back" assertion is about a genuine
/// mid-transaction abort. The card, tree, move and stream suites live in the
/// sibling `deck_repository_*_test.dart` files, all on this same harness.
void main() {
  final h = installDeckRepositoryHarness();

  group('createRootDeck', () {
    test('creates a root with the mandatory scheduler, generation 1', () async {
      final root = await h.deckRepository.createRootDeck(
        name: '  My deck  ',
        schedulerType: SchedulerType.sm2,
      );

      expect(root.name, 'My deck');
      expect(root.schedulerType, SchedulerType.sm2);
      expect(root.schedulerGeneration, 1);
      expect(root.firstReviewAt, isNull);
      expect(root.createdAt, testNow);

      final row = (await h.rawDeck(root.id))!;
      expect(row.readNullable<String>('parent_deck_id'), isNull);
      expect(row.read<String>('scheduler_type'), 'sm2');
      expect(row.read<int>('scheduler_version'), 1);
      expect(row.readNullable<DateTime>('first_review_at'), isNull);
    });

    test(
      'refuses the unknown scheduler — the choice is mandatory (BR-11)',
      () async {
        await expectLater(
          h.deckRepository.createRootDeck(
            name: 'No mode',
            schedulerType: SchedulerType.unknown,
          ),
          throwsA(isA<ValidationFailure>()),
        );
        expect(await h.countAll('decks'), 0);
      },
    );

    test('a root points at itself: root_deck_id = id (BR-56)', () async {
      final root = await h.deckRepository.createRootDeck(
        name: 'Self',
        schedulerType: SchedulerType.eightBox,
      );

      expect(root.rootDeckId, root.id);
      expect((await h.rawDeck(root.id))!.read<String>('root_deck_id'), root.id);
    });

    test('a root is born content_type = deck (BR-58)', () async {
      final root = await h.deckRepository.createRootDeck(
        name: 'Typed',
        schedulerType: SchedulerType.eightBox,
      );

      expect(root.contentType, DeckContentType.deck);
      expect(await h.contentTypeOf(root.id), 'deck');
    });

    test(
      'an invalid name is refused before anything is written (BR-01)',
      () async {
        await expectLater(
          h.deckRepository.createRootDeck(
            name: '   ',
            schedulerType: SchedulerType.eightBox,
          ),
          throwsA(isA<ValidationFailure>()),
        );
        expect(await h.countAll('decks'), 0);
      },
    );
  });

  group('createSubDeck', () {
    test(
      'creates an unset child inheriting the parent root (BR-60, BR-56)',
      () async {
        final tree = await h.seedTree();

        expect(tree.leaf.parentDeckId, tree.branch.id);
        expect(tree.leaf.rootDeckId, tree.root.id);
        expect(tree.leaf.contentType, DeckContentType.unset);
      },
    );

    test('a sub-deck carries no scheduler columns (BR-06)', () async {
      final tree = await h.seedTree();

      final row = (await h.rawDeck(tree.leaf.id))!;
      expect(row.readNullable<String>('scheduler_type'), isNull);
      expect(row.readNullable<int>('scheduler_version'), isNull);
      expect(row.readNullable<int>('scheduler_generation'), isNull);
      expect(tree.leaf.schedulerType, isNull);
      expect(tree.leaf.schedulerGeneration, isNull);
    });

    test('the first child flips an unset parent to deck (BR-62)', () async {
      final tree = await h.seedTree();
      // seedTree created leaf under branch while branch was unset.
      expect(await h.contentTypeOf(tree.branch.id), 'deck');
      // leaf itself got no child, so it stayed unset.
      expect(await h.contentTypeOf(tree.leaf.id), 'unset');
    });

    test(
      'a failing child insert rolls the content lock back (BR-62)',
      () async {
        final tree = await h.seedTree();
        expect(await h.contentTypeOf(tree.leaf.id), 'unset');

        // A real mid-transaction failure: the parent's content lock has
        // already been written when this trigger aborts the child insert.
        await h.db.customStatement(
          "CREATE TRIGGER fail_child_insert BEFORE INSERT ON decks "
          "WHEN NEW.parent_deck_id = '${tree.leaf.id}' "
          "BEGIN SELECT RAISE(ABORT, 'injected child failure'); END",
        );

        await expectLater(
          h.deckRepository.createSubDeck(
            name: 'Doomed',
            parentDeckId: tree.leaf.id,
          ),
          throwsA(isA<Failure>()),
        );

        // Rolled back: no half-created child, and the lock is undone.
        expect(await h.contentTypeOf(tree.leaf.id), 'unset');
        final children = await h.db
            .customSelect(
              "SELECT id FROM decks WHERE parent_deck_id = '${tree.leaf.id}'",
            )
            .get();
        expect(children, isEmpty);
      },
    );

    test('a card deck refuses sub-decks (BR-63)', () async {
      final tree = await h.seedTree();
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: 'f',
        back: 'b',
      );

      await expectLater(
        h.deckRepository.createSubDeck(
          name: 'Nope',
          parentDeckId: tree.leaf.id,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('a missing parent is NotFound, not a database error', () async {
      await expectLater(
        h.deckRepository.createSubDeck(name: 'Orphan', parentDeckId: 'absent'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}
