import 'package:flutter_test/flutter_test.dart';

import 'invariant_queries.dart';
import 'support/invariant_harness.dart';
import 'support/test_database.dart';

/// The 22 data invariants, run against a real database.
///
/// Each is checked **both ways**. Clean on valid data proves the query does not
/// cry wolf; firing on its own violation proves it is connected to anything at
/// all. A query that can never return a row passes "no violations found"
/// perfectly and enforces nothing — which is the failure this whole file exists
/// to make impossible.
///
/// The violating fixture introduces exactly one defect, so a query that fires is
/// firing on its own subject rather than on collateral damage from the seed.
///
/// The five Trash cases live in `invariants_trash_test.dart`; the fixture and
/// the both-ways helper they share are in `support/invariant_harness.dart`.
void main() {
  test('every invariant this suite claims to run is present', () {
    // The list itself is a claim. Losing one would leave the rest green and no
    // sign that the missing one ever existed.
    //
    // Q29 and Q30 keep the numbers `data-model.md` gave them rather than
    // becoming Q16 and Q17: the host set is a subset of the document's
    // numbering, and renumbering to close the gap would make every citation of
    // an invariant ambiguous about which document version it meant.
    expect(invariantQueries.keys, hasLength(22));
    expect(
      invariantQueries.keys,
      containsAll(<String>[for (var i = 1; i <= 15; i++) 'Q$i']),
    );
    expect(
      invariantQueries.keys,
      containsAll(<String>['Q29', 'Q30', 'Q31', 'Q32', 'Q33', 'Q34', 'Q35']),
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
      'UPDATE card_study_states SET scheduler_generation = 99 '
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
    'Q30',
    'the tree has learned cards but the scheduler is not locked (BR-13)',
    // The seed's card has no schedule, so it never finished the chain and the
    // root is legitimately unlocked. Giving it one without stamping the root is
    // exactly the state `completeLearning` writes both halves of in a single
    // transaction to make unreachable.
    breakIt: (db) => db.customStatement(
      "UPDATE card_study_states SET learned_at = '2026-01-01T00:00:00.000Z', "
      "due_at = '2026-01-02T00:00:00.000Z' WHERE card_id = 'card-1'",
    ),
    expectOffenders: <String>['root'],
  );

  group('Q30 — the other direction is not a violation', () {
    test('a locked root with nothing learned left is valid', () async {
      // Learn the tree, then delete the card. The lock records that this tree
      // *was* learned; deleting content does not un-learn it, and only Reset
      // clears the stamp (BR-44). An invariant firing here would call a
      // perfectly ordinary sequence corrupt.
      final db = openTestDatabase();
      await seedValid(db);
      await db.customStatement(
        "UPDATE decks SET first_answered_at = '2026-01-01T00:00:00.000Z' "
        "WHERE id = 'root'",
      );

      expect(await check(db, 'Q30'), isEmpty);
    });

    test('a learned card under a locked root is valid', () async {
      final db = openTestDatabase();
      await seedValid(db);
      await db.customStatement(
        "UPDATE card_study_states SET learned_at = '2026-01-01T00:00:00.000Z', "
        "due_at = '2026-01-02T00:00:00.000Z' WHERE card_id = 'card-1'",
      );
      await db.customStatement(
        "UPDATE decks SET first_answered_at = '2026-01-01T00:00:00.000Z' "
        "WHERE id = 'root'",
      );

      expect(await check(db, 'Q30'), isEmpty);
    });
  });

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
      kind: 'relearning',
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

  invariant(
    'Q29',
    'a sub-deck kept its type after everything left it (BR-163)',
    breakIt: (db) => insertSubDeck(
      db,
      id: 'emptied',
      parentId: 'root',
      rootDeckId: 'root',
      // The exact state BR-163 makes impossible and the v6 migration
      // normalises away: typed, non-root, and holding nothing.
      contentType: 'card',
    ),
    expectOffenders: <String>['emptied'],
  );

  test('an empty root keeps its type without tripping Q29', () async {
    // The other side of the rule. Root is `deck` forever (BR-58), so an empty
    // one is ordinary — an invariant that fired here would make every
    // freshly-created root a violation.
    final db = openTestDatabase();
    await seedValid(db);
    await insertRootDeck(db, id: 'empty-root');

    expect(await check(db, 'Q29'), isEmpty);
  });

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
