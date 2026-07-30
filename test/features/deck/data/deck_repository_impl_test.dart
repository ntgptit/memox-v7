import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/failures/deck_validation_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
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
        name: DeckName.parse('  My deck  ').name!,
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
      'the unknown scheduler cannot be persisted, and writes nothing (BR-11)',
      () async {
        // Not a `ValidationFailure`. It was one until M4.10b, from a
        // `_requireRealScheduler` guard in the repository — the *second* owner of
        // BR-11, reporting a form problem for a state no user can cause. "Please
        // choose a scheduler" is the wrong thing to show for a programming error.
        //
        // The rule is enforced by the type instead: `SchedulerType.unknown` has no
        // `dbValue`, so the write is impossible rather than merely refused. What
        // this asserts is the property that matters either way — the table is
        // untouched.
        await expectLater(
          h.deckRepository.createRootDeck(
            name: DeckName.parse('No mode').name!,
            schedulerType: SchedulerType.unknown,
          ),
          throwsA(isA<Failure>()),
        );
        expect(await h.countAll('decks'), 0);
      },
    );

    test('a root points at itself: root_deck_id = id (BR-56)', () async {
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parse('Self').name!,
        schedulerType: SchedulerType.eightBox,
      );

      expect(root.rootDeckId, root.id);
      expect((await h.rawDeck(root.id))!.read<String>('root_deck_id'), root.id);
    });

    test('a root is born content_type = deck (BR-58)', () async {
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parse('Typed').name!,
        schedulerType: SchedulerType.eightBox,
      );

      expect(root.contentType, DeckContentType.deck);
      expect(await h.contentTypeOf(root.id), 'deck');
    });

    test('an invalid name cannot reach the repository at all (BR-01)', () async {
      // Not "the repository refuses it" — the repository has no name check any
      // more. The contract takes a `DeckName`, and an invalid string cannot
      // become one, so the write is *unreachable* rather than refused. That is
      // the difference the value object bought: the guarantee moved from a
      // runtime check in a third layer into the signature.
      final parsed = DeckName.parse('   ');
      expect(parsed.name, isNull);
      expect(parsed.problem, DeckValidationProblem.nameEmpty);
      expect(await h.countAll('decks'), 0);
    });
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
            name: DeckName.parse('Doomed').name!,
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
          name: DeckName.parse('Nope').name!,
          parentDeckId: tree.leaf.id,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('a missing parent is NotFound, not a database error', () async {
      await expectLater(
        h.deckRepository.createSubDeck(
          name: DeckName.parse('Orphan').name!,
          parentDeckId: 'absent',
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}
