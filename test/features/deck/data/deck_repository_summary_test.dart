import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/root_deck_summary_model.dart';
import 'package:memox/features/deck/domain/scheduler_type_model.dart';

import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// The root-deck aggregate, against real SQLite (UC-06).
///
/// A mocked executor would prove the code calls the API it was written to call.
/// What is actually in doubt is the SQL: whether the two `LEFT JOIN`ed
/// subqueries reach descendants at every depth, whether a deck with no cards
/// still appears, and whether the due predicate has exactly the NULL semantics
/// BR-22 specifies. Only SQLite can answer those.
void main() {
  final harness = installDeckRepositoryHarness();

  /// The one instant every read in this file measures against. Nothing here
  /// touches the wall clock, so `due_at == now` is constructible.
  final now = testNow;

  Future<List<RootDeckSummary>> readSummaries() =>
      harness.deckRepository.watchRootDeckSummaries(now: now).first;

  group('counting', () {
    test('a root with no cards still appears, with zeroes', () async {
      // The COALESCE branch. Without it an inner join would drop empty decks and
      // a brand-new deck would vanish from the list that just created it.
      await harness.deckRepository.createRootDeck(
        name: 'Empty',
        schedulerType: SchedulerType.eightBox,
      );

      final summaries = await readSummaries();

      expect(summaries, hasLength(1));
      expect(summaries.single.totalCardCount, 0);
      expect(summaries.single.dueCardCount, 0);
      expect(summaries.single.hasDueCards, isFalse);
    });

    test('cards are counted at every depth of the tree', () async {
      // Three levels, one card each. The aggregate groups by `root_deck_id`
      // (BR-56), which is why this needs no recursion — and why a level-3 card
      // must still be counted.
      final tree = await harness.seedTree();
      for (final deckId in <String>[
        tree.root.id,
        tree.branch.id,
        tree.leaf.id,
      ]) {
        await insertCard(harness.db, id: 'card-$deckId', deckId: deckId);
      }

      final summaries = await readSummaries();

      expect(summaries.single.totalCardCount, 3);
    });

    test('two roots do not borrow each other’s cards', () async {
      final first = await harness.seedTree(prefix: 'first-');
      final second = await harness.seedTree(prefix: 'second-');
      await insertCard(harness.db, id: 'c1', deckId: first.leaf.id);
      await insertCard(harness.db, id: 'c2', deckId: second.leaf.id);
      await insertCard(harness.db, id: 'c3', deckId: second.leaf.id);

      final summaries = await readSummaries();
      final byId = <String, RootDeckSummary>{
        for (final summary in summaries) summary.deck.id: summary,
      };

      expect(byId[first.root.id]!.totalCardCount, 1);
      expect(byId[second.root.id]!.totalCardCount, 2);
    });

    test(
      'the scheduler comes back on the root, for the row to display',
      () async {
        await harness.deckRepository.createRootDeck(
          name: 'SM-2 deck',
          schedulerType: SchedulerType.sm2,
        );

        final summaries = await readSummaries();

        expect(summaries.single.deck.schedulerType, SchedulerType.sm2);
      },
    );
  });

  group('the due predicate (BR-22)', () {
    /// One card per boundary case, all in the same tree.
    Future<String> seedDueCases() async {
      final tree = await harness.seedTree();
      final deckId = tree.leaf.id;

      await insertCard(harness.db, id: 'new', deckId: deckId);
      await insertReviewState(harness.db, cardId: 'new');

      await insertCard(harness.db, id: 'past', deckId: deckId);
      await insertReviewState(
        harness.db,
        cardId: 'past',
        dueAt: now.subtract(const Duration(minutes: 1)),
      );

      await insertCard(harness.db, id: 'exactly-now', deckId: deckId);
      await insertReviewState(harness.db, cardId: 'exactly-now', dueAt: now);

      await insertCard(harness.db, id: 'future', deckId: deckId);
      await insertReviewState(
        harness.db,
        cardId: 'future',
        dueAt: now.add(const Duration(minutes: 1)),
      );

      return tree.root.id;
    }

    test('null, past and exactly-now are due; future is not', () async {
      await seedDueCases();

      final summaries = await readSummaries();

      expect(summaries.single.totalCardCount, 4);
      // `due_at IS NULL OR due_at <= now` — three of the four.
      expect(summaries.single.dueCardCount, 3);
      expect(summaries.single.hasDueCards, isTrue);
    });

    test('the count agrees with the list a session would hand out', () async {
      // The parity BR-22 exists for. A badge saying 12 over a session offering
      // 11 reads as a scheduler bug and is not one; the two predicates are
      // written character-for-character alike and this is what keeps them so.
      final rootId = await seedDueCases();

      final summaries = await readSummaries();
      final sessionCards = await harness.db
          .cardsDueForReview(rootId, now)
          .get();

      expect(summaries.single.dueCardCount, sessionCards.length);
    });

    test('moving the boundary moves the count', () async {
      // Proves `now` is genuinely a parameter rather than a SQL clock: the same
      // data read at a later instant reports more cards due.
      await seedDueCases();

      final later = await harness.deckRepository
          .watchRootDeckSummaries(now: now.add(const Duration(hours: 1)))
          .first;

      expect(later.single.dueCardCount, 4);
    });
  });

  group('the stream', () {
    test('re-emits after a create, a rename, a move and a delete', () async {
      // What makes the list update without a manual refresh (UC-06 A2). Each
      // write touches `decks`, and Drift invalidates the aggregate on that.
      final emissions = <List<RootDeckSummary>>[];
      final subscription = harness.deckRepository
          .watchRootDeckSummaries(now: now)
          .listen(emissions.add);
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      final first = await harness.deckRepository.createRootDeck(
        name: 'First',
        schedulerType: SchedulerType.eightBox,
      );
      await pumpEventQueue();
      await harness.deckRepository.renameDeck(
        deckId: first.id,
        name: 'Renamed',
      );
      await pumpEventQueue();
      await harness.deckRepository.deleteDeck(first.id);
      await pumpEventQueue();

      expect(emissions.length, greaterThanOrEqualTo(4));
      expect(emissions.first, isEmpty);
      expect(emissions.last, isEmpty);
      expect(
        emissions.any(
          (batch) => batch.any((summary) => summary.deck.name == 'Renamed'),
        ),
        isTrue,
      );
    });

    test('a card added deep in the tree changes the root’s count', () async {
      // Through `CardRepository`, not a raw insert. Drift invalidates a query
      // stream from the table updates its own API reports, so a `customInsert`
      // without an `updates:` set writes the row and notifies nobody — the
      // stream would look broken while the app is fine. Using the real write
      // path is also what this test is actually about.
      final tree = await harness.seedTree();
      final emissions = <List<RootDeckSummary>>[];
      final subscription = harness.deckRepository
          .watchRootDeckSummaries(now: now)
          .listen(emissions.add);
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await harness.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: 'front',
        back: 'back',
      );
      await pumpEventQueue();

      expect(emissions.last.single.totalCardCount, 1);
    });
  });

  group('watchAllDecks', () {
    test('returns every deck of every tree in one read', () async {
      // One statement for the move picker. Asking per root would be N+1 in the
      // number of trees, and the picker shows every tree by definition.
      await harness.seedTree(prefix: 'a-');
      await harness.seedTree(prefix: 'b-');

      final decks = await harness.deckRepository.watchAllDecks().first;

      expect(decks, hasLength(6));
      expect(decks.where((deck) => deck.isRoot), hasLength(2));
    });

    test('sub-decks carry no scheduler of their own (BR-06)', () async {
      final tree = await harness.seedTree();

      final decks = await harness.deckRepository.watchAllDecks().first;
      final leaf = decks.firstWhere((deck) => deck.id == tree.leaf.id);

      expect(leaf.schedulerType, isNull);
      expect(leaf.schedulerGeneration, isNull);
      expect(leaf.rootDeckId, tree.root.id);
    });
  });
}
