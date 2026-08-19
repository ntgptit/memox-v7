import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';

import 'support/progress_read_harness.dart';

/// What a Progress figure counts, and which rows a window admits — against real
/// SQLite.
///
/// Split from `progress_activity_hierarchy_test.dart` at the source-size
/// ceiling, and the seam is real: this file is about the *unit* and the
/// *boundary*, that one is about the *tree* and its lifecycle. Both need a real
/// database, because a mocked executor would assert that the code calls the API
/// it was written to call, which is the one thing nobody doubts.
void main() {
  final harness = installProgressReadHarness();

  group('the card-day is the unit (BR-183)', () {
    test('six answers to one card on one day count as one card-day', () async {
      await seedSingleDeck(harness);
      for (var i = 0; i < 6; i++) {
        await harness.answer(
          'a$i',
          cardId: 'card-1',
          at: localMidnight(0).add(Duration(hours: i)),
        );
      }

      final snapshot = await harness.watch().first;
      final row = rowFor(snapshot, 'root-a');

      expect(row.last7Days.activeCardCount, 1);
      expect(row.last7Days.activeDayCount, 1);
      expect(row.last7Days.cardDayCount, 1);
    });

    test('one card on three days is three card-days and three active '
        'days', () async {
      await seedSingleDeck(harness);
      for (var day = 0; day < 3; day++) {
        await harness.answer(
          'a$day',
          cardId: 'card-1',
          at: localMidnight(-day).add(const Duration(hours: 10)),
        );
      }

      final row = rowFor(await harness.watch().first, 'root-a');

      expect(row.last7Days.activeCardCount, 1);
      expect(row.last7Days.activeDayCount, 3);
      expect(row.last7Days.cardDayCount, 3);
    });

    test('two cards on the same day are one active day', () async {
      await seedSingleDeck(harness);
      await harness.card('card-2', deckId: cardDeckId);
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(0));
      await harness.answer('a2', cardId: 'card-2', at: localMidnight(0));

      final row = rowFor(await harness.watch().first, 'root-a');

      expect(row.last7Days.activeCardCount, 2);
      expect(row.last7Days.activeDayCount, 1);
      expect(row.last7Days.cardDayCount, 2);
    });
  });

  group('the window is whole local days ending today (BR-184)', () {
    /// One answer per boundary instant, each on its own card so the card counts
    /// stay separable.
    Future<DeckActivity> seedAt(DateTime instant) async {
      await seedSingleDeck(harness);
      await harness.answer('a1', cardId: 'card-1', at: instant);

      return rowFor(await harness.watch().first, 'root-a');
    }

    test('23:59:59 local today is inside both windows', () async {
      final row = await seedAt(lastSecondOfLocalDay(0));

      expect(row.last7Days.activeCardCount, 1);
      expect(row.last30Days.activeCardCount, 1);
    });

    test('local midnight tomorrow is inside neither', () async {
      final row = await seedAt(localMidnight(1));

      expect(row.last7Days.activeCardCount, 0);
      expect(row.last30Days.activeCardCount, 0);
    });

    test('the first instant of the seventh day back is inside the 7-day '
        'window', () async {
      final row = await seedAt(localMidnight(-6));

      expect(row.last7Days.activeCardCount, 1);
      expect(row.last30Days.activeCardCount, 1);
    });

    test('one second earlier is in the 30-day window only', () async {
      final row = await seedAt(lastSecondOfLocalDay(-7));

      expect(row.last7Days.activeCardCount, 0);
      expect(row.last30Days.activeCardCount, 1);
    });

    test('the first instant of the thirtieth day back is inside the 30-day '
        'window', () async {
      final row = await seedAt(localMidnight(-29));

      expect(row.last30Days.activeCardCount, 1);
    });

    test('one second earlier is outside every window', () async {
      final row = await seedAt(lastSecondOfLocalDay(-30));

      expect(row.last30Days.activeCardCount, 0);
    });

    test('exactly one local midnight is its own bucket, not the previous '
        'day', () async {
      // The day index is integer division by 86400 relative to the window's
      // first local midnight. Bound as a REAL it would divide in floating point,
      // where an instant exactly on a boundary can land a hair below the integer
      // and truncate into the day before — which shows up as two calendar days
      // sharing one bucket. Two answers on two consecutive local midnights must
      // therefore be two active days.
      await seedSingleDeck(harness);
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(-1));
      await harness.answer('a2', cardId: 'card-1', at: localMidnight(0));

      final row = rowFor(await harness.watch().first, 'root-a');

      expect(row.last7Days.activeDayCount, 2);
      expect(row.last7Days.cardDayCount, 2);
    });

    test('the snapshot expires at the next local midnight', () async {
      await seedSingleDeck(harness);

      final snapshot = await harness.watch().first;

      expect(snapshot.nextDayBoundaryAt, localMidnight(1));
    });
  });

  group('Learning and Reviewing partition the card-days (BR-186)', () {
    test('a day with any learning turn is a Learning day', () async {
      await seedSingleDeck(harness);
      // Stated rather than defaulted: the point of the case is that a
      // `scheduled` turn on the same day loses to the `learning` one below it.
      await harness.answer('a1', cardId: 'card-1', at: localMidnight(0));
      await harness.answer(
        'a2',
        cardId: 'card-1',
        at: localMidnight(0).add(const Duration(hours: 2)),
        kind: 'learning',
      );

      final row = rowFor(await harness.watch().first, 'root-a');

      expect(row.last7Days.learningCardDayCount, 1);
      expect(row.last7Days.reviewingCardDayCount, 0);
    });

    test('relearning without learning is a Reviewing day', () async {
      await seedSingleDeck(harness);
      await harness.answer(
        'a1',
        cardId: 'card-1',
        at: localMidnight(0),
        kind: 'relearning',
      );

      final row = rowFor(await harness.watch().first, 'root-a');

      expect(row.last7Days.learningCardDayCount, 0);
      expect(row.last7Days.reviewingCardDayCount, 1);
    });

    test('the two halves always sum to every card-day', () async {
      await seedSingleDeck(harness);
      await harness.card('card-2', deckId: cardDeckId);
      await harness.answer(
        'a1',
        cardId: 'card-1',
        at: localMidnight(0),
        kind: 'learning',
      );
      await harness.answer('a2', cardId: 'card-2', at: localMidnight(0));
      await harness.answer('a3', cardId: 'card-2', at: localMidnight(-1));

      final row = rowFor(await harness.watch().first, 'root-a');

      expect(row.last7Days.learningCardDayCount, 1);
      expect(row.last7Days.reviewingCardDayCount, 2);
      expect(row.last7Days.cardDayCount, 3);
    });
  });
}
