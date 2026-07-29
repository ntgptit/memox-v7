import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'support/test_database.dart';

/// Deleting a root deck, with real rows in the database.
///
/// Asserting that the schema *declares* `ON DELETE CASCADE` proves nothing: the
/// pragma that makes those declarations do anything is off by default in SQLite,
/// per connection. So this inserts a three-level tree with cards, states,
/// history and a session, deletes the root, and counts what is left.
void main() {
  Future<int> countOf(AppDatabase db, String table) async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS n FROM $table')
        .getSingle();

    return row.data['n']! as int;
  }

  Future<void> seedThreeLevelTree(AppDatabase db) async {
    // root → branch → leaf. Three levels on purpose: a one-level fixture would
    // pass even if the cascade only reached direct children (BR-55).
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

  test('deleting the root empties the whole tree', () async {
    final db = openTestDatabase();
    await seedThreeLevelTree(db);

    expect(await countOf(db, 'decks'), 3);
    expect(await countOf(db, 'cards'), 1);
    expect(await countOf(db, 'card_review_states'), 1);
    expect(await countOf(db, 'review_history'), 1);
    expect(await countOf(db, 'study_sessions'), 1);

    await db.customStatement("DELETE FROM decks WHERE id = 'root'");

    // BR-03. Every one of these is reached by a different chain: decks by
    // parent_deck_id, cards by deck_id, states by card_id, history by card_id,
    // sessions by deck_id. A single count would hide a chain that did not fire.
    expect(await countOf(db, 'decks'), 0);
    expect(await countOf(db, 'cards'), 0);
    expect(await countOf(db, 'card_review_states'), 0);
    expect(await countOf(db, 'review_history'), 0);
    expect(await countOf(db, 'study_sessions'), 0);
  });

  test('deleting one card leaves the rest of the tree standing', () async {
    // The other direction. A cascade that took too much would pass the test
    // above perfectly.
    final db = openTestDatabase();
    await seedThreeLevelTree(db);
    await insertCard(db, id: 'card-2', deckId: 'leaf');
    await insertReviewState(db, cardId: 'card-2');

    await db.customStatement("DELETE FROM cards WHERE id = 'card-1'");

    expect(await countOf(db, 'cards'), 1);
    expect(await countOf(db, 'card_review_states'), 1);
    expect(await countOf(db, 'review_history'), 0);
    expect(await countOf(db, 'decks'), 3);
    expect(await countOf(db, 'study_sessions'), 1);
  });

  test('a card cannot reference a deck that does not exist', () async {
    // Proves the pragma is enforcing, not merely reported as on.
    final db = openTestDatabase();

    await expectLater(
      insertCard(db, id: 'orphan', deckId: 'no-such-deck'),
      throwsA(anything),
    );
  });
}
