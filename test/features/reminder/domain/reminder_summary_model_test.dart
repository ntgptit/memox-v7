import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminder/domain/models/reminder_summary_model.dart';
import 'package:memox/features/reminder/domain/models/reminder_workload_model.dart';

/// BR-184's skip, BR-186's content limit, BR-187's ordering and BR-188's count,
/// all of which live in one pure function.
ReminderWorkloadModel deck(
  String id, {
  String? name,
  int overdue = 0,
  int dueToday = 0,
  int overdueDays = 0,
}) => ReminderWorkloadModel(
  deckId: id,
  deckName: name ?? id,
  overdueCount: overdue,
  dueTodayCount: dueToday,
  overdueDayCount: overdueDays,
);

void main() {
  group('build', () {
    test('nothing owed produces no summary at all (BR-184)', () {
      // `null` rather than a zeroed summary: there must be no object a caller
      // could show by accident.
      expect(
        ReminderSummaryModel.build(const <ReminderWorkloadModel>[]),
        isNull,
      );
      expect(
        ReminderSummaryModel.build(<ReminderWorkloadModel>[deck('a')]),
        isNull,
      );
    });

    test('the total is the sum of every deck, counted once (BR-188)', () {
      final summary = ReminderSummaryModel.build(<ReminderWorkloadModel>[
        deck('a', overdue: 3, dueToday: 2),
        deck('b', dueToday: 4),
      ]);

      expect(summary!.totalDueCount, 9);
    });

    test('one deck owing means no "and N more" tail', () {
      final summary = ReminderSummaryModel.build(<ReminderWorkloadModel>[
        deck('a', name: 'Kanji', dueToday: 5),
        deck('b', name: 'Idle'),
      ]);

      expect(summary!.leadDeckName, 'Kanji');
      expect(summary.otherDeckCount, 0);
    });

    test('other decks are counted, never named', () {
      final summary = ReminderSummaryModel.build(<ReminderWorkloadModel>[
        deck('a', name: 'A', overdue: 9),
        deck('b', name: 'B', dueToday: 1),
        deck('c', name: 'C', dueToday: 1),
      ]);

      expect(summary!.leadDeckName, 'A');
      expect(summary.otherDeckCount, 2);
    });
  });

  group('compareUrgency (BR-187)', () {
    List<String> rank(List<ReminderWorkloadModel> decks) =>
        (decks.toList()..sort(ReminderSummaryModel.compareUrgency))
            .map((entry) => entry.deckId)
            .toList();

    test('more overdue outranks everything else', () {
      expect(
        rank(<ReminderWorkloadModel>[
          deck('few', overdue: 1, dueToday: 900, overdueDays: 900),
          deck('many', overdue: 2),
        ]),
        <String>['many', 'few'],
      );
    });

    test('equal overdue counts break on the older overdue', () {
      expect(
        rank(<ReminderWorkloadModel>[
          deck('fresh', overdue: 4, overdueDays: 1, dueToday: 50),
          deck('stale', overdue: 4, overdueDays: 9),
        ]),
        <String>['stale', 'fresh'],
      );
    });

    test('then on due-today, then on name, then on id', () {
      expect(
        rank(<ReminderWorkloadModel>[
          deck('x', dueToday: 1),
          deck('y', dueToday: 2),
        ]),
        <String>['y', 'x'],
      );
      expect(
        rank(<ReminderWorkloadModel>[
          deck('id-b', name: 'Beta', dueToday: 1),
          deck('id-a', name: 'Alpha', dueToday: 1),
        ]),
        <String>['id-a', 'id-b'],
      );
      expect(
        rank(<ReminderWorkloadModel>[
          deck('id-z', name: 'Same', dueToday: 1),
          deck('id-a', name: 'Same', dueToday: 1),
        ]),
        <String>['id-a', 'id-z'],
      );
    });

    test('the lead deck does not depend on the order it arrived in', () {
      // The point of a total order: no tie is left to whatever the query
      // planner returned.
      final decks = <ReminderWorkloadModel>[
        deck('id-a', name: 'Same', overdue: 2, overdueDays: 3),
        deck('id-b', name: 'Same', overdue: 2, overdueDays: 3),
        deck('id-c', name: 'Same', overdue: 2, overdueDays: 3),
      ];

      expect(
        ReminderSummaryModel.build(decks)!.leadDeckName,
        ReminderSummaryModel.build(decks.reversed.toList())!.leadDeckName,
      );
      expect(rank(decks), rank(decks.reversed.toList()));
    });
  });
}
