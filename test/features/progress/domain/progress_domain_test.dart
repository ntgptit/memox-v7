import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/deck_activity_metrics_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_order_model.dart';
import 'package:memox/features/progress/domain/models/progress_range_model.dart';

import '../support/progress_fixtures.dart';

/// The Progress rules that are pure arithmetic over a snapshot: the windows, the
/// partition, and the order the list is read in.
///
/// Everything that depends on what is *in the database* lives in
/// `test/features/progress/data/` against real SQLite. What is here needs no
/// database, and putting it here is what keeps those tests about queries.
void main() {
  group('the two windows (BR-194)', () {
    test('each spans whole days including today', () {
      expect(ProgressRange.last7Days.dayCount, 7);
      expect(ProgressRange.last30Days.dayCount, 30);
    });

    test('the window starts one day fewer than it spans', () {
      // The off-by-one that separates "the last seven days" from "the last
      // eight": today is one of the seven, so the window opens six boundaries
      // back.
      expect(ProgressRange.last7Days.daysBeforeToday, 6);
      expect(ProgressRange.last30Days.daysBeforeToday, 29);
    });

    test('the shorter window is the one shown first', () {
      expect(ProgressRange.initial, ProgressRange.last7Days);
    });

    test('there are exactly two, so a switch over them stays exhaustive', () {
      expect(ProgressRange.values, hasLength(2));
    });
  });

  group('the metrics (BR-193, BR-196)', () {
    test('the card-day total is the two halves of the partition', () {
      final metrics = activityMetrics(learning: 4, reviewing: 9);

      expect(metrics.cardDayCount, 13);
    });

    test(
      'activity is decided by the card count, which the sort also reads',
      () {
        expect(activityMetrics().hasActivity, isFalse);
        expect(activityMetrics(activeCards: 1).hasActivity, isTrue);
      },
    );

    test('zero is a value, not an absence', () {
      expect(DeckActivityMetrics.zero.cardDayCount, 0);
      expect(DeckActivityMetrics.zero.hasActivity, isFalse);
    });
  });

  group('a row answers to one window at a time', () {
    final row = deckActivity(
      deckId: 'd1',
      name: 'Spanish',
      last7Days: activityMetrics(activeCards: 3),
      last30Days: activityMetrics(activeCards: 40),
    );

    test('metricsFor returns the selected window', () {
      expect(row.metricsFor(ProgressRange.last7Days).activeCardCount, 3);
      expect(row.metricsFor(ProgressRange.last30Days).activeCardCount, 40);
    });

    test('the level answers to the same window as its rows', () {
      final snapshot = activitySnapshot(
        decks: <DeckActivity>[row],
        scopeLast7Days: activityMetrics(activeCards: 3),
        scopeLast30Days: activityMetrics(activeCards: 40),
      );

      expect(
        snapshot.scopeMetricsFor(ProgressRange.last30Days).activeCardCount,
        40,
      );
      expect(snapshot.hasActivityIn(ProgressRange.last7Days), isTrue);
    });

    test('a level with decks but no activity is not an empty level', () {
      final snapshot = activitySnapshot(
        decks: <DeckActivity>[deckActivity(deckId: 'd1', name: 'Spanish')],
      );

      // The two states need different words on screen: there is something to
      // measure, and nothing was measured.
      expect(snapshot.decks, isNotEmpty);
      expect(snapshot.hasActivityIn(ProgressRange.last7Days), isFalse);
    });

    test('the top level is the one with no deck of its own', () {
      expect(activitySnapshot(decks: <DeckActivity>[]).isTopLevel, isTrue);
      expect(
        activitySnapshot(
          decks: <DeckActivity>[],
          scopeDeckId: 'd1',
          scopeName: 'Spanish',
        ).isTopLevel,
        isFalse,
      );
    });
  });

  group('the order the list is read in (BR-197)', () {
    List<String> namesOf(List<DeckActivity> decks, ProgressRange range) =>
        sortDeckActivity(
          decks,
          range: range,
        ).map((DeckActivity d) => d.deckId).toList();

    test('busiest first', () {
      final decks = <DeckActivity>[
        deckActivity(
          deckId: 'quiet',
          name: 'Quiet',
          last7Days: activityMetrics(activeCards: 2),
        ),
        deckActivity(
          deckId: 'busy',
          name: 'Busy',
          last7Days: activityMetrics(activeCards: 40),
        ),
      ];

      expect(namesOf(decks, ProgressRange.last7Days), <String>[
        'busy',
        'quiet',
      ]);
    });

    test('zero-activity decks stay in the list, at the end', () {
      final decks = <DeckActivity>[
        deckActivity(deckId: 'idle', name: 'Idle'),
        deckActivity(
          deckId: 'busy',
          name: 'Busy',
          last7Days: activityMetrics(activeCards: 1),
        ),
      ];

      // Hiding them would answer "which decks have I neglected" by removing the
      // answer.
      expect(namesOf(decks, ProgressRange.last7Days), <String>['busy', 'idle']);
    });

    test('ties break on the folded name, with full Unicode folding', () {
      // SQLite's `lower()` folds ASCII only, so sorting in SQL would put `Động`
      // and `động` in different places while `Verbs` and `verbs` sorted
      // together — one alphabet behaving differently from another.
      final decks = <DeckActivity>[
        deckActivity(deckId: 'd2', name: 'động từ'),
        deckActivity(deckId: 'd1', name: 'Động từ'),
      ];

      final sorted = sortDeckActivity(decks, range: ProgressRange.last7Days);

      expect(foldDeckName('Động từ'), foldDeckName('động từ'));
      // Folded equal, so the id decides — and it decides the same way every
      // time, which is the whole point.
      expect(sorted.first.deckId, 'd1');
    });

    test('the id is the last resort, so the order never wobbles', () {
      final decks = <DeckActivity>[
        deckActivity(deckId: 'z', name: 'Same'),
        deckActivity(deckId: 'a', name: 'Same'),
        deckActivity(deckId: 'm', name: 'Same'),
      ];

      expect(namesOf(decks, ProgressRange.last7Days), <String>['a', 'm', 'z']);
    });

    test('fifty idle decks sort into the same order every time', () {
      // The failure this rule exists to stop: with no tie-break the order is
      // whatever the sort did with the input, so the list reshuffles itself on
      // every re-read under a screen nobody touched.
      final decks = <DeckActivity>[
        for (var i = 0; i < 50; i++)
          deckActivity(deckId: 'deck-$i', name: 'Deck'),
      ];

      expect(
        namesOf(decks, ProgressRange.last7Days),
        namesOf(decks.reversed.toList(), ProgressRange.last7Days),
      );
    });

    test('the order follows the selected window', () {
      // A deck can be the busiest of the week and the quietest of the month.
      // Sorting by a window the screen is not showing would contradict the
      // figures printed on the rows.
      final decks = <DeckActivity>[
        deckActivity(
          deckId: 'sprint',
          name: 'Sprint',
          last7Days: activityMetrics(activeCards: 30),
          last30Days: activityMetrics(activeCards: 31),
        ),
        deckActivity(
          deckId: 'steady',
          name: 'Steady',
          last7Days: activityMetrics(activeCards: 5),
          last30Days: activityMetrics(activeCards: 90),
        ),
      ];

      expect(namesOf(decks, ProgressRange.last7Days), <String>[
        'sprint',
        'steady',
      ]);
      expect(namesOf(decks, ProgressRange.last30Days), <String>[
        'steady',
        'sprint',
      ]);
    });

    test('the input list is left alone', () {
      // It comes off a stream and may be held by something else.
      final decks = <DeckActivity>[
        deckActivity(
          deckId: 'quiet',
          name: 'Quiet',
          last7Days: activityMetrics(activeCards: 1),
        ),
        deckActivity(
          deckId: 'busy',
          name: 'Busy',
          last7Days: activityMetrics(activeCards: 9),
        ),
      ];

      sortDeckActivity(decks, range: ProgressRange.last7Days);

      expect(decks.first.deckId, 'quiet');
    });

    test('an empty list sorts to an empty list', () {
      expect(
        sortDeckActivity(const <DeckActivity>[], range: ProgressRange.initial),
        isEmpty,
      );
    });
  });
}
