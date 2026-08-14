import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/reminder/reminder_worker_entry.dart';

/// BR-185's "at most one summary per local day", at the one point it can break.
///
/// WorkManager is inexact by construction (AD-21), so the interesting cases are
/// all the ones where the wake-up did not happen when it was asked to. A run
/// that slipped past local midnight has already served the day it landed in;
/// measuring the next run from that instant would queue another one the same
/// day, and the user is alerted twice.
void main() {
  // +07:00, so the local and UTC calendar days differ for a large part of the
  // clock — an implementation that quietly used UTC midnight is wrong here in
  // a way it would not be at +00:00.
  const offset = Duration(hours: 7);

  group('after a delivery', () {
    test('anchors on the start of the next local day', () {
      // 20:00 local on 2026-07-29.
      final now = DateTime.utc(2026, 7, 29, 13);

      expect(
        reminderRescheduleAnchor(now: now, utcOffset: offset, didDeliver: true),
        // Midnight local on 2026-07-30.
        DateTime.utc(2026, 7, 29, 17),
      );
    });

    test('a run deferred past midnight cannot queue inside the day it served', () {
      // The scenario the rule exists for: a 20:00 reminder that Doze delayed
      // to 01:00 the next morning. The anchor must be tomorrow's midnight, not
      // this morning's — otherwise 20:00 *today* is still ahead of `now` and
      // gets queued.
      final now = DateTime.utc(2026, 7, 29, 18);

      final anchor = reminderRescheduleAnchor(
        now: now,
        utcOffset: offset,
        didDeliver: true,
      );

      expect(anchor, DateTime.utc(2026, 7, 30, 17));
      expect(anchor.isAfter(now), isTrue);
    });

    test('a delivery in the last minute of a local day still moves on', () {
      // 23:59 local on 2026-07-29.
      final now = DateTime.utc(2026, 7, 29, 16, 59);

      expect(
        reminderRescheduleAnchor(now: now, utcOffset: offset, didDeliver: true),
        DateTime.utc(2026, 7, 29, 17),
      );
    });
  });

  group('after a skip', () {
    test('anchors on now, because nothing was shown', () {
      final now = DateTime.utc(2026, 7, 29, 13);

      expect(
        reminderRescheduleAnchor(now: now, utcOffset: offset, didDeliver: false),
        now,
      );
    });
  });

  test('a negative offset resolves on the local calendar, not the UTC one', () {
    // 20:00 local on 2026-07-29 at -05:00 is already 2026-07-30 in UTC.
    const west = Duration(hours: -5);
    final now = DateTime.utc(2026, 7, 30, 1);

    expect(
      reminderRescheduleAnchor(now: now, utcOffset: west, didDeliver: true),
      // Midnight local on 2026-07-30, which is 05:00 UTC.
      DateTime.utc(2026, 7, 30, 5),
    );
  });
}
