import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_day_model.dart';

/// BR-105: the due moment is midnight local time of the Nth day, stored as UTC.
///
/// **The cases that matter are all at the edges.** Midday arithmetic works under
/// either reading of the rule; what separates them is 23:59, a negative offset,
/// and the difference between "N days of 24 hours" and "the start of the Nth
/// day".
void main() {
  // UTC+7, the app's first market.
  const vietnam = Duration(hours: 7);

  StudyDayModel dayAt(String iso, [Duration offset = vietnam]) =>
      StudyDayModel(now: DateTime.parse(iso), utcOffset: offset);

  group('the start of a day', () {
    test('midnight local is 17:00 UTC the day before, at UTC+7', () {
      // Someone studying at 09:00 Hanoi time on the 7th: tomorrow starts at
      // 00:00 on the 8th locally, which is 17:00 UTC on the 7th.
      expect(
        dayAt('2026-08-07T02:00:00Z').startOfDayAfter(1),
        DateTime.utc(2026, 8, 7, 17),
      );
    });

    test('day 0 is the start of today, not this moment', () {
      expect(
        dayAt('2026-08-07T02:00:00Z').startOfToday,
        DateTime.utc(2026, 8, 6, 17),
      );
    });
  });

  group('the boundary the rule exists for', () {
    test('23:59 local and 00:01 local land a day apart', () {
      // The case `now + N × 24h` gets wrong twice over. Two people answering
      // two minutes apart are on different study days, and that is correct —
      // but under the naive rule they would be scheduled two minutes apart
      // instead, at a time of night neither of them studies.
      final lateNight = dayAt('2026-08-07T16:59:00Z'); // 23:59 local on the 7th
      final justAfter = dayAt('2026-08-07T17:01:00Z'); // 00:01 local on the 8th

      expect(lateNight.startOfDayAfter(1), DateTime.utc(2026, 8, 7, 17));
      expect(justAfter.startOfDayAfter(1), DateTime.utc(2026, 8, 8, 17));
      expect(
        justAfter.startOfDayAfter(1).difference(lateNight.startOfDayAfter(1)),
        const Duration(days: 1),
      );
    });

    test('two answers on the same day get the same due moment', () {
      // The property that makes a due count stable: everything answered today
      // comes back at one moment, not scattered across tomorrow by the hour it
      // happened to be answered at.
      final morning = dayAt('2026-08-07T01:00:00Z').startOfDayAfter(1);
      final evening = dayAt('2026-08-07T14:00:00Z').startOfDayAfter(1);

      expect(morning, evening);
    });
  });

  group('offsets other than the default', () {
    test('a negative offset still anchors to local midnight', () {
      // UTC−5. 01:00 UTC on the 7th is 20:00 local on the *6th*, so the next
      // local day starts at 00:00 on the 7th — 05:00 UTC on the 7th, not the
      // 8th. Reading the UTC date as though it were the local one is the whole
      // mistake this class exists to make impossible.
      expect(
        dayAt(
          '2026-08-07T01:00:00Z',
          const Duration(hours: -5),
        ).startOfDayAfter(1),
        DateTime.utc(2026, 8, 7, 5),
      );
    });

    test('UTC itself is the simple case, and still not now + 24h', () {
      expect(
        dayAt('2026-08-07T09:30:00Z', Duration.zero).startOfDayAfter(1),
        DateTime.utc(2026, 8, 8),
      );
    });

    test('a half-hour offset works, because the offset is a duration', () {
      // India is UTC+5:30. An implementation that stored whole hours would be
      // half a day out here.
      expect(
        dayAt(
          '2026-08-07T02:00:00Z',
          const Duration(hours: 5, minutes: 30),
        ).startOfDayAfter(1),
        DateTime.utc(2026, 8, 7, 18, 30),
      );
    });
  });

  group('intervals the scheduler actually returns', () {
    test('the eight-box ladder lands on eight distinct midnights', () {
      final day = dayAt('2026-08-07T02:00:00Z');
      final moments = <int>[
        1,
        2,
        4,
        8,
        16,
        32,
        64,
        128,
      ].map(day.startOfDayAfter).toList();

      // Every one of them at the same wall-clock time, which is what a due
      // count needs to be readable.
      for (final moment in moments) {
        expect(moment.hour, 17);
        expect(moment.minute, 0);
      }
      expect(moments.toSet(), hasLength(8));
    });

    test('128 days out crosses months and still lands at midnight', () {
      expect(
        dayAt('2026-08-07T02:00:00Z').startOfDayAfter(128),
        DateTime.utc(2026, 12, 12, 17),
      );
    });
  });
}
