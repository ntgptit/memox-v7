import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/card_entity.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

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
        front: ' front ',
        back: ' back ',
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
          front: 'f',
          back: 'b',
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
        front: 'f',
        back: 'b',
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
            front: 'f',
            back: 'b',
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
          front: 'f',
          back: 'b',
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
          front: 'f',
          back: 'b',
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
        front: 'front v1',
        back: 'back v1',
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
          front: 'front v2',
          back: 'back v2',
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
        front: 'new front',
        back: 'new back',
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

    test('validation failure leaves the card untouched (BR-07)', () async {
      final seeded = await seedCard();

      await expectLater(
        h.cardRepository.updateCard(
          cardId: seeded.card.id,
          front: '  ',
          back: 'b',
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        (await h.rawCard(seeded.card.id))!.read<String>('front'),
        'front v1',
      );
    });
  });
}
