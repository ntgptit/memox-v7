import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/domain/models/trash_retention_model.dart';

/// BR-190's arithmetic, with no database and no clock.
///
/// The boundary is the whole point of this file: `deleted_at + 30 days` decides
/// whether a user still has their data, and it is the one number in the feature
/// that a test can pin exactly.
void main() {
  final deletedAt = DateTime.utc(2026, 8, 1, 12);

  group('the boundary', () {
    test('one microsecond short is not expired', () {
      final now = deletedAt
          .add(TrashRetention.window)
          .subtract(const Duration(microseconds: 1));

      expect(TrashRetention.isExpired(deletedAt: deletedAt, now: now), isFalse);
    });

    test('exactly thirty days is expired', () {
      // `<=`, so equality falls on the purge side — stated here rather than
      // left to the SQL, because the two must agree and only one of them is
      // readable at a glance.
      final now = deletedAt.add(TrashRetention.window);

      expect(TrashRetention.isExpired(deletedAt: deletedAt, now: now), isTrue);
    });

    test('the cutoff and the expiry are the same boundary from two sides', () {
      final now = deletedAt.add(TrashRetention.window);

      expect(TrashRetention.cutoffFor(now), deletedAt);
      expect(TrashRetention.expiryOf(deletedAt), now);
    });

    test('a clock that has gone backwards is not expired', () {
      // Not hypothetical: a device whose time is corrected backwards would
      // otherwise make `now - deleted_at` negative, and a comparison written
      // the other way round would read that as "long ago".
      final now = deletedAt.subtract(const Duration(days: 1));

      expect(TrashRetention.isExpired(deletedAt: deletedAt, now: now), isFalse);
    });
  });

  group('days left', () {
    test('is thirty at the moment of deletion', () {
      expect(TrashRetention.daysLeft(deletedAt: deletedAt, now: deletedAt), 30);
    });

    test('rounds up, so it never says zero while time remains', () {
      // A count that reached 0 while the item was still restorable would tell
      // the user it had already gone.
      final now = deletedAt
          .add(TrashRetention.window)
          .subtract(const Duration(minutes: 1));

      expect(TrashRetention.daysLeft(deletedAt: deletedAt, now: now), 1);
    });

    test('is zero exactly at expiry and stays there afterwards', () {
      final atExpiry = deletedAt.add(TrashRetention.window);

      expect(TrashRetention.daysLeft(deletedAt: deletedAt, now: atExpiry), 0);
      expect(
        TrashRetention.daysLeft(
          deletedAt: deletedAt,
          now: atExpiry.add(const Duration(days: 5)),
        ),
        0,
      );
    });

    test('counts whole days as they pass', () {
      expect(
        TrashRetention.daysLeft(
          deletedAt: deletedAt,
          now: deletedAt.add(const Duration(days: 10)),
        ),
        20,
      );
    });
  });
}
