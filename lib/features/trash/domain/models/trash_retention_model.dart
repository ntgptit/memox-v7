/// BR-264's retention window, in one place.
///
/// **30 × 24 hours, not "30 calendar days".** A calendar month means asking what
/// a local day is, which drags in `LocalDayModel`, a UTC offset and a
/// daylight-saving boundary — for a rule whose only job is "long enough to
/// notice a mistake". A fixed duration is the same number of days everywhere in
/// the world and is testable at its edge.
///
/// Nothing here reads a clock. `now` arrives from `clockProvider` at the top and
/// travels down as a value, because "now" having two owners is what AD-06
/// exists to stop.
abstract final class TrashRetention {
  /// How long a deleted item stays recoverable (BR-264).
  static const Duration window = Duration(days: 30);

  /// When [deletedAt] stops being recoverable.
  static DateTime expiryOf(DateTime deletedAt) => deletedAt.add(window);

  /// The moment a batch must have been deleted at or before, to be purgeable.
  ///
  /// Used as `deleted_at <= cutoff` so that a batch at **exactly** 30 days is
  /// eligible — the boundary BR-264 names, and the one
  /// `trash_retention_test.dart` pins from both sides.
  static DateTime cutoffFor(DateTime now) => now.subtract(window);

  /// Whether a batch deleted at [deletedAt] may be purged at [now].
  static bool isExpired({required DateTime deletedAt, required DateTime now}) =>
      !deletedAt.isAfter(cutoffFor(now));

  /// Whole days left before expiry, floored at zero.
  ///
  /// **Floored, and rounded up**, so "1 day left" means "there is still some
  /// time" rather than "somewhere between none and one". A count that reaches 0
  /// while the item is still restorable would tell the user it is already gone.
  static int daysLeft({required DateTime deletedAt, required DateTime now}) {
    final remaining = expiryOf(deletedAt).difference(now);
    if (remaining.isNegative) return 0;

    return remaining.inMicroseconds == 0
        ? 0
        : (remaining.inMicroseconds / Duration.microsecondsPerDay).ceil();
  }
}
