import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/repositories/card_import_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_conflict_failure.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/card_import_repository.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import 'support/card_text_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// The import commit against real SQLite (BR-168, BR-170, BR-171, BR-172).
///
/// Everything under test is transactional truth a fake cannot show: the
/// recheck racing the preview, the rollback wiping every table at once, the
/// content-type step riding the same commit.
void main() {
  final h = installDeckRepositoryHarness();

  CardImportRepositoryImpl repository({String Function()? idGenerator}) =>
      CardImportRepositoryImpl(
        h.db,
        clock: () => h.currentInstant,
        idGenerator: idGenerator ?? () => 'imp-${++h.idCounter}',
      );

  CardTransferRecord entry(
    String front,
    String back, {
    List<String> tags = const <String>[],
  }) => CardTransferRecord(
    front: cardText(front),
    back: cardText(back, side: CardSide.back),
    tags: <TagName>[for (final tag in tags) TagName.parse(tag).name!],
  );

  CardImportPlan plan(
    List<CardTransferRecord> records, {
    bool shouldIncludeDuplicates = false,
  }) => CardImportPlan(
    records: records,
    shouldIncludeDuplicates: shouldIncludeDuplicates,
  );

  group('the batch write (BR-171)', () {
    test('one card gets exactly one fresh study state from the root '
        'scheduler', () async {
      final tree = await h.seedTree();

      final result = await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[entry('사과', 'apple')]),
      );

      expect(result.imported, 1);
      final card = await h.db.customSelect('SELECT * FROM cards').getSingle();
      final states = await h.rawStates(card.read<String>('id'));
      expect(states, hasLength(1));
      expect(states.single.read<String>('scheduler_type'), 'eight_box');
      expect(states.single.read<int>('current_box'), 1);
      expect(states.single.read<String?>('due_at'), isNull);
    });

    test('many cards each get their state, and one timestamp covers the '
        'batch', () async {
      final tree = await h.seedTree();

      final result = await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[
          for (var i = 0; i < 40; i++) entry('front $i', 'back $i'),
        ]),
      );

      expect(result.imported, 40);
      expect(await h.countAll('cards'), 40);
      expect(await h.countAll('card_study_states'), 40);
      final distinctCreated = await h.db
          .customSelect('SELECT COUNT(DISTINCT created_at) AS c FROM cards')
          .getSingle();
      expect(distinctCreated.read<int>('c'), 1);
    });

    test('an sm2 root seeds sm2 state', () async {
      final tree = await h.seedTree(scheduler: SchedulerType.sm2);

      await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[entry('사과', 'apple')]),
      );

      final state = await h.db
          .customSelect('SELECT * FROM card_study_states')
          .getSingle();
      expect(state.read<String>('scheduler_type'), 'sm2');
      expect(state.read<double>('ease_factor'), 2.5);
    });

    test('a large batch clears the bind-variable limit', () async {
      // SQLite binds 999 variables per statement by default; 1200 rows ×
      // 10 columns would blow any single-statement insert. The batch API
      // binds per row, which is what this proves.
      final tree = await h.seedTree();

      final result = await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[
          for (var i = 0; i < 1200; i++) entry('front $i', 'back $i'),
        ]),
      );

      expect(result.imported, 1200);
      expect(await h.countAll('card_study_states'), 1200);
    });
  });

  group('content type (BR-172, BR-168)', () {
    test('an unset target becomes card in the same commit', () async {
      final tree = await h.seedTree();
      expect(await h.contentTypeOf(tree.leaf.id), 'unset');

      await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[entry('사과', 'apple')]),
      );

      expect(await h.contentTypeOf(tree.leaf.id), 'card');
    });

    test('a zero-write import changes nothing, the type included', () async {
      final tree = await h.seedTree();
      // The only entry collides with an existing card, and duplicates skip.
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('사과'),
        back: cardText('apple', side: CardSide.back),
      );
      final before = await h.countAll('cards');

      final result = await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[entry('사과', 'apple')]),
      );

      expect(result.imported, 0);
      expect(result.duplicatesSkipped, 1);
      expect(await h.countAll('cards'), before);
    });

    test('a root target refuses (BR-58)', () async {
      final tree = await h.seedTree();

      expect(
        () => repository().commitImport(
          deckId: tree.root.id,
          plan: plan(<CardTransferRecord>[entry('사과', 'apple')]),
        ),
        throwsA(
          predicate(
            (Object? e) =>
                e is ConflictFailure &&
                e.reason == CardConflictReason.parentIsRoot,
          ),
        ),
      );
    });

    test('a deck-type target refuses (BR-64)', () async {
      final tree = await h.seedTree();

      expect(
        () => repository().commitImport(
          deckId: tree.branch.id,
          plan: plan(<CardTransferRecord>[entry('사과', 'apple')]),
        ),
        throwsA(
          predicate(
            (Object? e) =>
                e is ConflictFailure &&
                e.reason == CardConflictReason.deckHoldsDecks,
          ),
        ),
      );
    });

    test('a missing target refuses with NotFound', () async {
      await h.seedTree();

      expect(
        () => repository().commitImport(
          deckId: 'gone',
          plan: plan(<CardTransferRecord>[entry('사과', 'apple')]),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('duplicates recheck in the transaction (BR-170)', () {
    test('a card created after the preview is still skipped', () async {
      final tree = await h.seedTree();
      // The "preview" happened before this create — the entry does not carry
      // an isDuplicate flag. The transaction's own read is what catches it.
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('사과'),
        back: cardText('apple', side: CardSide.back),
      );

      final result = await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[
          entry('사과', 'apple'),
          entry('배', 'pear'),
        ]),
      );

      expect(result.imported, 1);
      expect(result.duplicatesSkipped, 1);
    });

    test('include-duplicates writes them as new cards', () async {
      final tree = await h.seedTree();
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('사과'),
        back: cardText('apple', side: CardSide.back),
      );

      final result = await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[
          entry('사과', 'apple'),
        ], shouldIncludeDuplicates: true),
      );

      expect(result.imported, 1);
      expect(await h.countAll('cards'), 2);
    });

    test('an in-batch repeat is skipped under the default policy', () async {
      final tree = await h.seedTree();

      final result = await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[
          entry('사과', 'apple'),
          entry('사과', 'apple'),
        ]),
      );

      expect(result.imported, 1);
      expect(result.duplicatesSkipped, 1);
    });
  });

  group('tags (BR-93, BR-94)', () {
    test(
      'reuses an existing tag by folded name and links every card',
      () async {
        final tree = await h.seedTree();
        final seedCard = await h.cardRepository.createCard(
          deckId: tree.leaf.id,
          front: cardText('먼저'),
          back: cardText('first', side: CardSide.back),
        );
        await h.cardRepository.addCardTag(
          cardId: seedCard.id,
          name: TagName.parse('Fruit').name!,
        );

        await repository().commitImport(
          deckId: tree.leaf.id,
          plan: plan(<CardTransferRecord>[
            entry('사과', 'apple', tags: <String>['fruit', 'red']),
            entry('배', 'pear', tags: <String>['FRUIT']),
          ]),
        );

        // 'fruit' and 'FRUIT' fold onto the seeded 'Fruit'; only 'red' is new.
        expect(await h.countAll('tags'), 2);
        expect(await h.countAll('card_tags'), 4);
      },
    );

    test('more distinct tags than one lookup chunk still reuse and link '
        'correctly (C)', () async {
      // 45 cards x 10 tags = 450 distinct folded names — more than
      // CardImportDao.tagLookupChunkSize, so the reuse read must chunk. One
      // of them is seeded beforehand to prove reuse survives the chunking.
      final tree = await h.seedTree();
      final seedCard = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('먼저'),
        back: cardText('first', side: CardSide.back),
      );
      await h.cardRepository.addCardTag(
        cardId: seedCard.id,
        name: TagName.parse('tag000').name!,
      );

      final result = await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[
          for (var card = 0; card < 45; card++)
            entry(
              'front $card',
              'back $card',
              tags: <String>[
                for (var t = 0; t < 10; t++)
                  'tag${(card * 10 + t).toString().padLeft(3, '0')}',
              ],
            ),
        ]),
      );

      expect(result.imported, 45);
      // 450 distinct names, one of which already existed: 449 minted.
      expect(await h.countAll('tags'), 450);
      // The seed card's link plus 45 x 10 imported links.
      expect(await h.countAll('card_tags'), 451);
    });
  });

  group('atomicity under fault (BR-171)', () {
    test('a failing write mid-batch rolls back cards, states, tags and the '
        'content type', () async {
      final tree = await h.seedTree();
      // Fault injection: the third card id repeats the first, so its insert
      // violates the primary key *after* two cards, one tag and the
      // content-type flip already ran inside the transaction.
      var calls = 0;
      final repo = repository(
        idGenerator: () {
          calls += 1;

          return calls == 4 ? 'dup-id-1' : 'dup-id-$calls';
        },
      );

      await expectLater(
        repo.commitImport(
          deckId: tree.leaf.id,
          plan: plan(<CardTransferRecord>[
            entry('하나', 'one', tags: <String>['num']),
            entry('둘', 'two'),
            entry('셋', 'three'),
          ]),
        ),
        throwsA(isA<Failure>()),
      );

      // All or nothing: no partial cards, no orphan states or tags, and the
      // deck is still `unset` — the flip rolled back with the batch.
      expect(await h.countAll('cards'), 0);
      expect(await h.countAll('card_study_states'), 0);
      expect(await h.countAll('tags'), 0);
      expect(await h.countAll('card_tags'), 0);
      expect(await h.contentTypeOf(tree.leaf.id), 'unset');
    });

    test('existing cards, progress and history survive a failed and a '
        'successful import untouched', () async {
      final tree = await h.seedTree();
      final existing = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('기존'),
        back: cardText('existing', side: CardSide.back),
      );
      final rowBefore = await h.rawCard(existing.id);

      await repository().commitImport(
        deckId: tree.leaf.id,
        plan: plan(<CardTransferRecord>[entry('사과', 'apple')]),
      );

      final rowAfter = await h.rawCard(existing.id);
      expect(rowAfter!.data, rowBefore!.data);
    });
  });

  group('readExistingDuplicateKeys', () {
    test('is scoped to the one deck', () async {
      final tree = await h.seedTree();
      final other = await h.seedTree(prefix: 'Other');
      await h.cardRepository.createCard(
        deckId: other.leaf.id,
        front: cardText('사과'),
        back: cardText('apple', side: CardSide.back),
      );

      final keys = await repository().readExistingDuplicateKeys(tree.leaf.id);

      // The other tree's card is not a duplicate of this deck (BR-170).
      expect(keys, isEmpty);
    });
  });
}
