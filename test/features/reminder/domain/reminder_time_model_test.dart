import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminder/domain/models/reminder_time_model.dart';

/// The value object that makes BR-183's range unskippable, and the one piece of
/// clock arithmetic the feature owns.
void main() {
  group('parse', () {
    test('accepts both ends of the day and rejects one past either', () {
      expect(ReminderTime.parse(0).time?.minuteOfDay, 0);
      expect(ReminderTime.parse(kMinutesPerDay - 1).time?.minuteOfDay, 1439);

      expect(ReminderTime.parse(-1).problem, ReminderTimeProblem.outOfRange);
      expect(
        ReminderTime.parse(kMinutesPerDay).problem,
        ReminderTimeProblem.outOfRange,
      );
    });

    test('a rejected value yields no time at all', () {
      // The pair is either-or by construction; a caller that only checked the
      // problem must not be able to find a value beside it.
      expect(ReminderTime.parse(5000).time, isNull);
      expect(ReminderTime.parse(600).problem, isNull);
    });

    test('fromHourMinute rejects a minute outside 0..59', () {
      expect(
        ReminderTime.fromHourMinute(hour: 20, minute: 60).problem,
        ReminderTimeProblem.outOfRange,
      );
      expect(
        ReminderTime.fromHourMinute(hour: 20, minute: 0).time,
        ReminderTime.suggested,
      );
    });

    test('the suggested default is 20:00 (BR-183)', () {
      expect(ReminderTime.suggested.hour, 20);
      expect(ReminderTime.suggested.minute, 0);
      expect(ReminderTime.suggested.minuteOfDay, kDefaultReminderMinute);
    });

    test('a stored value out of range is clamped, not rejected', () {
      // Refusing to open the settings screen over a bad row would leave the
      // user with no way to fix it.
      expect(ReminderTime.fromStored(-10).minuteOfDay, 0);
      expect(ReminderTime.fromStored(99999).minuteOfDay, 1439);
    });
  });

  group('nextOccurrenceAfter', () {
    // +07:00, so a UTC instant and its local reading differ by enough that a
    // mistake shows up as the wrong day rather than the wrong minute.
    const offset = Duration(hours: 7);
    final time = ReminderTime.parse(20 * 60).time!;

    test('today, when the time is still ahead in local terms', () {
      // 10:00 local on 2026-07-29.
      final now = DateTime.utc(2026, 7, 29, 3);

      expect(
        time.nextOccurrenceAfter(now, offset),
        DateTime.utc(2026, 7, 29, 13),
      );
    });

    test('tomorrow, once the time has passed', () {
      // 21:00 local on 2026-07-29.
      final now = DateTime.utc(2026, 7, 29, 14);

      expect(
        time.nextOccurrenceAfter(now, offset),
        DateTime.utc(2026, 7, 30, 13),
      );
    });

    test('now, when the fire instant is exactly now', () {
      // "At or after": a reconcile running in the same millisecond as the fire
      // time must not skip a day.
      final now = DateTime.utc(2026, 7, 29, 13);

      expect(time.nextOccurrenceAfter(now, offset), now);
    });

    test(
      'the same wall-clock time in a different zone is a different instant',
      () {
        // The whole reason BR-183 stores a local minute rather than a UTC one: a
        // device that moves keeps 20:00 and changes which instant that is.
        final now = DateTime.utc(2026, 7, 29, 3);

        expect(
          time.nextOccurrenceAfter(now, const Duration(hours: 2)),
          DateTime.utc(2026, 7, 29, 18),
        );
        expect(
          time.nextOccurrenceAfter(now, const Duration(hours: -5)),
          DateTime.utc(2026, 7, 30, 1),
        );
      },
    );

    test('a local midnight reminder resolves on the local calendar day', () {
      final midnight = ReminderTime.parse(0).time!;
      // 22:00 local on 2026-07-29, which is already 2026-07-30 in UTC.
      final now = DateTime.utc(2026, 7, 29, 15);

      expect(
        midnight.nextOccurrenceAfter(now, offset),
        DateTime.utc(2026, 7, 29, 17),
      );
    });
  });
}
