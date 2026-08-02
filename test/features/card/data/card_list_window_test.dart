import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';

import '../../deck/data/support/deck_repository_harness.dart';
import 'support/card_text_fixture.dart';

/// The card list's window, on a real SQLite database.
///
/// **What is under test is the read plan, not just the rows.** The window
/// exists to stop `cardsByDeck` selecting a whole deck, and every property that
/// makes it work is invisible in the returned list: that the index supplies the
/// order so `LIMIT` can stop early, that no temporary B-tree is built, that
/// growing the window cannot duplicate or drop a row. So the plan is asserted
/// directly, and the timings are printed rather than asserted — a wall-clock
/// threshold in CI is a flake, but a number nobody can see is a number nobody
/// checks.
void main() {
  final h = installDeckRepositoryHarness();

  /// Seeds [count] cards into a leaf deck and returns its id.
  Future<String> seedCards(int count) async {
    final tree = await h.seedTree();
    for (var i = 0; i < count; i++) {
      // Distinct instants: the ordering pair is (created_at, id), and cards
      // sharing a millisecond would let `id` decide and hide an ordering bug.
      h.currentInstant = h.currentInstant.add(const Duration(seconds: 1));
      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('front $i'),
        back: cardText('back $i', side: CardSide.back),
      );
    }

    return tree.leaf.id;
  }

  Future<List<String>> explain(String deckId, int limit) async {
    final rows = await h.db
        .customSelect(
          'EXPLAIN QUERY PLAN '
          'SELECT * FROM cards WHERE deck_id = ? '
          'ORDER BY created_at DESC, id DESC LIMIT ?',
          variables: <Variable<Object>>[
            Variable<String>(deckId),
            Variable<int>(limit),
          ],
        )
        .get();

    return rows.map((QueryRow row) => row.read<String>('detail')).toList();
  }

  group('the read plan', () {
    test('DESC uses the composite index and builds no temp B-tree', () async {
      // The whole point of `idx_cards_deck_created (deck_id, created_at, id)`.
      // Without it SQLite sorts every matching row and *then* applies the
      // limit — measured at 1193us against 102us for a page of 50 — so a
      // `LIMIT` on an unindexed sort is a lid on the cost, not a removal of it.
      //
      // Asserted for DESC specifically: reading the index backwards is only
      // free while every ordering column runs the same direction, and this is
      // the assumption the whole window design rests on.
      final deckId = await seedCards(120);
      final plan = await explain(deckId, 50);

      expect(
        plan.join(' | '),
        contains('idx_cards_deck_created'),
        reason: 'the DESC read stopped using the index: ${plan.join(' | ')}',
      );
      expect(
        plan.join(' | '),
        isNot(contains('TEMP B-TREE')),
        reason:
            'SQLite is sorting the deck before applying the limit, which is '
            'exactly what the composite index exists to prevent: '
            '${plan.join(' | ')}',
      );
    });
  });

  group('the window', () {
    test('newest first, so a just-created card needs no scrolling', () async {
      // UC-04 A4 adds several cards in a row. Oldest-first put every one of
      // them at the far end of the deck.
      final deckId = await seedCards(60);
      final page = await h.cardRepository
          .watchCardsByDeck(deckId, limit: 10)
          .first;

      expect(page.first.front, 'front 59');
      expect(page.last.front, 'front 50');
    });

    test('the window caps the rows read, not the rows that exist', () async {
      final deckId = await seedCards(120);

      for (final int limit in <int>[1, 50, 100]) {
        final page = await h.cardRepository
            .watchCardsByDeck(deckId, limit: limit)
            .first;

        expect(page, hasLength(limit), reason: 'limit $limit');
      }
      expect(await h.cardRepository.watchCardCountByDeck(deckId).first, 120);
    });

    test('asking past the end returns what exists, not an error', () async {
      final deckId = await seedCards(3);
      final page = await h.cardRepository
          .watchCardsByDeck(deckId, limit: 50)
          .first;

      expect(page, hasLength(3));
    });

    test('a window under one row is refused, not silently unbounded', () async {
      // SQLite reads a negative LIMIT as "no limit", so the parameter meant to
      // bound the read would deliver the unbounded read instead — the failure
      // this whole change exists to prevent, arriving through its own guard.
      final deckId = await seedCards(2);

      for (final int limit in <int>[0, -1]) {
        expect(
          () => h.cardRepository.watchCardsByDeck(deckId, limit: limit),
          throwsA(isA<ArgumentError>()),
          reason: 'limit $limit',
        );
      }
    });

    test('growing the window never duplicates or drops a row', () async {
      // The correctness argument for a re-read window over an `OFFSET` page:
      // an insert above the window shifts an offset, so the reader sees one row
      // twice or misses one. Here the wider window is a superset of the
      // narrower one, with a card created in between.
      final deckId = await seedCards(30);
      final first = await h.cardRepository
          .watchCardsByDeck(deckId, limit: 10)
          .first;

      h.currentInstant = h.currentInstant.add(const Duration(seconds: 1));
      await h.cardRepository.createCard(
        deckId: deckId,
        front: cardText('newest'),
        back: cardText('b', side: CardSide.back),
      );

      final second = await h.cardRepository
          .watchCardsByDeck(deckId, limit: 20)
          .first;
      final ids = second.map((CardEntity c) => c.id).toList();

      expect(ids.toSet(), hasLength(ids.length), reason: 'a row appears twice');
      expect(second.first.front, 'newest');
      // Every card the narrow window showed is still present, none skipped.
      for (final CardEntity card in first) {
        expect(
          ids,
          contains(card.id),
          reason: '${card.front} fell out of the wider window',
        );
      }
    });

    test('a write re-emits the window it belongs to', () async {
      final deckId = await seedCards(5);
      final emissions = <List<CardEntity>>[];
      final subscription = h.cardRepository
          .watchCardsByDeck(deckId, limit: 50)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      h.currentInstant = h.currentInstant.add(const Duration(seconds: 1));
      final card = await h.cardRepository.createCard(
        deckId: deckId,
        front: cardText('added'),
        back: cardText('b', side: CardSide.back),
      );
      await pumpEventQueue();
      expect(emissions.last.first.front, 'added');

      await h.cardRepository.deleteCard(card.id);
      await pumpEventQueue();
      expect(emissions.last, hasLength(5));
    });

    test('the count follows writes too', () async {
      final deckId = await seedCards(4);
      final counts = <int>[];
      final subscription = h.cardRepository
          .watchCardCountByDeck(deckId)
          .listen(counts.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(counts.last, 4);

      h.currentInstant = h.currentInstant.add(const Duration(seconds: 1));
      await h.cardRepository.createCard(
        deckId: deckId,
        front: cardText('one more'),
        back: cardText('b', side: CardSide.back),
      );
      await pumpEventQueue();

      expect(counts.last, 5);
    });
  });

  group('cost, measured rather than assumed', () {
    test('a window read scales with the window, not with the deck', () async {
      // Printed, not asserted. The shape is what matters: reading 50 rows out
      // of a large deck must not cost what reading the deck costs, and a
      // regression shows as the two numbers converging.
      //
      // This is a debug VM on a developer machine, so the absolute numbers are
      // not the device's. Point 5 of the M4.11 design review asks for the same
      // measurement on the target Android device, end to end from database
      // invalidation to a settled frame; that belongs with the screen, which
      // does not exist yet.
      const deckSize = 800;
      final deckId = await seedCards(deckSize);

      final timings = <int, int>{};
      for (final int limit in <int>[50, 200, deckSize]) {
        final watch = Stopwatch()..start();
        final page = await h.cardRepository
            .watchCardsByDeck(deckId, limit: limit)
            .first;
        watch.stop();
        timings[limit] = watch.elapsedMicroseconds;
        expect(page, hasLength(limit));
      }

      // ignore: avoid_print — the number is the deliverable of this test.
      print('card window read (deck of $deckSize): $timings microseconds');

      expect(
        timings[50],
        lessThan(timings[deckSize]!),
        reason:
            'a page of 50 costs as much as the whole deck — the LIMIT is no '
            'longer stopping early. Measured: $timings',
      );
    });
  });
}
