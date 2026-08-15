import 'package:flutter_test/flutter_test.dart';

import 'support/progress_read_harness.dart';

/// Which deck a figure belongs to — the tree, walked for real.
///
/// Split from `progress_activity_lifecycle_test.dart` at the source-size
/// ceiling, and the seam is real: this file asks *where does a number belong*,
/// that one asks *what happens to it when the tree changes*. Both need real
/// SQLite: the recursive subtree walk and the `root_deck_id` shortcut are
/// behaviour of the database, not of the code that calls it.
void main() {
  final harness = installProgressReadHarness();

  group('hierarchy is resolved for real (BR-195)', () {
    /// A root with a strictly linear chain below it, ten decks tall counting
    /// the root as level 1 (BR-55), and one card at the deepest level.
    Future<List<String>> seedTenLevels() async {
      final ids = <String>[await harness.root('lvl-1', name: 'Root')];
      await harness.seedSession(deckId: 'lvl-1');
      for (var level = 2; level <= 10; level++) {
        ids.add(
          await harness.subDeck(
            'lvl-$level',
            parentId: ids.last,
            rootId: 'lvl-1',
            contentType: level == 10 ? 'card' : 'deck',
            name: 'Level $level',
          ),
        );
      }
      await harness.card('deep-card', deckId: ids.last);
      await harness.answer('a1', cardId: 'deep-card', at: localMidnight(0));

      return ids;
    }

    test('a card ten levels down counts for its root', () async {
      await seedTenLevels();

      final row = rowFor(await harness.watch().first, 'lvl-1');

      expect(row.last7Days.activeCardCount, 1);
    });

    test('every intermediate level counts it too', () async {
      final ids = await seedTenLevels();

      // Level 2 seen from level 1, level 3 seen from level 2, and so on: each
      // level's row aggregates the whole subtree below it, which is what a walk
      // through `parent_deck_id` has to prove and what `root_deck_id` alone
      // cannot.
      for (var level = 1; level < 10; level++) {
        final snapshot = await harness.watch(deckId: ids[level - 1]).first;
        final row = rowFor(snapshot, ids[level]);

        expect(
          row.last7Days.activeCardCount,
          1,
          reason: 'level ${level + 1} seen from level $level',
        );
      }
    });

    test("a level's own totals cover its whole subtree", () async {
      final ids = await seedTenLevels();

      final snapshot = await harness.watch(deckId: ids[4]).first;

      expect(snapshot.scopeLast7Days.activeCardCount, 1);
      expect(snapshot.scopeDeckId, ids[4]);
    });

    test('the level carries the path back up, root first', () async {
      final ids = await seedTenLevels();

      final snapshot = await harness.watch(deckId: ids[3]).first;

      expect(snapshot.scopePath.map((segment) => segment.id).toList(), <String>[
        ids[0],
        ids[1],
        ids[2],
      ]);
      // Every row on this level sits under the scope, so its path is the
      // scope's path plus the scope itself.
      expect(
        rowFor(snapshot, ids[4]).path.map((segment) => segment.id).toList(),
        <String>[ids[0], ids[1], ids[2], ids[3]],
      );
    });

    test('the deepest legal level still gets its whole path', () async {
      // The ancestry walk carries a bound (`ProgressDao.ancestryWalkLimit`), so
      // the number that stops a cyclic chain must still clear a legal one. Level
      // 10 is the deepest BR-55 allows and has nine ancestors; a bound one too
      // small would drop the root and nothing else would fail.
      final ids = await seedTenLevels();

      final snapshot = await harness.watch(deckId: ids[9]).first;

      expect(
        snapshot.scopePath.map((segment) => segment.id).toList(),
        ids.sublist(0, 9),
      );
    });

    test('a cyclic parent chain returns a short path instead of hanging', () async {
      // Only reachable through corrupt data — invariant Q8 is what catches it —
      // but "the query never returns" is the worst possible failure: it holds
      // the database isolate, so every other read in the app blocks behind it
      // and the screen sits on a spinner with no error and no timeout. The
      // bound turns that into a truncated path, which the mapper already treats
      // as chrome.
      await harness.root('root-a', name: 'Alpha');
      await harness.subDeck('a-1', parentId: 'root-a', rootId: 'root-a');
      await harness.subDeck(
        'a-2',
        parentId: 'a-1',
        rootId: 'root-a',
        contentType: 'card',
      );
      // a-1 -> a-2 -> a-1: `distance` grows every lap, so UNION cannot
      // deduplicate the rows away.
      await harness.reparent('a-1', toParentId: 'a-2');

      final snapshot = await harness
          .watch(deckId: 'a-2')
          .first
          .timeout(const Duration(seconds: 5));

      expect(snapshot.scopeDeckId, 'a-2');
      expect(snapshot.scopePath.length, lessThanOrEqualTo(10));
    });

    test('sibling subtrees never count each other', () async {
      await harness.root('root-a', name: 'Alpha');
      await harness.root('root-b', name: 'Beta');
      await harness.seedSession(deckId: 'root-a');
      await harness.subDeck('a-1', parentId: 'root-a', rootId: 'root-a');
      await harness.subDeck('b-1', parentId: 'root-b', rootId: 'root-b');
      await harness.card('card-a', deckId: 'a-1');
      await harness.card('card-b', deckId: 'b-1');
      await harness.answer('a1', cardId: 'card-a', at: localMidnight(0));
      await harness.answer('a2', cardId: 'card-b', at: localMidnight(-1));

      final snapshot = await harness.watch().first;

      expect(rowFor(snapshot, 'root-a').last7Days.activeCardCount, 1);
      expect(rowFor(snapshot, 'root-b').last7Days.activeCardCount, 1);
      // Cards add up across disjoint subtrees; days do not — the two decks were
      // studied on different days, so the level saw two.
      expect(snapshot.scopeLast7Days.activeCardCount, 2);
      expect(snapshot.scopeLast7Days.activeDayCount, 2);
    });

    test('active days are read, not summed — one day in two decks stays one '
        'day', () async {
      await harness.root('root-a', name: 'Alpha');
      await harness.root('root-b', name: 'Beta');
      await harness.subDeck(
        'cards-a',
        parentId: 'root-a',
        rootId: 'root-a',
        contentType: 'card',
      );
      await harness.subDeck(
        'cards-b',
        parentId: 'root-b',
        rootId: 'root-b',
        contentType: 'card',
      );
      await harness.seedSession(deckId: 'root-a');
      await harness.card('card-a', deckId: 'cards-a');
      await harness.card('card-b', deckId: 'cards-b');
      await harness.answer('a1', cardId: 'card-a', at: localMidnight(0));
      await harness.answer('a2', cardId: 'card-b', at: localMidnight(0));

      final snapshot = await harness.watch().first;

      expect(rowFor(snapshot, 'root-a').last7Days.activeDayCount, 1);
      expect(rowFor(snapshot, 'root-b').last7Days.activeDayCount, 1);
      expect(snapshot.scopeLast7Days.activeDayCount, 1);
    });
  });
}
