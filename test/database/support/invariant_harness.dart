import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../invariant_queries.dart';
import 'test_database.dart';

/// The fixture and the both-ways check every invariant case is written against.
///
/// **Shared because two files assert with it, not because it is generic.** The
/// suite outgrew one file when Trash added five invariants; the seam it split
/// on is deck-and-study cases against Trash cases, and what neither owns is the
/// valid tree and the pair of assertions each case makes.

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
  await insertSession(db, id: 'session-1', deckId: 'root', rootDeckId: 'root');
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
