import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/local_day_model.dart';
import 'package:memox/features/progress/domain/models/progress_activity_day_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

/// `ProgressOverview.fromActivity` — the window, the zero-fill and the streak
/// (BR-186, BR-187), with no database and no clock anywhere near it.
///
/// These are the rules that would be hardest to see going wrong in production:
/// a streak that silently caps at seven, a window that loses a day at the end of
/// a month, an offset that puts an answer in the wrong day. Each of them
/// produces a plausible number, so nothing downstream would notice.
void main() {
  /// Midday UTC, so a positive and a negative offset both stay inside the same
  /// UTC day and the local-day arithmetic is the only thing being measured.
  final DateTime noon = DateTime.utc(2026, 8, 12, 12);

  LocalDayModel dayAt(DateTime now, {Duration offset = Duration.zero}) =>
      LocalDayModel(now: now, utcOffset: offset);

  ProgressActivityDay activity(
    DateTime date, {
    int total = 1,
    int learning = 0,
  }) => ProgressActivityDay(
    localDate: date,
    totalCards: total,
    learningCards: learning,
  );

  DateTime date(int year, int month, int day) => DateTime.utc(year, month, day);

  group('the seven-day window', () {
    test('is seven entries, oldest first, ending today', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[activity(date(2026, 8, 12))],
        day: dayAt(noon),
      );

      expect(overview.lastSevenDays, hasLength(kProgressWindowDays));
      expect(overview.lastSevenDays.first.localDate, date(2026, 8, 6));
      expect(overview.lastSevenDays.last.localDate, date(2026, 8, 12));
      expect(overview.today, same(overview.lastSevenDays.last));
    });

    test('zero-fills a day with no activity instead of dropping it', () {
      // The bug this catches is a window built by mapping the rows: it would
      // return two entries here and the chart would silently show a two-day
      // week, which reads as "quiet" rather than as broken.
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[
          activity(date(2026, 8, 8), total: 4),
          activity(date(2026, 8, 12), total: 9),
        ],
        day: dayAt(noon),
      );

      expect(overview.lastSevenDays.map((day) => day.totalCards), <int>[
        0,
        0,
        4,
        0,
        0,
        0,
        9,
      ]);
      expect(
        overview.lastSevenDays.every((day) => day.learningCards >= 0),
        isTrue,
      );
    });

    test('ignores activity older than the window without losing it from the '
        'streak', () {
      // The two consumers of the same list read different amounts of it, and
      // getting that wrong in either direction is a real bug: a window that
      // included the older day would be eight long, and a streak computed from
      // the window alone would say 7 for a 10-day run.
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[
          for (int back = 9; back >= 0; back--)
            activity(date(2026, 8, 12).subtract(Duration(days: back))),
        ],
        day: dayAt(noon),
      );

      expect(overview.lastSevenDays, hasLength(kProgressWindowDays));
      expect(overview.currentStreakDays, 10);
    });

    test('crosses the end of a month', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[activity(date(2026, 3, 1))],
        day: dayAt(DateTime.utc(2026, 3, 1, 12)),
      );

      expect(overview.lastSevenDays.first.localDate, date(2026, 2, 23));
      expect(overview.lastSevenDays[5].localDate, date(2026, 2, 28));
      expect(overview.lastSevenDays.last.localDate, date(2026, 3, 1));
    });

    test('crosses the end of a year', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[activity(date(2026, 1, 1))],
        day: dayAt(DateTime.utc(2026, 1, 1, 12)),
      );

      expect(overview.lastSevenDays.first.localDate, date(2025, 12, 26));
      expect(overview.lastSevenDays.last.localDate, date(2026, 1, 1));
    });
  });

  group('the UTC offset decides which day "today" is', () {
    test('an instant just before local midnight east of Greenwich belongs to '
        'the day the user is in', () {
      // 22:00 UTC on the 12th is 05:00 on the 13th in UTC+7. A window anchored
      // on the UTC date would end on the 12th and show the user's own morning
      // as "no activity yet" while they were looking at the cards they had
      // just answered.
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[activity(date(2026, 8, 13))],
        day: dayAt(
          DateTime.utc(2026, 8, 12, 22),
          offset: const Duration(hours: 7),
        ),
      );

      expect(overview.lastSevenDays.last.localDate, date(2026, 8, 13));
      expect(overview.today.totalCards, 1);
    });

    test('an instant just after UTC midnight west of Greenwich still belongs '
        'to yesterday', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[activity(date(2026, 8, 12))],
        day: dayAt(
          DateTime.utc(2026, 8, 13, 1),
          offset: const Duration(hours: -5),
        ),
      );

      expect(overview.lastSevenDays.last.localDate, date(2026, 8, 12));
      expect(overview.today.totalCards, 1);
    });
  });

  group('the streak', () {
    test('ends today when today is active', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[
          activity(date(2026, 8, 10)),
          activity(date(2026, 8, 11)),
          activity(date(2026, 8, 12)),
        ],
        day: dayAt(noon),
      );

      expect(overview.currentStreakDays, 3);
      expect(overview.isStreakHeldFromYesterday, isFalse);
    });

    test('is held from yesterday when today is not active yet', () {
      // A rest day does not end a streak — it stops extending one. Resetting to
      // zero at midnight would punish everyone who studies in the evening, for
      // the hours before they get to it.
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[
          activity(date(2026, 8, 10)),
          activity(date(2026, 8, 11)),
        ],
        day: dayAt(noon),
      );

      expect(overview.currentStreakDays, 2);
      expect(overview.isStreakHeldFromYesterday, isTrue);
    });

    test('is zero when neither today nor yesterday is active', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[
          activity(date(2026, 8, 9)),
          activity(date(2026, 8, 10)),
        ],
        day: dayAt(noon),
      );

      expect(overview.currentStreakDays, 0);
      expect(overview.isStreakHeldFromYesterday, isFalse);
    });

    test('stops at the first gap rather than counting every active day', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[
          activity(date(2026, 8, 1)),
          activity(date(2026, 8, 2)),
          activity(date(2026, 8, 3)),
          // the gap
          activity(date(2026, 8, 11)),
          activity(date(2026, 8, 12)),
        ],
        day: dayAt(noon),
      );

      expect(overview.currentStreakDays, 2);
    });

    test('has no upper bound', () {
      // 400 days is past every plausible cap somebody might have added "for
      // safety" — a year, the window, a month.
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[
          for (int back = 399; back >= 0; back--)
            activity(date(2026, 8, 12).subtract(Duration(days: back))),
        ],
        day: dayAt(noon),
      );

      expect(overview.currentStreakDays, 400);
    });

    test('is zero with no history at all', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: const <ProgressActivityDay>[],
        day: dayAt(noon),
      );

      expect(overview.currentStreakDays, 0);
      expect(overview.hasLifetimeActivity, isFalse);
      expect(
        overview.lastSevenDays.every((day) => day.totalCards == 0),
        isTrue,
      );
    });
  });

  group('lifetime activity', () {
    test('is true when history exists outside the window', () {
      // The case that cannot be derived from the window: a month of study, then
      // a fortnight off. An empty window here must not put the first-run
      // invitation in front of somebody with three hundred cards behind them.
      final overview = ProgressOverview.fromActivity(
        activityDays: <ProgressActivityDay>[activity(date(2026, 7, 1))],
        day: dayAt(noon),
      );

      expect(overview.hasLifetimeActivity, isTrue);
      expect(overview.currentStreakDays, 0);
      expect(
        overview.lastSevenDays.every((day) => day.totalCards == 0),
        isTrue,
      );
    });
  });

  group('the Learning / Reviewing partition', () {
    test('reviewing is the remainder, so the halves always sum to the total', () {
      // Derived rather than stored, which is what makes BR-185's identity true
      // by construction: two independently counted columns can disagree, and a
      // card answered both ways in one day is exactly where they would.
      final day = activity(date(2026, 8, 12), total: 9, learning: 4);

      expect(day.reviewingCards, 5);
      expect(day.learningCards + day.reviewingCards, day.totalCards);
    });

    test('a zero-filled day is not active', () {
      final overview = ProgressOverview.fromActivity(
        activityDays: const <ProgressActivityDay>[],
        day: dayAt(noon),
      );

      expect(overview.today.isActive, isFalse);
      expect(overview.today.reviewingCards, 0);
    });
  });

  test('the snapshot carries the midnight it expires at', () {
    final overview = ProgressOverview.fromActivity(
      activityDays: const <ProgressActivityDay>[],
      day: dayAt(noon, offset: const Duration(hours: 7)),
    );

    // 2026-08-13 00:00 in UTC+7 is 2026-08-12 17:00 UTC. Carrying the boundary
    // rather than recomputing it in the controller is what keeps the timer
    // waiting for the same midnight the numbers were measured against.
    expect(overview.nextLocalMidnight, DateTime.utc(2026, 8, 12, 17));
  });
}
