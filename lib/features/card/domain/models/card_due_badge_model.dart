/// When a card next comes due, as the row's badge shows it (D5, BR-22).
///
/// A sealed classification, not a formatted string: the domain decides *which*
/// bucket a due date falls in against a given now, and the screen picks the copy
/// — the same split `CardState` uses, and the reason a badge can be tested
/// without a widget or a locale. Pure Dart, no Flutter, no clock: [dueBadgeOf]
/// takes now as an argument because nothing in `lib/features/` reads the wall
/// clock (CLAUDE.md).
sealed class CardDueBadge {
  const CardDueBadge();
}

/// Due now — `due_at` is null (a new card, BR-22) or already in the past.
class CardDueNow extends CardDueBadge {
  const CardDueNow();
}

/// Due in under an hour.
class CardDueInMinutes extends CardDueBadge {
  const CardDueInMinutes(this.minutes);

  final int minutes;
}

/// Due in under a day.
class CardDueInHours extends CardDueBadge {
  const CardDueInHours(this.hours);

  final int hours;
}

/// Due in a day or more.
class CardDueInDays extends CardDueBadge {
  const CardDueInDays(this.days);

  final int days;
}

const int _minutesPerHour = 60;
const int _hoursPerDay = 24;

/// Buckets [dueAt] against [now]. Null or past → [CardDueNow]; otherwise the
/// coarsest unit that is at least one — minutes under an hour, hours under a day,
/// days beyond. Coarse on purpose: the badge is a glanceable "when", not a
/// countdown, so a card due in 90 minutes reads "1h", not "90m".
CardDueBadge dueBadgeOf(DateTime? dueAt, DateTime now) {
  if (dueAt == null || !dueAt.isAfter(now)) return const CardDueNow();

  final remaining = dueAt.difference(now);
  final minutes = remaining.inMinutes;
  if (minutes < _minutesPerHour) {
    // At least one minute: `inMinutes` floored a sub-minute gap to 0, but the
    // card is still in the future, so it rounds up to the smallest unit shown.
    return CardDueInMinutes(minutes < 1 ? 1 : minutes);
  }

  final hours = remaining.inHours;
  if (hours < _hoursPerDay) return CardDueInHours(hours);

  return CardDueInDays(remaining.inDays);
}
