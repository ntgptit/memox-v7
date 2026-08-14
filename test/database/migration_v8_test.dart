import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'support/migration_v8_fixture.dart';

/// The v7 → v8 upgrade: the recall direction, and the backfill of what the app
/// was already doing (BR-182).
///
/// **Why data has to move at all.** Every `self_assess` review this app has
/// served showed the front and revealed the back. Leaving those rows NULL would
/// make "asked from the Korean term" and "the feature did not exist yet" the
/// same stored value, and the second reading is the one a report would take —
/// so a learner's whole history would read as directionless rather than as
/// recognition.
///
/// **The other half is what must NOT be stamped.** `eight_box` never runs
/// `self_assess` in a review, a learning chain does not choose its stages, and
/// neither has a direction to record. A backfill that scoped itself loosely
/// would invent one for both, and nothing downstream could tell it apart from a
/// choice the user made.
///
/// Seeded through **raw SQL against the v7 schema**: the point is that rows
/// written by the old code are repaired, and raw SQL is the only way to write a
/// row that owes nothing to the current build.
void main() {
  group('an sm2 self-assess review is backfilled', () {
    Future<AppDatabase> seeded() => upgradedFromV7((raw) {
      seedTree(raw, root: 'sm2root', scheduler: 'sm2');
      seedSession(
        raw,
        root: 'sm2root',
        id: 's-sm2',
        kind: 'reviewing',
        mode: 'self_assess',
        scheduler: 'sm2',
      );
    });

    test('the session carries the direction it actually ran in', () async {
      final db = await seeded();

      expect(
        await directionOf(db, 'study_sessions', "id = 's-sm2'"),
        'korean_to_meaning',
      );
    });

    test('so does its queue row', () async {
      final db = await seeded();

      expect(
        await directionOf(db, 'study_queue_items', "session_id = 's-sm2'"),
        'korean_to_meaning',
      );
    });

    test('and so does the turn it recorded', () async {
      final db = await seeded();

      expect(
        await directionOf(db, 'study_answers', "id = 's-sm2-a1'"),
        'korean_to_meaning',
      );
    });
  });
}
