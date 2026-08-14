import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/time/local_day_model.dart';
import 'progress_activity_day_model.dart';

part 'progress_overview_model.freezed.dart';

/// How many days the activity chart shows, including today (BR-186).
const int kProgressWindowDays = 7;

/// Everything the Progress screen shows, from one read at one instant (UC-12).
///
/// **One snapshot, not three reads.** Streak, today and the seven-day window
/// answer the same question at three zoom levels, and they have to agree: read
/// separately, an answer written between two of them makes today say 8 while
/// the last bar of the chart says 7 — a contradiction the user can see on one
/// screen. AD-13 states the rule; this type is what makes obeying it the
/// default, because there is nowhere to put a second read.
@freezed
abstract class ProgressOverview with _$ProgressOverview {
  const factory ProgressOverview({
    /// Exactly [kProgressWindowDays] entries, oldest first, ending on today
    /// (BR-186). Days with no activity are present with zeros — they are data,
    /// not gaps.
    required List<ProgressActivityDay> lastSevenDays,

    /// Consecutive local days of activity ending at the anchor (BR-187).
    ///
    /// The anchor is today when today is active, and yesterday when it is not
    /// but yesterday is. Zero when neither is. Deliberately uncapped: a streak
    /// longer than the chart is still the streak, and clamping it to the window
    /// would make the number quietly wrong for exactly the users it matters
    /// most to.
    required int currentStreakDays,

    /// Whether the user has **ever** answered a card.
    ///
    /// Not derivable from [lastSevenDays]: somebody who studied hard for a
    /// month and then stopped for a fortnight has an empty window and a full
    /// history, and the screen owes those two people different words — an
    /// invitation to start versus a quiet week. It is also not derivable from
    /// [currentStreakDays], which is zero in both cases.
    required bool hasLifetimeActivity,

    /// Local midnight ahead of the read's `now` — the instant this whole
    /// snapshot expires (BR-189).
    ///
    /// Carried on the snapshot rather than recomputed by the controller for the
    /// AD-13 reason above: the boundary the timer waits for has to be the one
    /// the numbers were measured against, or a rollover re-reads at an instant
    /// that has already moved on.
    required DateTime nextLocalMidnight,
  }) = _ProgressOverview;

  const ProgressOverview._();

  /// Today, which is always the last entry of the window (BR-186).
  ProgressActivityDay get today => lastSevenDays.last;

  /// True when the streak is being held by yesterday rather than by today
  /// (BR-187) — the state that needs its own sentence on screen, because a
  /// user who sees "7 days" beside "0 cards today" would otherwise read the
  /// two as contradicting each other.
  bool get isStreakHeldFromYesterday =>
      currentStreakDays > 0 && !today.isActive;

  /// Assembles the snapshot from the days that actually had activity.
  ///
  /// [activityDays] is every local day the user has ever answered a card on,
  /// ascending, one entry per day and none of them empty — which is exactly
  /// what the SQL aggregate produces. Nothing here re-reads a clock: [day]
  /// carries the single `now`/offset snapshot the whole emission is measured
  /// against (BR-184).
  ///
  /// **The full history is the input, not the window.** The streak has no cap
  /// (BR-187), so it cannot be computed from seven days; and "has ever studied"
  /// (BR-186's empty case) cannot either. Passing the window and asking for
  /// both was the first shape of this function, and it answered "1 day" for a
  /// user on day 300 of a streak.
  static ProgressOverview fromActivity({
    required List<ProgressActivityDay> activityDays,
    required LocalDayModel day,
  }) {
    // `startOfToday` is the UTC instant of local midnight; adding the offset
    // back re-labels it as the local calendar date, at 00:00, still UTC-flagged.
    // Same construction as `ProgressActivityDay.localDate`, so the two compare
    // exactly — which is the whole mechanism behind the lookups below.
    final DateTime todayDate = day.startOfToday.add(day.utcOffset);

    final Map<DateTime, ProgressActivityDay> byDate =
        <DateTime, ProgressActivityDay>{
          for (final ProgressActivityDay entry in activityDays)
            entry.localDate: entry,
        };

    return ProgressOverview(
      lastSevenDays: _window(byDate, todayDate),
      currentStreakDays: _streak(byDate, todayDate),
      hasLifetimeActivity: activityDays.isNotEmpty,
      nextLocalMidnight: day.startOfTomorrow,
    );
  }

  /// Seven entries, oldest first, zero-filled (BR-186).
  ///
  /// Built by subtracting whole days from a UTC-flagged date, so a window that
  /// spans the end of a month, the end of a year or a leap day is ordinary
  /// arithmetic rather than a special case.
  static List<ProgressActivityDay> _window(
    Map<DateTime, ProgressActivityDay> byDate,
    DateTime todayDate,
  ) => List<ProgressActivityDay>.generate(kProgressWindowDays, (int index) {
    final DateTime date = todayDate.subtract(
      Duration(days: kProgressWindowDays - 1 - index),
    );

    return byDate[date] ??
        ProgressActivityDay(localDate: date, totalCards: 0, learningCards: 0);
  }, growable: false);

  /// Consecutive active days ending at today, or at yesterday (BR-187).
  static int _streak(
    Map<DateTime, ProgressActivityDay> byDate,
    DateTime todayDate,
  ) {
    final DateTime yesterday = todayDate.subtract(const Duration(days: 1));

    // Today first, then yesterday. A day of rest does not end a streak — it
    // stops extending one — so the anchor moves back at most one day and never
    // further: two idle days is a streak of zero, not a streak that ended
    // whenever the user last studied.
    final DateTime? anchor = byDate.containsKey(todayDate)
        ? todayDate
        : byDate.containsKey(yesterday)
        ? yesterday
        : null;
    if (anchor == null) return 0;

    int days = 0;
    DateTime cursor = anchor;
    while (byDate.containsKey(cursor)) {
      days++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return days;
  }
}
