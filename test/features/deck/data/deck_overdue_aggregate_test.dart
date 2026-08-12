import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';

import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// `oldestDueAt` → `overdueDayCount`, against real SQLite (BR-161).
///
/// The instant rides the same grouped subquery as `dueCardCount` and the same
/// statement as everything else on the level (AD-13) — these tests hold that
/// to be true at every depth, at both query shapes, and across the sets that
/// must not participate.
void main() {
  final harness = installDeckRepositoryHarness();
  final now = testNow;

  /// The read, at the offset every case here assumes.
  Future<List<DeckSummary>> level({String? under}) async =>
      (await harness.deckRepository
              .watchDeckList(
                parentDeckId: under,
                now: now,
                utcOffset: Duration.zero,
              )
              .first)
          .decks;

  group('the root aggregate', () {
    test('measures from the oldest due card anywhere in the subtree', () async {
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'shallow', deckId: tree.branch.id);
      await insertReviewState(
        harness.db,
        cardId: 'shallow',
        dueAt: now.subtract(const Duration(days: 2)),
      );
      // The older card sits deeper — the aggregate must not stop at level 2.
      await insertCard(harness.db, id: 'deep', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'deep',
        dueAt: now.subtract(const Duration(days: 7)),
      );

      final summary = (await level()).single;

      expect(summary.overdueDayCount, 7);
      expect(summary.scheduleStatus, DeckScheduleStatus.overdue);
    });

    test('due earlier today is dueToday, not overdue', () async {
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'c1', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'c1',
        dueAt: now.subtract(const Duration(hours: 2)),
      );

      final summary = (await level()).single;

      expect(summary.overdueDayCount, 0);
      expect(summary.scheduleStatus, DeckScheduleStatus.dueToday);
    });

    test('new cards and future cards take no part', () async {
      final tree = await harness.seedTree();
      // Never learned: no schedule at all (BR-149).
      await insertCard(harness.db, id: 'fresh', deckId: tree.leaf.id);
      await insertReviewState(harness.db, cardId: 'fresh');
      // Learned, due tomorrow: the other side of the boundary.
      await insertCard(harness.db, id: 'later', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'later',
        dueAt: now.add(const Duration(days: 1)),
      );

      final summary = (await level()).single;

      expect(summary.dueCardCount, 0);
      expect(summary.overdueDayCount, 0);
      expect(summary.scheduleStatus, DeckScheduleStatus.notDue);
    });
  });

  group('the due partition (BR-162)', () {
    /// The level at [at], defaulting to the harness clock.
    Future<DeckListSnapshot> snapshotAt({DateTime? at, String? under}) =>
        harness.deckRepository
            .watchDeckList(
              parentDeckId: under,
              now: at ?? now,
              utcOffset: Duration.zero,
            )
            .first;

    test('due earlier today is dueToday, and only dueToday', () async {
      final tree = await harness.seedTree();
      for (var i = 0; i < 5; i++) {
        await insertCard(harness.db, id: 'today-$i', deckId: tree.leaf.id);
        await insertReviewState(
          harness.db,
          cardId: 'today-$i',
          dueAt: now.subtract(Duration(hours: i + 1)),
        );
      }

      final summary = (await snapshotAt()).decks.single;

      expect(summary.dueCardCount, 5);
      expect(summary.dueTodayCardCount, 5);
      expect(summary.overdueCardCount, 0);
      expect(summary.overdueDayCount, 0);
    });

    test(
      'due before today is overdue, and the oldest sets the badge',
      () async {
        final tree = await harness.seedTree();
        for (var i = 0; i < 7; i++) {
          await insertCard(harness.db, id: 'late-$i', deckId: tree.leaf.id);
          await insertReviewState(
            harness.db,
            cardId: 'late-$i',
            dueAt: now.subtract(Duration(days: i + 1)),
          );
        }

        final summary = (await snapshotAt()).decks.single;

        expect(summary.dueCardCount, 7);
        expect(summary.overdueCardCount, 7);
        expect(summary.dueTodayCardCount, 0);
        // The badge is the AGE of the oldest card, not the count.
        expect(summary.overdueDayCount, 7);
      },
    );

    test('mixed: the two halves sum to the total, New independent', () async {
      final tree = await harness.seedTree();
      for (var i = 0; i < 12; i++) {
        await insertCard(harness.db, id: 'late-$i', deckId: tree.leaf.id);
        await insertReviewState(
          harness.db,
          cardId: 'late-$i',
          dueAt: now.subtract(Duration(days: 1, hours: i)),
        );
      }
      for (var i = 0; i < 3; i++) {
        await insertCard(harness.db, id: 'today-$i', deckId: tree.leaf.id);
        await insertReviewState(
          harness.db,
          cardId: 'today-$i',
          dueAt: now.subtract(Duration(hours: i + 1)),
        );
      }
      // Never learned: the other set entirely (BR-142).
      await insertCard(harness.db, id: 'fresh', deckId: tree.leaf.id);
      await insertReviewState(harness.db, cardId: 'fresh');

      final summary = (await snapshotAt()).decks.single;

      expect(summary.dueCardCount, 15);
      expect(summary.overdueCardCount, 12);
      expect(summary.dueTodayCardCount, 3);
      expect(summary.newCardCount, 1);
      expect(
        summary.dueCardCount,
        summary.overdueCardCount + summary.dueTodayCardCount,
        reason: 'the partition must sum to the Reviewing total (BR-142)',
      );
    });

    test('a future card belongs to neither half', () async {
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'later', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'later',
        dueAt: now.add(const Duration(hours: 2)),
      );

      final summary = (await snapshotAt()).decks.single;

      expect(summary.dueCardCount, 0);
      expect(summary.overdueCardCount, 0);
      expect(summary.dueTodayCardCount, 0);
    });

    test('local midnight moves dueToday into overdue with no write', () async {
      // The same rows, read at two instants. Nothing in the database changes
      // between the reads — only the local-day boundary the repository
      // derives from `now` — and the card slides from one half to the other.
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'c1', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'c1',
        dueAt: now.subtract(const Duration(hours: 2)),
      );

      final before = (await snapshotAt()).decks.single;
      expect(before.dueTodayCardCount, 1);
      expect(before.overdueCardCount, 0);

      final after = (await snapshotAt(
        at: now.add(const Duration(days: 1)),
      )).decks.single;
      expect(after.dueTodayCardCount, 0);
      expect(after.overdueCardCount, 1);
      expect(after.dueCardCount, 1, reason: 'still the same Reviewing card');
    });

    test('a level sums the partition from its own subtrees', () async {
      // A holds branch and leaf; the hero folds the level's summaries, so
      // the level halves must equal the sums of the children's halves — and
      // nothing from an unrelated tree may leak in.
      final tree = await harness.seedTree();
      final other = await harness.seedTree(prefix: 'X-');
      await insertCard(harness.db, id: 'x1', deckId: other.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'x1',
        dueAt: now.subtract(const Duration(days: 30)),
      );
      await insertCard(harness.db, id: 'late', deckId: tree.branch.id);
      await insertReviewState(
        harness.db,
        cardId: 'late',
        dueAt: now.subtract(const Duration(days: 4)),
      );
      await insertCard(harness.db, id: 'today', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'today',
        dueAt: now.subtract(const Duration(hours: 1)),
      );

      final level = await snapshotAt(under: tree.root.id);

      expect(level.levelOverdueCardCount, 1);
      expect(level.levelDueTodayCardCount, 1);
      expect(
        level.levelDueCardCount,
        level.levelOverdueCardCount + level.levelDueTodayCardCount,
      );
      expect(level.levelOverdueDayCount, 4, reason: 'not tree X\'s 30');
    });
  });

  group('the child-level aggregate', () {
    test('agrees with the root about the same subtree', () async {
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'old', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'old',
        dueAt: now.subtract(const Duration(days: 3)),
      );

      final root = (await level()).single;
      final children = await level(under: tree.root.id);
      final branch = children.singleWhere(
        (DeckSummary summary) => summary.deck.id == tree.branch.id,
      );

      // Root/child parity: the flat GROUP BY and the recursive walk must name
      // the same oldest card.
      expect(root.overdueDayCount, 3);
      expect(branch.overdueDayCount, 3);
    });

    test('the level fold repeats the same aggregate the tiles carry', () async {
      // BR-161 on the summary panel: descending into the tree must not lose
      // the overdue state. The panel folds the level's summaries, so parent
      // row, child row and the fold above the child all say the same days.
      final tree = await harness.seedTree();
      await insertCard(harness.db, id: 'old', deckId: tree.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'old',
        dueAt: now.subtract(const Duration(days: 7)),
      );

      final rootLevel = await harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now, utcOffset: Duration.zero)
          .first;
      final insideRoot = await harness.deckRepository
          .watchDeckList(
            parentDeckId: tree.root.id,
            now: now,
            utcOffset: Duration.zero,
          )
          .first;

      expect(rootLevel.levelOverdueDayCount, 7);
      expect(insideRoot.decks.single.overdueDayCount, 7);
      expect(insideRoot.levelDueCardCount, 1);
      expect(insideRoot.levelOverdueDayCount, 7);
    });
  });
}
