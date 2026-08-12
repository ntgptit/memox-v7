import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/local_day_model.dart';

/// The calendar arithmetic under the overdue badge (BR-161) and the study day
/// (BR-105) — one implementation, tested at the boundaries where naive
/// hour-division goes wrong.
///
/// Every case pins an explicit UTC `now` and offset, so nothing here depends
/// on the zone of the machine running the suite.
void main() {
  group('completedDaysSince', () {
    test('due earlier today is zero days — not one, not negative', () {
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 11, 14), // 21:00 local at +7
        utcOffset: const Duration(hours: 7),
      );

      expect(day.completedDaysSince(DateTime.utc(2026, 8, 11, 1)), 0);
    });

    test('due yesterday is one day, even two hours apart', () {
      // 23:00 local yesterday vs 01:00 local today: two hours of clock time,
      // one crossed midnight. Hour-division would say zero; the person
      // experiences "yesterday's card".
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 10, 18), // 01:00 local Aug 11 at +7
        utcOffset: const Duration(hours: 7),
      );

      expect(
        day.completedDaysSince(DateTime.utc(2026, 8, 10, 16)), // 23:00 Aug 10
        1,
      );
    });

    test('seven local calendar days is seven', () {
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 11, 12),
        utcOffset: const Duration(hours: 7),
      );

      expect(day.completedDaysSince(DateTime.utc(2026, 8, 4, 12)), 7);
    });

    test('a negative offset counts by its own calendar', () {
      // 20:00 UTC on Aug 10 is 15:00 local Aug 10 at -5; a card due at
      // 03:00 UTC Aug 10 was 22:00 local Aug 9 — one local day behind, even
      // though both instants share a UTC date boundary story of their own.
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 10, 20),
        utcOffset: const Duration(hours: -5),
      );

      expect(day.completedDaysSince(DateTime.utc(2026, 8, 10, 3)), 1);
    });

    test('a future instant is zero, never negative', () {
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 11, 12),
        utcOffset: Duration.zero,
      );

      expect(day.completedDaysSince(DateTime.utc(2026, 8, 20)), 0);
    });

    test('one minute before local midnight still counts today', () {
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 11, 16, 59), // 23:59 local at +7
        utcOffset: const Duration(hours: 7),
      );

      expect(day.completedDaysSince(DateTime.utc(2026, 8, 11, 1)), 0);
    });

    test('one minute after local midnight counts one', () {
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 11, 17, 1), // 00:01 local Aug 12 at +7
        utcOffset: const Duration(hours: 7),
      );

      expect(day.completedDaysSince(DateTime.utc(2026, 8, 11, 1)), 1);
    });
  });

  group('startOfTomorrow', () {
    test('is the next local midnight as a UTC instant', () {
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 11, 14), // 21:00 local at +7
        utcOffset: const Duration(hours: 7),
      );

      // Local midnight Aug 12 at +7 is 17:00 UTC Aug 11.
      expect(day.startOfTomorrow, DateTime.utc(2026, 8, 11, 17));
    });

    test('agrees with startOfDayAfter(1) west of Greenwich', () {
      final day = LocalDayModel(
        now: DateTime.utc(2026, 8, 11, 2), // 21:00 local Aug 10 at -5
        utcOffset: const Duration(hours: -5),
      );

      // Local midnight Aug 11 at -5 is 05:00 UTC Aug 11.
      expect(day.startOfTomorrow, DateTime.utc(2026, 8, 11, 5));
      expect(day.startOfTomorrow, day.startOfDayAfter(1));
    });
  });
}
