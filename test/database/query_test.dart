import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'support/test_database.dart';

/// The two due queries, and the thing that matters most about them: they agree.
///
/// BR-22 defines due as `due_at IS NULL OR due_at <= now`. The count shown before
/// a session and the list the session hands out are two spellings of that
/// predicate, and the first time one is edited without the other the symptom is a
/// badge reading 12 beside a session offering 11 — which reads as a scheduler bug
/// and is not one.
void main() {
  /// root-a: three levels deep, with one card in each due state.
  /// root-b: a separate tree, to prove the queries do not bleed across roots.
  Future<void> seed(AppDatabase db) async {
    await insertRootDeck(db, id: 'root-a');
    await insertSubDeck(
      db,
      id: 'branch-a',
      parentId: 'root-a',
      rootDeckId: 'root-a',
      contentType: 'deck',
    );
    await insertSubDeck(
      db,
      id: 'leaf-a',
      parentId: 'branch-a',
      rootDeckId: 'root-a',
      contentType: 'card',
    );

    // Never reviewed: due_at NULL means due now (BR-22). The predicate has to
    // test for NULL, not only for a timestamp.
    await insertCard(db, id: 'a-null', deckId: 'leaf-a');
    await insertReviewState(db, cardId: 'a-null');

    // Exactly at `now`. The boundary the `<=` decides, and the reason `:now` is
    // a parameter: a query reading the SQL clock cannot be tested here at all.
    await insertCard(db, id: 'a-exact', deckId: 'leaf-a');
    await insertReviewState(db, cardId: 'a-exact', dueAt: testNow);

    await insertCard(db, id: 'a-overdue', deckId: 'leaf-a');
    await insertReviewState(
      db,
      cardId: 'a-overdue',
      dueAt: testNow.subtract(const Duration(days: 3)),
    );

    await insertCard(db, id: 'a-future', deckId: 'leaf-a');
    await insertReviewState(
      db,
      cardId: 'a-future',
      dueAt: testNow.add(const Duration(days: 1)),
    );

    await insertRootDeck(db, id: 'root-b');
    await insertSubDeck(
      db,
      id: 'leaf-b',
      parentId: 'root-b',
      rootDeckId: 'root-b',
      contentType: 'card',
    );
    await insertCard(db, id: 'b-overdue', deckId: 'leaf-b');
    await insertReviewState(
      db,
      cardId: 'b-overdue',
      dueAt: testNow.subtract(const Duration(hours: 1)),
    );
  }

  test('cardsDueForStudy returns exactly the due cards of one tree', () async {
    final db = openTestDatabase();
    await seed(db);

    final due = await db.cardsDueForStudy('root-a', testNow).get();

    expect(due.map((row) => row.c.id).toSet(), <String>{
      'a-null',
      'a-exact',
      'a-overdue',
    });
    // Reaches a card three levels down through root_deck_id, and never crosses
    // into the other tree.
    expect(due.map((row) => row.c.id), isNot(contains('b-overdue')));
    expect(due.map((row) => row.c.id), isNot(contains('a-future')));
  });

  test('dueCountPerRootDeck counts each tree separately', () async {
    final db = openTestDatabase();
    await seed(db);

    final counts = <String, int>{
      for (final row in await db.dueCountPerRootDeck(testNow).get())
        row.rootDeckId: row.dueCount,
    };

    expect(counts, <String, int>{'root-a': 3, 'root-b': 1});
  });

  test('the count and the list agree, for every root', () async {
    // The acceptance criterion of M4.3, asserted rather than assumed.
    final db = openTestDatabase();
    await seed(db);

    final counts = await db.dueCountPerRootDeck(testNow).get();

    for (final row in counts) {
      final listed = await db.cardsDueForStudy(row.rootDeckId, testNow).get();

      expect(
        listed.length,
        row.dueCount,
        reason:
            '${row.rootDeckId}: badge says ${row.dueCount}, session '
            'offers ${listed.length}',
      );
    }
  });

  test('now actually drives the result', () async {
    // Were the queries to read the clock instead of the parameter, both of
    // these would return the same thing and the test above would still pass.
    final db = openTestDatabase();
    await seed(db);

    final earlier = await db
        .cardsDueForStudy('root-a', testNow.subtract(const Duration(days: 2)))
        .get();
    final later = await db
        .cardsDueForStudy('root-a', testNow.add(const Duration(days: 2)))
        .get();

    expect(earlier.map((row) => row.c.id).toSet(), <String>{
      'a-null',
      'a-overdue',
    });
    expect(later.map((row) => row.c.id).toSet(), <String>{
      'a-null',
      'a-exact',
      'a-overdue',
      'a-future',
    });
  });

  test('a card with no study state is not offered', () async {
    // BR-09 says a card is born with a state, so a card without one is broken
    // data rather than a due card. The inner join is what decides that, and it
    // is worth pinning: an outer join here would quietly hand the session a card
    // it cannot schedule.
    final db = openTestDatabase();
    await seed(db);
    await insertCard(db, id: 'a-stateless', deckId: 'leaf-a');

    final due = await db.cardsDueForStudy('root-a', testNow).get();

    expect(due.map((row) => row.c.id), isNot(contains('a-stateless')));
  });

  test('the schema version is 3', () async {
    final db = openTestDatabase();

    expect(db.schemaVersion, 3);
  });

  test('the only scheduler numbers in SQL are BR-88s two thresholds', () {
    // **This test used to assert `schemaVersion == 1` under this name.** It
    // passed, and it measured nothing about the SQL — the name promised BR-16
    // and the body checked a version number. Renaming it would have hidden that;
    // implementing it is what the name was worth.
    //
    // BR-16 keeps the eight-box day ladder and the SM-2 factors in the
    // scheduler, so a number here would make changing the algorithm a
    // migration. Two exceptions are deliberate and written down: BR-88 says
    // "mastered" is enforced by the database, and `rootDeckSummaries` counts it,
    // so `current_box = 8` and `interval_days >= 128` are allowed to appear.
    // Nothing else is.
    // **Comments are stripped first, and that is not a detail.** The first
    // version of this scanned the raw file and failed on a comment that
    // *explains* the seed value — it matched the prose describing the rule,
    // not any SQL. This project has shipped that mistake twice: `R8` once
    // matched `platformBrightness` left in the comment describing it, and
    // the duration guard flagged its own documentation.
    final sql = <String>[
      for (final name in <String>['deck.drift', 'card.drift', 'study.drift'])
        File('lib/core/database/queries/$name').readAsStringSync().replaceAll(
          RegExp(r'^\s*--.*$', multiLine: true),
          '',
        ),
    ].join('\n');

    final boxes = RegExp(
      r'current_box\s*[=<>]+\s*(\d+)',
    ).allMatches(sql).map((m) => m.group(1)!).toSet();
    final intervals = RegExp(
      r'interval_days\s*[=<>]+\s*(\d+)',
    ).allMatches(sql).map((m) => m.group(1)!).toSet();
    final easeFactors = RegExp(
      r'ease_factor\s*[=<>]+\s*([\d.]+)',
    ).allMatches(sql).map((m) => m.group(1)!).toSet();

    expect(boxes, <String>{
      '8',
    }, reason: 'a box number other than BR-88s mastered box is in the SQL');
    expect(
      intervals,
      <String>{'128'},
      reason: 'an interval other than BR-88s mastered threshold is in the SQL',
    );
    expect(
      easeFactors,
      isEmpty,
      reason: 'SM-2 factors belong to the scheduler, not to a query (BR-16)',
    );
  });
}
