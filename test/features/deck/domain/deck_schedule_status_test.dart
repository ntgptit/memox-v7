import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/local_day_model.dart';
import 'package:memox/features/deck/data/mappers/deck_mapper.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';

import '../presentation/support/deck_fixtures.dart';

/// The status matrix (BR-161), and the mapper invariant that feeds it.
void main() {
  group('deckScheduleStatusOf — the one statement of the matrix', () {
    // Every caller — a summary, a level fold — delegates here, so the
    // boundaries are asserted once against the function itself.
    test('zero due is notDue, whatever the day count claims', () {
      expect(
        deckScheduleStatusOf(dueCardCount: 0, overdueDayCount: 0),
        DeckScheduleStatus.notDue,
      );
    });

    test('due with zero completed days is dueToday', () {
      expect(
        deckScheduleStatusOf(dueCardCount: 3, overdueDayCount: 0),
        DeckScheduleStatus.dueToday,
      );
    });

    test('one completed day tips it to overdue', () {
      expect(
        deckScheduleStatusOf(dueCardCount: 3, overdueDayCount: 1),
        DeckScheduleStatus.overdue,
      );
    });
  });

  group('the level fold (BR-161 on a whole level)', () {
    DeckListSnapshot level(List<DeckSummary> decks) => DeckListSnapshot(
      parent: null,
      decks: decks,
      ancestors: const [],
      nextDueAt: null,
      nextOverdueTickAt: null,
    );

    test('sums due and new across disjoint child subtrees', () {
      final snapshot = level(<DeckSummary>[
        fakeSummary(id: 'b', name: 'B', totalCardCount: 10, newCardCount: 4),
        fakeSummary(
          id: 'c',
          name: 'C',
          totalCardCount: 20,
          dueCardCount: 7,
          newCardCount: 2,
          overdueDayCount: 7,
        ),
      ]);

      expect(snapshot.levelDueCardCount, 7);
      expect(snapshot.levelNewCardCount, 6);
    });

    test('the level is as late as its latest subtree', () {
      // Max, not sum and not first: days are an age, and two backlogs do not
      // add up to an older one.
      final snapshot = level(<DeckSummary>[
        fakeSummary(
          id: 'b',
          name: 'B',
          totalCardCount: 10,
          dueCardCount: 1,
          overdueDayCount: 2,
        ),
        fakeSummary(
          id: 'c',
          name: 'C',
          totalCardCount: 20,
          dueCardCount: 7,
          overdueDayCount: 7,
        ),
      ]);

      expect(snapshot.levelOverdueDayCount, 7);
      expect(snapshot.levelScheduleStatus, DeckScheduleStatus.overdue);
    });

    test('no due anywhere is zero days and notDue', () {
      final snapshot = level(<DeckSummary>[
        fakeSummary(id: 'b', name: 'B', totalCardCount: 10, newCardCount: 10),
      ]);

      expect(snapshot.levelOverdueDayCount, 0);
      expect(snapshot.levelScheduleStatus, DeckScheduleStatus.notDue);
    });

    test('due today on every subtree is dueToday, no days', () {
      final snapshot = level(<DeckSummary>[
        fakeSummary(id: 'b', name: 'B', totalCardCount: 10, dueCardCount: 2),
        fakeSummary(id: 'c', name: 'C', totalCardCount: 20, dueCardCount: 5),
      ]);

      expect(snapshot.levelDueCardCount, 7);
      expect(snapshot.levelOverdueDayCount, 0);
      expect(snapshot.levelScheduleStatus, DeckScheduleStatus.dueToday);
    });

    test('the partition sums across subtrees, and back to the total', () {
      // BR-162 at level scope: each child's halves sum to its total, so the
      // level's halves sum to the level's total — the identity the hero
      // renders three numbers from.
      final snapshot = level(<DeckSummary>[
        fakeSummary(
          id: 'b',
          name: 'B',
          totalCardCount: 10,
          dueCardCount: 5,
          overdueCardCount: 2,
          overdueDayCount: 3,
        ),
        fakeSummary(
          id: 'c',
          name: 'C',
          totalCardCount: 40,
          dueCardCount: 10,
          overdueCardCount: 6,
          overdueDayCount: 7,
        ),
      ]);

      expect(snapshot.levelOverdueCardCount, 8);
      expect(snapshot.levelDueTodayCardCount, 7);
      expect(
        snapshot.levelDueCardCount,
        snapshot.levelOverdueCardCount + snapshot.levelDueTodayCardCount,
      );
    });
  });

  group('the due partition on one summary (BR-162)', () {
    test('dueTodayCardCount is the arithmetic complement', () {
      final summary = fakeSummary(
        id: 'd1',
        name: 'Deck',
        totalCardCount: 60,
        dueCardCount: 15,
        overdueCardCount: 12,
        overdueDayCount: 7,
      );

      expect(summary.dueTodayCardCount, 3);
      expect(
        summary.dueCardCount,
        summary.overdueCardCount + summary.dueTodayCardCount,
      );
    });

    test('all-overdue leaves nothing for today', () {
      final summary = fakeSummary(
        id: 'd1',
        name: 'Deck',
        totalCardCount: 60,
        dueCardCount: 7,
        overdueCardCount: 7,
        overdueDayCount: 1,
      );

      expect(summary.dueTodayCardCount, 0);
    });

    test('scheduled closes the partition to the total', () {
      // The fourth set: every card is New, due (either half), or resting
      // until a later review — so the four figures the hero renders sum to
      // the deck.
      final summary = fakeSummary(
        id: 'd1',
        name: 'Deck',
        totalCardCount: 60,
        newCardCount: 20,
        dueCardCount: 15,
        overdueCardCount: 12,
        overdueDayCount: 7,
      );

      expect(summary.scheduledCardCount, 25);
      expect(
        summary.totalCardCount,
        summary.newCardCount +
            summary.overdueCardCount +
            summary.dueTodayCardCount +
            summary.scheduledCardCount,
      );
    });
  });

  group('overdueCountOf — the partition invariant', () {
    test('a count inside the total passes through', () {
      expect(overdueCountOf(dueCardCount: 15, overdueCardCount: 12), 12);
      expect(overdueCountOf(dueCardCount: 5, overdueCardCount: 0), 0);
    });

    test('an overdue half larger than the whole is rejected loudly', () {
      // One grouped subquery counts both halves, so production SQL cannot
      // produce this — only a fixture that set the two independently can,
      // and a silent clamp would render a negative "due today".
      expect(
        () => overdueCountOf(dueCardCount: 3, overdueCardCount: 4),
        throwsStateError,
      );
    });

    test('a negative count is rejected loudly', () {
      expect(
        () => overdueCountOf(dueCardCount: 3, overdueCardCount: -1),
        throwsStateError,
      );
    });
  });
  group('DeckSummary.scheduleStatus', () {
    test('no due cards is notDue, whatever else is true', () {
      final summary = fakeSummary(
        id: 'd1',
        name: 'Deck',
        totalCardCount: 20,
        newCardCount: 20,
      );

      expect(summary.scheduleStatus, DeckScheduleStatus.notDue);
    });

    test('due with zero overdue days is dueToday', () {
      final summary = fakeSummary(
        id: 'd1',
        name: 'Deck',
        totalCardCount: 20,
        dueCardCount: 5,
      );

      expect(summary.scheduleStatus, DeckScheduleStatus.dueToday);
    });

    test('one overdue day is overdue', () {
      final summary = fakeSummary(
        id: 'd1',
        name: 'Deck',
        totalCardCount: 20,
        dueCardCount: 5,
        overdueDayCount: 1,
      );

      expect(summary.scheduleStatus, DeckScheduleStatus.overdue);
    });

    test('many overdue days is still overdue', () {
      final summary = fakeSummary(
        id: 'd1',
        name: 'Deck',
        totalCardCount: 20,
        dueCardCount: 5,
        overdueDayCount: 120,
      );

      expect(summary.scheduleStatus, DeckScheduleStatus.overdue);
    });
  });

  group('overdueDaysOf — the mapper invariant', () {
    final day = LocalDayModel(
      now: DateTime.utc(2026, 8, 11, 12),
      utcOffset: Duration.zero,
    );

    test('no due cards is zero, and the instant is not consulted', () {
      expect(overdueDaysOf(day, dueCardCount: 0, oldestDueAt: null), 0);
    });

    test('cannot go negative: a future oldest instant clamps to zero', () {
      expect(
        overdueDaysOf(
          day,
          dueCardCount: 3,
          oldestDueAt: DateTime.utc(2026, 8, 11, 13),
        ),
        0,
      );
    });

    test(
      'a due count with no instant is an inconsistent read, said loudly',
      () {
        // The two ride one grouped subquery, so production SQL cannot produce
        // this pair — only a fixture that skipped half the aggregate can, and a
        // silent zero would render a healthy-looking deck over a broken read.
        expect(
          () => overdueDaysOf(day, dueCardCount: 3, oldestDueAt: null),
          throwsStateError,
        );
      },
    );
  });
}
