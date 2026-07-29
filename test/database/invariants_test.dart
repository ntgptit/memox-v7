import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'invariant_queries.dart';
import 'support/test_database.dart';

/// The 15 data invariants, run against a real database.
///
/// Each is checked **both ways**. Clean on valid data proves the query does not
/// cry wolf; firing on its own violation proves it is connected to anything at
/// all. A query that can never return a row passes "no violations found"
/// perfectly and enforces nothing — which is the failure this whole file exists
/// to make impossible.
///
/// The violating fixture introduces exactly one defect, so a query that fires is
/// firing on its own subject rather than on collateral damage from the seed.
void main() {
  /// A valid three-level tree: root → branch → leaf, with a card, a state, a
  /// session and one history row.
  ///
  /// Three levels because BR-55 says the tree nests, and a one-level fixture
  /// would let Q6 and Q9 pass with the `COALESCE` root-finding BR-57 forbids.
  Future<void> seedValid(AppDatabase db) async {
    await insertRootDeck(db, id: 'root');
    await insertSubDeck(
      db,
      id: 'branch',
      parentId: 'root',
      rootDeckId: 'root',
      contentType: 'deck',
    );
    await insertSubDeck(
      db,
      id: 'leaf',
      parentId: 'branch',
      rootDeckId: 'root',
      contentType: 'card',
    );
    await insertCard(db, id: 'card-1', deckId: 'leaf');
    await insertReviewState(db, cardId: 'card-1');
    await insertSession(
      db,
      id: 'session-1',
      deckId: 'root',
      rootDeckId: 'root',
    );
    await insertHistory(
      db,
      id: 'history-1',
      cardId: 'card-1',
      sessionId: 'session-1',
    );
  }

  /// Runs one invariant and returns the offending ids.
  Future<List<String>> check(AppDatabase db, String id) =>
      violations(db, invariantQueries[id]!);

  /// Asserts the pair: silent on the valid tree, and firing once [breakIt] has
  /// introduced this invariant's own defect.
  void invariant(
    String id,
    String description, {
    required Future<void> Function(AppDatabase db) breakIt,
    required List<String> expectOffenders,
  }) {
    group('$id — $description', () {
      test('clean on a valid three-level tree', () async {
        final db = openTestDatabase();
        await seedValid(db);

        expect(await check(db, id), isEmpty);
      });

      test('fires on its own violation', () async {
        final db = openTestDatabase();
        await seedValid(db);
        await breakIt(db);

        // Unordered: the invariant queries specify no ORDER BY, and Q8's
        // recursive walk returns rows in whatever order the CTE produced.
        expect(await check(db, id), unorderedEquals(expectOffenders));
      });
    });
  }

  test('all fifteen invariants are present', () {
    // The list itself is a claim. Losing one would leave fourteen green tests
    // and no sign that the fifteenth ever existed.
    expect(invariantQueries.keys, hasLength(15));
    expect(
      invariantQueries.keys,
      containsAll(<String>[for (var i = 1; i <= 15; i++) 'Q$i']),
    );
  });

  invariant(
    'Q1',
    'root deck holds cards directly (BR-58)',
    breakIt: (db) => insertCard(db, id: 'bad-card', deckId: 'root'),
    expectOffenders: <String>['bad-card'],
  );

  invariant(
    'Q2',
    'unset deck already has content (BR-60, BR-62)',
    breakIt: (db) async {
      await insertSubDeck(
        db,
        id: 'unset-deck',
        parentId: 'branch',
        rootDeckId: 'root',
      );
      await insertCard(db, id: 'card-in-unset', deckId: 'unset-deck');
    },
    expectOffenders: <String>['unset-deck'],
  );

  invariant(
    'Q3',
    'card deck has sub-decks (BR-63)',
    breakIt: (db) => insertSubDeck(
      db,
      id: 'under-leaf',
      parentId: 'leaf',
      rootDeckId: 'root',
    ),
    expectOffenders: <String>['leaf'],
  );

  invariant(
    'Q4',
    'deck deck holds cards directly (BR-64)',
    breakIt: (db) => insertCard(db, id: 'card-on-branch', deckId: 'branch'),
    expectOffenders: <String>['branch'],
  );

  invariant(
    'Q5',
    'root does not carry content_type = deck',
    breakIt: (db) => db.customStatement(
      "UPDATE decks SET content_type = 'card' WHERE id = 'root'",
    ),
    expectOffenders: <String>['root'],
  );

  invariant(
    'Q6',
    'descendant points at the wrong root (BR-72)',
    breakIt: (db) async {
      // The level-3 case. With a one-level fixture this defect cannot even be
      // expressed, which is why BR-55 asks for depth here.
      await insertRootDeck(db, id: 'other-root');
      await db.customStatement(
        "UPDATE decks SET root_deck_id = 'other-root' WHERE id = 'leaf'",
      );
    },
    expectOffenders: <String>['leaf'],
  );

  invariant(
    'Q7',
    'root does not point at itself (BR-56)',
    breakIt: (db) => db.customStatement(
      "UPDATE decks SET root_deck_id = 'branch' WHERE id = 'root'",
    ),
    expectOffenders: <String>['root'],
  );

  invariant(
    'Q8',
    'cycle in the deck tree (BR-69)',
    breakIt: (db) async {
      // root → branch → leaf → root. Reachable only because root_deck_id is not
      // a foreign key and parent_deck_id is self-referential.
      await db.customStatement(
        "UPDATE decks SET parent_deck_id = 'leaf' WHERE id = 'root'",
      );
    },
    expectOffenders: <String>['branch', 'leaf', 'root'],
  );

  invariant(
    'Q9',
    'card state disagrees with its root scheduler (BR-48, BR-49)',
    breakIt: (db) => db.customStatement(
      'UPDATE card_review_states SET scheduler_generation = 99 '
      "WHERE card_id = 'card-1'",
    ),
    expectOffenders: <String>['card-1'],
  );

  invariant(
    'Q10',
    'sub-deck carries scheduler columns (BR-06)',
    breakIt: (db) => db.customStatement(
      "UPDATE decks SET scheduler_type = 'sm2' WHERE id = 'branch'",
    ),
    expectOffenders: <String>['branch'],
  );

  invariant(
    'Q11',
    'root is missing its scheduler (BR-11)',
    breakIt: (db) => db.customStatement(
      "UPDATE decks SET scheduler_type = NULL WHERE id = 'root'",
    ),
    expectOffenders: <String>['root'],
  );

  invariant(
    'Q12',
    'invalid status × end_reason (BR-79…BR-85)',
    breakIt: (db) => db.customStatement(
      "UPDATE study_sessions SET status = 'completed', "
      "end_reason = 'user_exit' WHERE id = 'session-1'",
    ),
    expectOffenders: <String>['session-1'],
  );

  invariant(
    'Q13',
    'ended session has no ended_at',
    breakIt: (db) => db.customStatement(
      "UPDATE study_sessions SET status = 'abandoned', "
      "end_reason = 'user_exit', ended_at = NULL WHERE id = 'session-1'",
    ),
    expectOffenders: <String>['session-1'],
  );

  invariant(
    'Q14',
    'a relearning review changed the schedule (BR-78)',
    breakIt: (db) => insertHistory(
      db,
      id: 'history-bad',
      cardId: 'card-1',
      sessionId: 'session-1',
      reviewKind: 'relearning',
      previousBox: 3,
      nextBox: 5,
    ),
    expectOffenders: <String>['history-bad'],
  );

  invariant(
    'Q15',
    'a deck deeper than 10 levels (BR-55)',
    breakIt: (db) async {
      // Extend the valid tree to level 11. `branch` sits at level 2 (leaf
      // holds cards, so the chain goes under branch): d3 is level 3 … d11 is
      // level 11.
      var parent = 'branch';
      for (var level = 3; level <= 11; level++) {
        final id = 'd$level';
        await insertSubDeck(
          db,
          id: id,
          parentId: parent,
          rootDeckId: 'root',
          contentType: level == 11 ? 'unset' : 'deck',
        );
        parent = id;
      }
    },
    // Only the node past the limit — levels 3..10 are legal.
    expectOffenders: <String>['d11'],
  );

  test('one defect trips only the invariants that genuinely cover it', () async {
    // Guards the pairs above from passing for the wrong reason: if every
    // invariant fired on every defect, "fires on its own violation" would be
    // meaningless.
    //
    // Q1 and Q4 overlap here, and correctly so. A card attached to a root
    // violates BR-58 (a root holds only sub-decks) and BR-64 (a `deck` deck
    // holds no direct cards) at the same time, because a root always carries
    // `content_type = 'deck'`. Two rules, one defect — the document says so, and
    // pretending otherwise would mean weakening one of the queries.
    const expectedToFire = <String>{'Q1', 'Q4'};

    final db = openTestDatabase();
    await seedValid(db);
    await insertCard(db, id: 'bad-card', deckId: 'root');

    for (final id in invariantQueries.keys) {
      final rows = await check(db, id);

      expect(
        rows.isNotEmpty,
        expectedToFire.contains(id),
        reason:
            '$id: ${rows.isEmpty ? 'stayed silent' : 'fired'} on a card '
            'attached to a root deck',
      );
    }
  });
}
