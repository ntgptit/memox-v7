import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';

import 'support/progress_read_harness.dart';

/// What happens to a figure when the tree moves under it — against real SQLite.
///
/// The cascade that removes a deleted deck's answers, the stream invalidation
/// that follows a write, and the statement count that proves there is no N+1 are
/// all behaviour of SQLite and Drift themselves. None of it is checkable against
/// a fake.
void main() {
  final harness = installProgressReadHarness();

  group('history follows the card, not where it was answered (BR-185)', () {
    test('moving a card moves its whole history to the new deck', () async {
      await harness.root('root-a', name: 'Alpha');
      await harness.root('root-b', name: 'Beta');
      await harness.subDeck(
        'cards-a',
        parentId: 'root-a',
        rootId: 'root-a',
        contentType: 'card',
      );
      await harness.subDeck(
        'cards-b',
        parentId: 'root-b',
        rootId: 'root-b',
        contentType: 'card',
      );
      await harness.seedSession(deckId: 'root-a');
      await harness.card('card-1', deckId: 'cards-a');
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(-2));
      await harness.answer('a2', cardId: 'card-1', at: localMidnight(0));

      final before = await harness.watch().first;
      expect(rowFor(before, 'root-a').last7Days.cardDayCount, 2);
      expect(rowFor(before, 'root-b').last7Days.cardDayCount, 0);

      await harness.moveCard('card-1', toDeckId: 'cards-b');

      final after = await harness.watch().first;

      // The whole history, not just the turns graded after the move — there is
      // no per-answer deck to split it by, and that is the design (BR-185).
      expect(rowFor(after, 'root-a').last7Days.cardDayCount, 0);
      expect(rowFor(after, 'root-b').last7Days.cardDayCount, 2);
    });

    test('moving a subtree moves every card under it', () async {
      await harness.root('root-a', name: 'Alpha');
      await harness.root('root-b', name: 'Beta');
      await harness.seedSession(deckId: 'root-a');
      await harness.subDeck('branch', parentId: 'root-a', rootId: 'root-a');
      await harness.subDeck(
        'leaf',
        parentId: 'branch',
        rootId: 'root-a',
        contentType: 'card',
      );
      await harness.card('card-1', deckId: 'leaf');
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(0));

      await harness.moveSubtree(
        'branch',
        toParentId: 'root-b',
        toRootId: 'root-b',
      );

      final after = await harness.watch().first;

      expect(rowFor(after, 'root-a').last7Days.activeCardCount, 0);
      expect(rowFor(after, 'root-b').last7Days.activeCardCount, 1);
    });
  });

  group('a deleted deck takes its activity with it', () {
    test(
      'deleting a deck removes the whole subtree from every total',
      () async {
        await harness.root('root-a', name: 'Alpha');
        await harness.seedSession(deckId: 'root-a');
        await harness.subDeck(
          'branch',
          parentId: 'root-a',
          rootId: 'root-a',
          contentType: 'card',
        );
        await harness.card('card-1', deckId: 'branch');
        await harness.answer('a1', cardId: 'card-1', at: localMidnight(0));

        expect(
          rowFor(
            await harness.watch().first,
            'root-a',
          ).last7Days.activeCardCount,
          1,
        );

        await harness.deleteDeck('branch');

        final after = await harness.watch().first;

        expect(rowFor(after, 'root-a').last7Days.activeCardCount, 0);
        expect(after.scopeLast7Days.activeCardCount, 0);
        // Not filtered out — gone. The cascade reaches cards and then answers,
        // which is why no predicate in the statement mentions deletion at all.
        expect(await harness.countRows('study_answers'), 0);
      },
    );

    test(
      'a level whose deck is gone fails rather than rendering empty',
      () async {
        await harness.root('root-a', name: 'Alpha');

        await expectLater(
          harness.watch(deckId: 'no-such-deck').first,
          throwsA(isA<NotFoundFailure>()),
        );
      },
    );

    test('a deck with no sub-decks still yields a level', () async {
      await harness.root('root-a', name: 'Alpha');
      await harness.subDeck(
        'cards-a',
        parentId: 'root-a',
        rootId: 'root-a',
        contentType: 'card',
      );
      await harness.seedSession(deckId: 'root-a');
      await harness.card('card-1', deckId: 'cards-a');
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(0));

      final snapshot = await harness.watch(deckId: 'cards-a').first;

      expect(snapshot.decks, isEmpty);
      expect(snapshot.scopeLast7Days.activeCardCount, 1);
    });
  });

  group('reset keeps the history it does not own (BR-43)', () {
    test(
      'activity survives a reset, in the old generation and the new',
      () async {
        await seedSingleDeck(harness);
        await harness.answer('a1', cardId: 'card-1', at: localMidnight(-1));

        await harness.resetTree('root-a');
        await harness.answer(
          'a2',
          cardId: 'card-1',
          at: localMidnight(0),
          generation: 2,
        );

        final row = rowFor(await harness.watch().first, 'root-a');

        // Both generations count. A window measures what a person did, and a
        // reset is not something that unhappened.
        expect(row.last7Days.cardDayCount, 2);
        expect(row.last7Days.activeDayCount, 2);
      },
    );
  });

  group('the read is a read', () {
    test('it runs one statement per emission and does not grow with the '
        'number of decks', () async {
      for (var i = 0; i < 12; i++) {
        await harness.root('root-$i', name: 'Deck $i');
        await harness.subDeck(
          'cards-$i',
          parentId: 'root-$i',
          rootId: 'root-$i',
          contentType: 'card',
        );
        await harness.card('card-$i', deckId: 'cards-$i');
      }
      await harness.seedSession(deckId: 'root-0');
      await harness.answer('a1', cardId: 'card-0', at: localMidnight(0));
      harness.clearStatements();

      final snapshot = await harness.watch().first;

      expect(snapshot.decks, hasLength(12));
      // One SELECT, whatever the number of decks. A per-deck read would return
      // exactly these records and be invisible to any assertion on them.
      expect(harness.countStatements('card_days'), 1);
    });

    test('it writes nothing', () async {
      await seedSingleDeck(harness);
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(0));
      final decks = await harness.countRows('decks');
      final cards = await harness.countRows('cards');
      final answers = await harness.countRows('study_answers');
      final states = await harness.countRows('card_study_states');
      harness.clearStatements();

      await harness.watch().first;
      await harness.watch(deckId: 'root-a').first;

      expect(harness.writeStatements, isEmpty);
      expect(await harness.countRows('decks'), decks);
      expect(await harness.countRows('cards'), cards);
      expect(await harness.countRows('study_answers'), answers);
      expect(await harness.countRows('card_study_states'), states);
    });
  });

  group('the stream follows the data (BR-189)', () {
    test('a new answer re-emits with the new figures', () async {
      await seedSingleDeck(harness);

      final emissions = harness.watch().map(
        (DeckActivitySnapshot s) => rowFor(s, 'root-a').last7Days.cardDayCount,
      );

      final done = expectLater(emissions, emitsInOrder(<int>[0, 1]));
      await pumpEventQueue();
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(0));
      await done;
    });

    test('moving a card re-emits both decks', () async {
      await harness.root('root-a', name: 'Alpha');
      await harness.root('root-b', name: 'Beta');
      await harness.subDeck(
        'cards-a',
        parentId: 'root-a',
        rootId: 'root-a',
        contentType: 'card',
      );
      await harness.subDeck(
        'cards-b',
        parentId: 'root-b',
        rootId: 'root-b',
        contentType: 'card',
      );
      await harness.seedSession(deckId: 'root-a');
      await harness.card('card-1', deckId: 'cards-a');
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(0));

      final emissions = harness.watch().map(
        (DeckActivitySnapshot s) =>
            rowFor(s, 'root-b').last7Days.activeCardCount,
      );

      final done = expectLater(emissions, emitsInOrder(<int>[0, 1]));
      await pumpEventQueue();
      await harness.moveCard('card-1', toDeckId: 'cards-b');
      await done;
    });

    test('deleting a deck re-emits the level it was on', () async {
      await harness.root('root-a', name: 'Alpha');
      await harness.root('root-b', name: 'Beta');

      final emissions = harness.watch().map(
        (DeckActivitySnapshot s) => s.decks.length,
      );

      final done = expectLater(emissions, emitsInOrder(<int>[2, 1]));
      await pumpEventQueue();
      await harness.deleteDeck('root-b');
      await done;
    });
  });

  group('a level with nothing in it', () {
    test('no decks at all is an empty level with zero totals', () async {
      final snapshot = await harness.watch().first;

      expect(snapshot.decks, isEmpty);
      expect(snapshot.scopeLast7Days.activeCardCount, 0);
      expect(snapshot.scopeLast30Days.cardDayCount, 0);
      expect(snapshot.nextDayBoundaryAt, localMidnight(1));
    });

    test(
      'decks with no answers report zeroes rather than disappearing',
      () async {
        await harness.root('root-a', name: 'Alpha');
        await harness.root('root-b', name: 'Beta');

        final snapshot = await harness.watch().first;

        expect(snapshot.decks, hasLength(2));
        expect(rowFor(snapshot, 'root-a').last7Days.activeCardCount, 0);
        expect(rowFor(snapshot, 'root-b').last30Days.cardDayCount, 0);
      },
    );
  });
}
