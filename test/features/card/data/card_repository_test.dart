import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import 'support/card_text_fixture.dart';
import '../../../database/support/test_database.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// Card integration tests on a real SQLite database: create with exactly one
/// review state (BR-09), per-scheduler initialisation, edit isolation (BR-10)
/// and delete cascade (BR-67).
void main() {
  final h = installDeckRepositoryHarness();

  group('createCard', () {
    test('creates the card and exactly one review state (BR-09)', () async {
      final tree = await h.seedTree();
      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText(' front '),
        back: cardText(' back ', side: CardSide.back),
      );

      expect(card.front, 'front');
      expect(card.back, 'back');
      final states = await h.rawStates(card.id);
      expect(states, hasLength(1));
      expect(await h.countAll('card_review_states'), 1);
      // The first card locked the deck (BR-62).
      expect(await h.contentTypeOf(tree.leaf.id), 'card');
    });

    test(
      'eight_box initialisation: box 1, SM-2 columns NULL (BR-09)',
      () async {
        final tree = await h.seedTree();
        final card = await h.cardRepository.createCard(
          deckId: tree.leaf.id,
          front: cardText('f'),
          back: cardText('b', side: CardSide.back),
        );

        final state = (await h.rawStates(card.id)).single;
        expect(state.read<String>('scheduler_type'), 'eight_box');
        expect(state.read<int>('scheduler_version'), 1);
        expect(state.read<int>('scheduler_generation'), 1);
        expect(state.readNullable<DateTime>('due_at'), isNull);
        expect(state.read<int>('current_box'), 1);
        expect(state.readNullable<double>('ease_factor'), isNull);
        expect(state.readNullable<int>('interval_days'), isNull);
        expect(state.readNullable<int>('repetitions'), isNull);
        expect(state.read<int>('review_count'), 0);
        expect(state.read<int>('lapse_count'), 0);
      },
    );

    test('sm2 initialisation: 2.5 / 0 / 0, box NULL (BR-09)', () async {
      final tree = await h.seedTree(scheduler: SchedulerType.sm2);
      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('f'),
        back: cardText('b', side: CardSide.back),
      );

      final state = (await h.rawStates(card.id)).single;
      expect(state.read<String>('scheduler_type'), 'sm2');
      expect(state.readNullable<int>('current_box'), isNull);
      expect(state.read<double>('ease_factor'), 2.5);
      expect(state.read<int>('interval_days'), 0);
      expect(state.read<int>('repetitions'), 0);
      expect(state.readNullable<DateTime>('due_at'), isNull);
    });

    test(
      'a failing review-state insert rolls back card AND content lock',
      () async {
        final tree = await h.seedTree();
        expect(await h.contentTypeOf(tree.leaf.id), 'unset');

        // By the time this fires, the content lock and the card insert have
        // both happened inside the transaction.
        await h.db.customStatement(
          'CREATE TRIGGER fail_state_insert '
          'BEFORE INSERT ON card_review_states '
          "BEGIN SELECT RAISE(ABORT, 'injected state failure'); END",
        );

        await expectLater(
          h.cardRepository.createCard(
            deckId: tree.leaf.id,
            front: cardText('f'),
            back: cardText('b', side: CardSide.back),
          ),
          throwsA(isA<Failure>()),
        );

        // No card without a review state can exist (BR-09) — and the deck's
        // content_type went back to unset with it.
        expect(await h.countAll('cards'), 0);
        expect(await h.countAll('card_review_states'), 0);
        expect(await h.contentTypeOf(tree.leaf.id), 'unset');
      },
    );

    test('a card directly under a root is refused (BR-58)', () async {
      final tree = await h.seedTree();

      await expectLater(
        h.cardRepository.createCard(
          deckId: tree.root.id,
          front: cardText('f'),
          back: cardText('b', side: CardSide.back),
        ),
        throwsA(isA<ConflictFailure>()),
      );
      expect(await h.countAll('cards'), 0);
    });

    test('a deck-typed deck refuses cards (BR-64)', () async {
      final tree = await h.seedTree();
      // branch holds leaf, so it is 'deck'.
      await expectLater(
        h.cardRepository.createCard(
          deckId: tree.branch.id,
          front: cardText('f'),
          back: cardText('b', side: CardSide.back),
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('updateCard and deleteCard', () {
    Future<({DeckEntity leaf, CardEntity card})> seedCard() async {
      final tree = await h.seedTree();
      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('front v1'),
        back: cardText('back v1', side: CardSide.back),
      );

      return (leaf: tree.leaf, card: card);
    }

    test(
      'editing content leaves the review state byte-identical (BR-10)',
      () async {
        final seeded = await seedCard();
        final before = (await h.rawStates(seeded.card.id)).single.data;

        h.currentInstant = testNow.add(const Duration(minutes: 5));
        final updated = await h.cardRepository.updateCard(
          cardId: seeded.card.id,
          front: cardText('front v2'),
          back: cardText('back v2', side: CardSide.back),
        );

        expect(updated.front, 'front v2');
        expect(updated.updatedAt, h.currentInstant);
        final after = (await h.rawStates(seeded.card.id)).single.data;
        expect(after, before);
      },
    );

    test('editing content leaves review history untouched (BR-10)', () async {
      final seeded = await seedCard();
      await insertSession(
        h.db,
        id: 'session-1',
        deckId: seeded.leaf.id,
        rootDeckId: seeded.leaf.rootDeckId,
      );
      await insertHistory(
        h.db,
        id: 'history-1',
        cardId: seeded.card.id,
        sessionId: 'session-1',
      );
      final before =
          (await h.db.customSelect('SELECT * FROM review_history').get())
              .map((QueryRow r) => r.data)
              .toList();

      await h.cardRepository.updateCard(
        cardId: seeded.card.id,
        front: cardText('new front'),
        back: cardText('new back', side: CardSide.back),
      );

      final after =
          (await h.db.customSelect('SELECT * FROM review_history').get())
              .map((QueryRow r) => r.data)
              .toList();
      expect(after, before);
    });

    test('deleting a card cascades its state and history', () async {
      final seeded = await seedCard();
      await insertSession(
        h.db,
        id: 'session-1',
        deckId: seeded.leaf.id,
        rootDeckId: seeded.leaf.rootDeckId,
      );
      await insertHistory(
        h.db,
        id: 'history-1',
        cardId: seeded.card.id,
        sessionId: 'session-1',
      );

      await h.cardRepository.deleteCard(seeded.card.id);

      expect(await h.rawCard(seeded.card.id), isNull);
      expect(await h.countAll('card_review_states'), 0);
      expect(await h.countAll('review_history'), 0);
    });

    test(
      'deleting the last card does NOT reset content_type (BR-67)',
      () async {
        final seeded = await seedCard();
        await h.cardRepository.deleteCard(seeded.card.id);

        expect(await h.contentTypeOf(seeded.leaf.id), 'card');
      },
    );

    // "A refused write leaves the card untouched (BR-07)" used to be asserted
    // here, by handing the repository a blank side and checking the row after.
    // It cannot be written that way any more, and that is the improvement: the
    // contract takes `CardText`, so there is no blank side to hand it. The rule
    // runs above this layer and the guarantee is now structural rather than
    // observed — `card_use_cases_test.dart` proves the repository is never
    // reached, and `card_text_test.dart` owns the rule itself.

    test('setCardFlag writes only the flag (BR-92)', () async {
      final seeded = await seedCard();

      await h.cardRepository.setCardFlag(
        cardId: seeded.card.id,
        isFlagged: true,
      );

      final row = await h.rawCard(seeded.card.id);
      expect(row!.read<int>('is_flagged'), 1);
      // The content the toggle must not touch.
      expect(row.read<String>('front'), seeded.card.front);
      expect(row.read<String>('back'), seeded.card.back);
    });

    test('setCardFlag on a missing card is a NotFoundFailure', () async {
      await expectLater(
        h.cardRepository.setCardFlag(cardId: 'ghost', isFlagged: true),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('optional details (BR-95)', () {
    test('createCard persists the three details', () async {
      final tree = await h.seedTree();

      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('f'),
        back: cardText('b', side: CardSide.back),
        example: cardDetail('a sentence'),
        hint: cardDetail('a mnemonic'),
        pronunciation: cardDetail('/saʊnd/'),
      );

      expect(card.example, 'a sentence');
      expect(card.hint, 'a mnemonic');
      expect(card.pronunciation, '/saʊnd/');
    });

    test('updateCard with null details clears them (BR-95)', () async {
      final tree = await h.seedTree();
      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('f'),
        back: cardText('b', side: CardSide.back),
        example: cardDetail('was here'),
      );
      expect(card.example, 'was here');

      final updated = await h.cardRepository.updateCard(
        cardId: card.id,
        front: cardText('f2'),
        back: cardText('b2', side: CardSide.back),
      );

      expect(
        updated.example,
        isNull,
        reason: 'a null detail clears the column',
      );
    });
  });

  group('watchCardListItems (D5)', () {
    test(
      'joins each card to its review state; a new card reads isNew',
      () async {
        final tree = await h.seedTree();
        await h.cardRepository.createCard(
          deckId: tree.leaf.id,
          front: cardText('fresh'),
          back: cardText('back', side: CardSide.back),
        );

        final items = await h.cardRepository
            .watchCardListItems(tree.leaf.id, limit: 50)
            .first;

        expect(items, hasLength(1));
        expect(items.single.card.front, 'fresh');
        // Born with review_count 0 (BR-09), so it projects to isNew (BR-90).
        expect(items.single.state, CardState.isNew);
      },
    );

    test('a non-positive window is refused', () async {
      final tree = await h.seedTree();

      expect(
        () => h.cardRepository.watchCardListItems(tree.leaf.id, limit: 0),
        throwsArgumentError,
      );
    });

    test('the row carries its tag names (BR-93)', () async {
      final tree = await h.seedTree();
      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('f'),
        back: cardText('b', side: CardSide.back),
      );
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: TagName.parse('noun').name!,
      );
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: TagName.parse('people').name!,
      );

      final item =
          (await h.cardRepository
                  .watchCardListItems(tree.leaf.id, limit: 50)
                  .first)
              .single;

      expect(item.tagNames, containsAll(<String>['noun', 'people']));
    });
  });
}
