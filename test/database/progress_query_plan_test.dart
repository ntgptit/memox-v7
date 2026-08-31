import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_database.dart';

/// What SQLite actually does with Progress's window over `study_answers`.
///
/// **This exists because the debt row about it was wrong, and only a plan could
/// show that.** M99.28 recorded: *"index duy nhất chạm cột này là
/// `(card_id, answered_at)`, mà cột dẫn đầu không nằm trong predicate — nên mỗi
/// lần emit là một full scan `study_answers`"*, and proposed adding
/// `study_answers(answered_at)`.
///
/// The premise is a reasonable reading of the `WHERE` clause and it is not what
/// the query does. The window is not a standalone range scan: it is a join, and
/// `cards` drives it. SQLite finds the live cards through
/// `idx_cards_delete_batch` and then enters `study_answers` with `card_id`
/// already bound — which is exactly the leading column the row believed was
/// missing, supplied by the join rather than by the predicate. The existing
/// composite index then serves the whole row as a **covering** index.
///
/// Measured at M100.12: adding `study_answers(answered_at)` changes the plan by
/// nothing at all. An index nobody reads is not free — every answer written
/// pays to maintain it — so it is not added, and this test is what keeps the
/// decision from being re-litigated from the `WHERE` clause again.
void main() {
  /// The shape of the Progress window, reduced to the part that touches
  /// `study_answers`. The shipped queries (`rootDeckActivity`,
  /// `childDeckActivity`, `progressActivityDays`) wrap this in CTEs and
  /// aggregates; the access path into the table is this join and this filter.
  const String window = '''
SELECT c.deck_id, ans.card_id, ans.answered_at
FROM study_answers ans
INNER JOIN cards c ON c.id = ans.card_id AND c.delete_batch_id IS NULL
WHERE ans.answered_at >= 0 AND ans.answered_at < 999999999
''';

  Future<List<String>> planOf(AppDatabase db) async {
    final rows = await db.customSelect('EXPLAIN QUERY PLAN $window').get();
    return <String>[
      for (final QueryRow row in rows) (row.data['detail'] as String?) ?? '',
    ];
  }

  test('the window enters study_answers through the composite index', () async {
    final db = openTestDatabase();
    addTearDown(db.close);

    final plan = await planOf(db);
    debugPrint(plan.join('\n'));

    expect(
      plan.any((String line) => line.contains('SCAN ans')),
      isFalse,
      reason:
          'Progress is scanning study_answers. The join is supposed to bind '
          'card_id first; if it stopped doing that the cost of this window '
          'changed shape and the index question is open again.\n'
          '${plan.join('\n')}',
    );

    expect(
      plan.any(
        (String line) =>
            line.contains('idx_study_answers_card') &&
            line.contains('card_id=?'),
      ),
      isTrue,
      reason:
          'the composite index is no longer the access path into '
          'study_answers\n${plan.join('\n')}',
    );
  });

  test(
    'an answered_at index would change nothing, so there is not one',
    () async {
      final db = openTestDatabase();
      addTearDown(db.close);

      final before = await planOf(db);

      // Created only inside this test's database and never in the schema — the
      // point is to show the plan is indifferent to it.
      await db.customStatement(
        'CREATE INDEX idx_probe_answered_at ON study_answers (answered_at)',
      );
      final after = await planOf(db);

      expect(
        after,
        before,
        reason:
            'Adding study_answers(answered_at) now changes the plan, so the '
            'measurement this decision rests on has expired. Re-measure before '
            'either adding the index or leaving it out.',
      );

      // The other half of the claim: the schema really does not carry one, so a
      // future reader cannot conclude from a passing test that it was added.
      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name = 'study_answers'",
          )
          .get();
      final names = indexes
          .map((QueryRow row) => row.data['name']! as String)
          .where((String name) => !name.startsWith('idx_probe_'))
          .toList();

      expect(
        names,
        containsAll(<String>[
          'idx_study_answers_card',
          'idx_study_answers_session',
        ]),
      );
      expect(
        names.any((String name) => name.contains('answered_at')),
        isFalse,
        reason:
            'an answered_at index was added to the schema — if that was a '
            'decision, this test carries the measurement that argued against it '
            'and should be updated with the new one',
      );
    },
  );
}
