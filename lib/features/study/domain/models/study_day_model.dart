/// Turns "N days from now" into the moment BR-105 actually means.
///
/// **The due moment is 00:00 local time of the Nth day, stored as UTC** — not
/// `now + N × 24h`. The difference shows up every time somebody studies in the
/// evening: with the naive arithmetic a card answered at 21:00 comes back at
/// 21:00, so a person who studies at 20:00 the next day finds it not due yet,
/// and the day after that it has drifted an hour further.
///
/// **The offset comes from the composition root**, the same way `clockProvider`
/// does (AD-16). `domain/` may not read the device timezone any more than it may
/// read the wall clock; both are inputs.
///
/// Daylight saving is deliberately not modelled here. The offset is resolved
/// once per call by whoever constructs this, so a device that has just changed
/// season is already carrying the new offset — modelling the transition inside
/// this class would need a timezone database that the app does not ship.
final class StudyDayModel {
  const StudyDayModel({required this.now, required this.utcOffset});

  /// The moment the calculation is anchored to, in UTC.
  final DateTime now;

  /// Local time minus UTC. Positive east of Greenwich.
  final Duration utcOffset;

  /// Midnight, local time, of the day [days] after today — as a UTC instant.
  ///
  /// `days: 0` is the start of today, which is what a session uses to decide
  /// whether a session left open belongs to an earlier study day (BR-103).
  /// `days: 1` is tomorrow, where a card lands when it finishes the learning
  /// chain (BR-144).
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

  /// The start of the current study day (BR-105).
  DateTime get startOfToday => startOfDayAfter(0);
}
