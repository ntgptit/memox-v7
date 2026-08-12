import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../card/data/support/card_text_fixture.dart';
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

  Future<List<DeckSummary>> readSummaries() async =>
      (await harness.deckRepository
              .watchDeckList(
                parentDeckId: null,
                now: now,
                utcOffset: Duration.zero,
              )
              .first)
          .decks;

  group('counting', () {
    test('a root with no cards still appears, with zeroes', () async {
      // The COALESCE branch. Without it an inner join would drop empty decks and
      // a brand-new deck would vanish from the list that just created it.
      await harness.deckRepository.createRootDeck(
        name: DeckName.parse('Empty').name!,
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
      final byId = <String, DeckSummary>{
        for (final summary in summaries) summary.deck.id: summary,
      };

      expect(byId[first.root.id]!.totalCardCount, 1);
      expect(byId[second.root.id]!.totalCardCount, 2);
    });

    test(
      'the scheduler comes back on the root, for the row to display',
      () async {
        await harness.deckRepository.createRootDeck(
          name: DeckName.parse('SM-2 deck').name!,
          schedulerType: SchedulerType.sm2,
        );

        final summaries = await readSummaries();

        expect(summaries.single.deck.schedulerType, SchedulerType.sm2);
      },
    );
  });

  group('the due predicate (BR-142)', () {
    /// One card per boundary case, all in the same tree.
    Future<String> seedDueCases() async {
      final tree = await harness.seedTree();
      final deckId = tree.leaf.id;

      // Never learned, so no schedule (BR-149). Under BR-22 the badge counted
      // this as due; since BR-142 it is New, and the badge's Due number must
      // not claim a card the New number already has.
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

    test('past and exactly-now are due; future and new are not', () async {
      await seedDueCases();

      final summaries = await readSummaries();

      expect(summaries.single.totalCardCount, 4);
      // `learned_at IS NOT NULL AND due_at <= now` — two of the four.
      expect(summaries.single.dueCardCount, 2);
      expect(summaries.single.hasDueCards, isTrue);
    });

    test('the count agrees with the list a session would hand out', () async {
      // The parity BR-142 exists for. A badge saying 12 over a session offering
      // 11 reads as a scheduler bug and is not one; the two predicates are
      // written character-for-character alike and this is what keeps them so.
      final rootId = await seedDueCases();

      final summaries = await readSummaries();
      final sessionCards = await harness.db.cardsDueForStudy(rootId, now).get();

      expect(summaries.single.dueCardCount, sessionCards.length);
    });

    test('moving the boundary moves the count', () async {
      // Proves `now` is genuinely a parameter rather than a SQL clock: the same
      // data read at a later instant reports more cards due.
      await seedDueCases();

      final later = await harness.deckRepository
          .watchDeckList(
            parentDeckId: null,
            now: now.add(const Duration(hours: 1)),
            utcOffset: Duration.zero,
          )
          .first;

      expect(later.decks.single.dueCardCount, 3);
    });

    test('nextDueAt is the earliest card NOT already due', () async {
      // `> :now`, strictly, and it matters. The fixture has a card due at exactly
      // `now`, which the count above already treats as due; if the boundary
      // included it the delay would be zero, the controller's guard would refuse
      // to arm anything, and the genuinely-next boundary a minute later would
      // never get a wake-up. The screen would go stale again, silently — the same
      // bug the boundary exists to fix, reintroduced by one character.
      await seedDueCases();

      final snapshot = await harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now, utcOffset: Duration.zero)
          .first;

      expect(snapshot.nextDueAt, now.add(const Duration(minutes: 1)));
    });

    test('nextDueAt is null when every card is already due', () async {
      await seedDueCases();

      final snapshot = await harness.deckRepository
          .watchDeckList(
            parentDeckId: null,
            now: now.add(const Duration(hours: 1)),
            utcOffset: Duration.zero,
          )
          .first;

      // Nothing left to wait for. The controller must arm no timer here, and a
      // non-null value would have it wait for a boundary in the past.
      expect(snapshot.nextDueAt, isNull);
      // Three of the four. The never-learned card is not waiting for a
      // boundary — it has no schedule to arrive at (BR-149).
      expect(snapshot.decks.single.dueCardCount, 3);
    });

    test('nextDueAt is null when there are no cards at all', () async {
      await harness.deckRepository.createRootDeck(
        name: DeckName.parse('Empty').name!,
        schedulerType: SchedulerType.eightBox,
      );

      final snapshot = await harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now, utcOffset: Duration.zero)
          .first;

      expect(snapshot.decks, hasLength(1));
      expect(snapshot.nextDueAt, isNull);
    });

    test('nextDueAt is null when there are no decks at all', () async {
      // The no-rows case in the mapper: with nothing to join against there is no
      // row to read the scalar off, and `null` is the truth rather than a value
      // that went missing.
      final snapshot = await harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now, utcOffset: Duration.zero)
          .first;

      expect(snapshot.decks, isEmpty);
      expect(snapshot.nextDueAt, isNull);
    });

    test('nextDueAt is the earliest across every tree, not per root', () async {
      // One timer for the screen, so one boundary for the screen. Per-root
      // boundaries would mean one timer per row, which is the N+1 this design
      // avoids everywhere else.
      final treeA = await harness.seedTree(prefix: 'A-');
      final treeB = await harness.seedTree(prefix: 'B-');
      await insertCard(harness.db, id: 'a-late', deckId: treeA.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'a-late',
        dueAt: now.add(const Duration(hours: 5)),
      );
      await insertCard(harness.db, id: 'b-soon', deckId: treeB.leaf.id);
      await insertReviewState(
        harness.db,
        cardId: 'b-soon',
        dueAt: now.add(const Duration(minutes: 7)),
      );

      final snapshot = await harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now, utcOffset: Duration.zero)
          .first;

      expect(snapshot.nextDueAt, now.add(const Duration(minutes: 7)));
    });

    test('reading again at nextDueAt raises the count', () async {
      // The boundary and the counts describing the same data, which is why they
      // come from one statement. If reading at `nextDueAt` did not move the count,
      // the timer would be waking the screen for nothing.
      await seedDueCases();
      final before = await harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now, utcOffset: Duration.zero)
          .first;

      final after = await harness.deckRepository
          .watchDeckList(
            parentDeckId: null,
            now: before.nextDueAt!,
            utcOffset: Duration.zero,
          )
          .first;

      expect(before.decks.single.dueCardCount, 2);
      expect(after.decks.single.dueCardCount, 3);
    });
  });

  group('the stream', () {
    test('re-emits after a create, a rename, a move and a delete', () async {
      // What makes the list update without a manual refresh (UC-06 A2). Each
      // write touches `decks`, and Drift invalidates the aggregate on that.
      final emissions = <List<DeckSummary>>[];
      final subscription = harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now, utcOffset: Duration.zero)
          .listen((snapshot) => emissions.add(snapshot.decks));
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      final first = await harness.deckRepository.createRootDeck(
        name: DeckName.parse('First').name!,
        schedulerType: SchedulerType.eightBox,
      );
      await pumpEventQueue();
      await harness.deckRepository.renameDeck(
        deckId: first.id,
        name: DeckName.parse('Renamed').name!,
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
      final emissions = <List<DeckSummary>>[];
      final subscription = harness.deckRepository
          .watchDeckList(parentDeckId: null, now: now, utcOffset: Duration.zero)
          .listen((snapshot) => emissions.add(snapshot.decks));
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await harness.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('front'),
        back: cardText('back', side: CardSide.back),
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
