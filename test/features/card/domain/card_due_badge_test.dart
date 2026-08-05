import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_due_badge_model.dart';

/// `dueBadgeOf` buckets a due date against a fixed now — pure, no clock, no
/// locale (D5, BR-22).
void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  test('a null due has no date to show, and is not "now"', () {
    // BR-22 would put this card in a session, but that is a fact about the
    // queue, not about when the card is next due. Answering "now" here put the
    // word beside the row's own `NEW` label and told the learner a card they
    // had never opened had come back around.
    expect(dueBadgeOf(null, now), isA<CardNotScheduled>());
    expect(dueBadgeOf(null, now), isNot(isA<CardDueNow>()));
  });

  test('a past due is due now', () {
    expect(
      dueBadgeOf(now.subtract(const Duration(hours: 1)), now),
      isA<CardDueNow>(),
    );
  });

  test('under an hour reads in minutes', () {
    final badge = dueBadgeOf(now.add(const Duration(minutes: 10)), now);
    expect(badge, isA<CardDueInMinutes>());
    expect((badge as CardDueInMinutes).minutes, 10);
  });

  test('a sub-minute future rounds up to one minute, never zero', () {
    final badge = dueBadgeOf(now.add(const Duration(seconds: 30)), now);
    expect((badge as CardDueInMinutes).minutes, 1);
  });

  test('under a day reads in hours, coarsely', () {
    final badge = dueBadgeOf(now.add(const Duration(minutes: 90)), now);
    expect(badge, isA<CardDueInHours>());
    expect((badge as CardDueInHours).hours, 1, reason: '90 min floors to 1h');
  });

  test('a day or more reads in days', () {
    final badge = dueBadgeOf(now.add(const Duration(days: 4, hours: 3)), now);
    expect(badge, isA<CardDueInDays>());
    expect((badge as CardDueInDays).days, 4);
  });
}
