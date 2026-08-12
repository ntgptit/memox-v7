/// Local calendar-day arithmetic over an explicit clock and offset (BR-105).
///
/// **Feature-neutral on purpose.** The study day (BR-105) and the deck list's
/// overdue badge (BR-161) ask the same two questions — where does the current
/// local day start, and how many day boundaries lie between two instants — and
/// two implementations of midnight is how one screen says "due today" while
/// another says "1 day overdue" about the same card. `StudyDayModel` delegates
/// here; Deck's mapper reads it directly.
///
/// **Both inputs are explicit.** `now` comes from `clockProvider` and the
/// offset from `utcOffsetProvider`, resolved by the composition root (AD-16):
/// nothing here reads the wall clock or the device zone, which is what makes
/// 23:59-boundary tests reproducible on any machine.
///
/// Daylight saving is deliberately not modelled. The offset is resolved once
/// per call by whoever constructs this, so a device that has just changed
/// season is already carrying the new offset — modelling the transition here
/// would need a timezone database the app does not ship.
final class LocalDayModel {
  const LocalDayModel({required this.now, required this.utcOffset});

  /// The moment the calculation is anchored to, in UTC.
  final DateTime now;

  /// Local time minus UTC. Positive east of Greenwich.
  final Duration utcOffset;

  /// Midnight, local time, of the day [days] after today — as a UTC instant.
  ///
  /// `days: 0` is the start of today; `days: 1` is the boundary the overdue
  /// badge waits for.
  DateTime startOfDayAfter(int days) {
    final local = now.toUtc().add(utcOffset);

    // Constructed as UTC and then shifted back, rather than built as a local
    // `DateTime`: `DateTime(y, m, d)` uses the *host's* zone, which in a test
    // is whatever machine happens to run it. Building the arithmetic out of a
    // UTC value and one explicit offset is what makes 23:59 reproducible.
    final midnightLocal = DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).add(Duration(days: days));

    return midnightLocal.subtract(utcOffset);
  }

  /// The start of the current local day.
  DateTime get startOfToday => startOfDayAfter(0);

  /// The start of the next local day — the instant "due today" becomes
  /// "1 day overdue" with no database write in between (BR-161).
  DateTime get startOfTomorrow => startOfDayAfter(1);

  /// How many **completed local day boundaries** lie between [instant] and
  /// now — the number the overdue badge shows (BR-161).
  ///
  /// Calendar days, not `difference().inHours ~/ 24`: a card due at 23:00
  /// yesterday is one day overdue at 01:00 today even though only two hours
  /// have passed, because the schedule is anchored to local midnight (BR-105)
  /// and the person experiences "yesterday's card", not "a card from two
  /// hours ago".
  ///
  /// Never negative: an instant later today — or in the future — is zero
  /// boundaries behind, not a negative debt.
  int completedDaysSince(DateTime instant) {
    final local = instant.toUtc().add(utcOffset);
    final instantMidnight = DateTime.utc(local.year, local.month, local.day);
    final todayLocal = now.toUtc().add(utcOffset);
    final todayMidnight = DateTime.utc(
      todayLocal.year,
      todayLocal.month,
      todayLocal.day,
    );

    final days = todayMidnight.difference(instantMidnight).inDays;

    return days > 0 ? days : 0;
  }
}
