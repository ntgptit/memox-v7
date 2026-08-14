/// Minutes in a day. The upper bound of [ReminderTime] is one less than this.
const int kMinutesPerDay = 24 * 60;

/// BR-183's suggested time, 20:00 local, as a minute of the day.
const int kDefaultReminderMinute = 20 * 60;

/// A time of day the reminder may fire at, in **local** minutes (BR-183).
///
/// **The type is the check.** The settings repository takes a [ReminderTime],
/// not an `int`, so "has this been validated?" is answered by the signature —
/// the same reason `StudyCardLimit` and `DeckName` exist rather than a
/// `validateTime` somebody has to remember to call.
///
/// **Local, and deliberately not converted to UTC.** Every `DATETIME` in this
/// schema stores UTC because it stores an *instant*; this is a *time of day*.
/// Converting on write moves the reminder by exactly the offset change when the
/// user crosses a timezone — they set 20:00 and start getting it at 23:00, with
/// nothing to explain why. The conversion happens once, per schedule, against
/// the offset in force at that moment.
final class ReminderTime {
  const ReminderTime._(this.minuteOfDay);

  /// Minutes since local midnight, `0…kMinutesPerDay - 1`.
  final int minuteOfDay;

  /// BR-183's default, which needs no parsing.
  static const ReminderTime suggested = ReminderTime._(kDefaultReminderMinute);

  /// The hour part, `0…23`.
  int get hour => minuteOfDay ~/ 60;

  /// The minute part, `0…59`.
  int get minute => minuteOfDay % 60;

  /// Parses [rawMinuteOfDay], reporting the problem instead of throwing.
  ///
  /// Takes an `int` rather than a string because every caller already has one:
  /// a time picker returns hour and minute, and the database column is an
  /// integer. There is no "not a number at all" case to leave outside the type.
  static ({ReminderTime? time, ReminderTimeProblem? problem}) parse(
    int rawMinuteOfDay,
  ) {
    if (rawMinuteOfDay < 0 || rawMinuteOfDay >= kMinutesPerDay) {
      return (time: null, problem: ReminderTimeProblem.outOfRange);
    }

    return (time: ReminderTime._(rawMinuteOfDay), problem: null);
  }

  /// The same parse, expressed the way a time picker hands its result over.
  static ({ReminderTime? time, ReminderTimeProblem? problem}) fromHourMinute({
    required int hour,
    required int minute,
  }) {
    if (minute < 0 || minute >= 60) {
      return (time: null, problem: ReminderTimeProblem.outOfRange);
    }

    return parse(hour * 60 + minute);
  }

  /// The value already in the database, which is clamped rather than rejected.
  ///
  /// A stored value outside the range is not a reason to refuse to open the
  /// settings screen, and the clamp is visible the moment it does open — the
  /// same trade `StudyCardLimit.fromStored` makes.
  static ReminderTime fromStored(int stored) =>
      ReminderTime._(stored.clamp(0, kMinutesPerDay - 1));

  /// The next instant this time of day occurs at or after [now].
  ///
  /// **Both inputs are explicit** (AD-16): `now` comes from `clockProvider` and
  /// [utcOffset] from `utcOffsetProvider`, so nothing here reads the wall clock
  /// or the device zone and a 23:59 boundary is reproducible on any machine.
  ///
  /// Returns tomorrow's occurrence when today's has already passed, and today's
  /// when it lands exactly on [now] — "at or after", because a reconcile that
  /// runs in the same millisecond as the fire time should not skip a day.
  DateTime nextOccurrenceAfter(DateTime now, Duration utcOffset) {
    final local = now.toUtc().add(utcOffset);
    final midnightLocal = DateTime.utc(local.year, local.month, local.day);
    final todayLocal = midnightLocal.add(Duration(minutes: minuteOfDay));
    final today = todayLocal.subtract(utcOffset);
    if (!today.isBefore(now)) return today;

    return today.add(const Duration(days: 1));
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.minuteOfDay == minuteOfDay;

  @override
  int get hashCode => minuteOfDay.hashCode;

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

/// What was wrong with a proposed reminder time.
///
/// One value, and it stays an enum rather than becoming a `bool`: a second
/// reason will arrive the first time this is parsed from something other than a
/// picker, and a `bool` would have to be replaced at every call site.
enum ReminderTimeProblem { outOfRange }
