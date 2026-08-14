import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';

import '../../../database/support/test_database.dart';
import 'support/study_home_db_harness.dart';

/// What Study Home counts, and how it ranks what it counted (UC-12, BR-183).
///
/// The predicates are held against real SQLite because that is what is in doubt:
/// whether the aggregate reaches every depth, whether the due set is partitioned
/// exactly at the local-day boundary, and whether the ranking survives a tie.
void main() {
  late StudyHomeDbHarness harness;
  late AppDatabase db;
  final day = StudyHomeDbHarness.day;

  setUp(() {
    harness = StudyHomeDbHarness();
    db = harness.db;
  });

  Future<StudyHomeModel> read() => harness.read();

  Future<void> seedDueCard(
    String id, {
    required String deckId,
    required Duration before,
  }) => harness.seedDueCard(id, deckId: deckId, before: before);

  Future<void> seedNewCard(String id, {required String deckId}) =>
      harness.seedNewCard(id, deckId: deckId);

  group('workload', () {
    test('aggregates the whole subtree, at every depth', () async {
      // Three levels, one due card each. The read groups by `root_deck_id`
      // (BR-56, BR-57), which is why it needs no recursion — and why a card at
      // level 3 must still be counted against the root.
      await insertRootDeck(db, id: 'root');
      await insertSubDeck(
        db,
        id: 'branch',
        parentId: 'root',
        rootDeckId: 'root',
      );
      await insertSubDeck(
        db,
        id: 'leaf',
        parentId: 'branch',
        rootDeckId: 'root',
      );
      for (final deckId in <String>['root', 'branch', 'leaf']) {
        await seedDueCard(
          'c-$deckId',
          deckId: deckId,
          before: const Duration(hours: 1),
        );
      }

      final home = await read();

      expect(home.decks, hasLength(1));
      expect(home.decks.single.dueTodayCount, 3);
      expect(home.decks.single.totalCardCount, 3);
    });

    test('splits due exactly at the local-day boundary', () async {
      // BR-162's partition. `startOfToday` is 00:00Z; the three cards sit one
      // second before it, exactly on it, and at the read instant — so every
      // boundary this rule has is constructed rather than assumed.
      await insertRootDeck(db, id: 'root');
      await insertCard(db, id: 'yesterday', deckId: 'root');
      await insertReviewState(
        db,
        cardId: 'yesterday',
        dueAt: day.startOfToday.subtract(const Duration(seconds: 1)),
      );
      await insertCard(db, id: 'midnight', deckId: 'root');
      await insertReviewState(db, cardId: 'midnight', dueAt: day.startOfToday);
      await insertCard(db, id: 'now', deckId: 'root');
      await insertReviewState(db, cardId: 'now', dueAt: testNow);

      final deck = (await read()).decks.single;

      expect(deck.overdueCount, 1);
      expect(deck.dueTodayCount, 2);
      // The partition closes: the two halves are the whole Reviewing set of
      // BR-142, so a session still draws from one number.
      expect(deck.dueCount, deck.overdueCount + deck.dueTodayCount);
    });

    test('a card due after now counts in neither half', () async {
      await insertRootDeck(db, id: 'root');
      await insertCard(db, id: 'later', deckId: 'root');
      await insertReviewState(
        db,
        cardId: 'later',
        dueAt: testNow.add(const Duration(seconds: 1)),
      );

      final deck = (await read()).decks.single;

      expect(deck.dueCount, 0);
      expect(deck.newCount, 0);
      expect(deck.totalCardCount, 1);
    });

    test('new is the other side of learned_at, never a subtraction', () async {
      await insertRootDeck(db, id: 'root');
      await seedNewCard('new-1', deckId: 'root');
      await seedDueCard(
        'due-1',
        deckId: 'root',
        before: const Duration(days: 3),
      );

      final deck = (await read()).decks.single;

      expect(deck.newCount, 1);
      expect(deck.overdueCount, 1);
      expect(deck.dueTodayCount, 0);
    });

    test('sibling trees are counted apart', () async {
      await insertRootDeck(db, id: 'a');
      await insertRootDeck(db, id: 'b');
      await seedDueCard('c-a', deckId: 'a', before: const Duration(days: 2));
      await seedNewCard('c-b', deckId: 'b');

      final home = await read();

      final a = home.decks.firstWhere((deck) => deck.deckId == 'a');
      final b = home.decks.firstWhere((deck) => deck.deckId == 'b');
      expect(a.overdueCount, 1);
      expect(a.newCount, 0);
      expect(b.overdueCount, 0);
      expect(b.newCount, 1);
    });

    test('a root with no cards is listed, with zeroes', () async {
      // It has to be listed: dropping it in SQL would make "decks but no cards"
      // indistinguishable from "no decks", and those are two screens (BR-184).
      await insertRootDeck(db, id: 'root');

      final home = await read();

      expect(home.decks.single.totalCardCount, 0);
      expect(home.decks.single.hasWorkload, isFalse);
      expect(home.decks.single.isStudiable, isFalse);
      expect(home.hasNoCards, isTrue);
      expect(home.studiableDecks, isEmpty);
    });

    test('no decks at all is the empty-library state', () async {
      final home = await read();

      expect(home.decks, isEmpty);
      expect(home.isLibraryEmpty, isTrue);
      // Not the same state, and the difference decides which screen renders.
      expect(home.hasNoCards, isFalse);
      expect(home.resume, isNull);
    });

    test('a sub-deck never appears as a row of its own', () async {
      await insertRootDeck(db, id: 'root');
      await insertSubDeck(
        db,
        id: 'branch',
        parentId: 'root',
        rootDeckId: 'root',
      );

      final home = await read();

      expect(home.decks.map((deck) => deck.deckId), <String>['root']);
    });

    test('the scheduler is the root-s own, and null degrades', () async {
      await insertRootDeck(db, id: 'sm2', schedulerType: 'sm2');
      await insertRootDeck(db, id: 'none', schedulerType: null);

      final home = await read();

      expect(
        home.decks.firstWhere((deck) => deck.deckId == 'sm2').schedulerType,
        SchedulerType.sm2,
      );
      // Listed and openable; only the label is withheld.
      expect(
        home.decks.firstWhere((deck) => deck.deckId == 'none').schedulerType,
        SchedulerType.unknown,
      );
    });
  });

  group('ordering (BR-183)', () {
    test('overdue outranks due today, which outranks new', () async {
      await insertRootDeck(db, id: 'new-heavy');
      await insertRootDeck(db, id: 'due-today');
      await insertRootDeck(db, id: 'overdue');
      for (var i = 0; i < 50; i++) {
        await seedNewCard('n$i', deckId: 'new-heavy');
      }
      for (var i = 0; i < 10; i++) {
        await seedDueCard(
          't$i',
          deckId: 'due-today',
          before: const Duration(hours: 1),
        );
      }
      await seedDueCard(
        'o0',
        deckId: 'overdue',
        before: const Duration(days: 4),
      );

      final home = await read();

      // One overdue card beats ten due today, which beats fifty new: the keys
      // are ranked, not summed. A total would have put `new-heavy` first.
      expect(home.decks.map((deck) => deck.deckId), <String>[
        'overdue',
        'due-today',
        'new-heavy',
      ]);
    });

    test('a deck with no workload sorts last but stays studiable', () async {
      await insertRootDeck(db, id: 'quiet');
      await insertRootDeck(db, id: 'busy');
      await insertCard(db, id: 'resting', deckId: 'quiet');
      await insertReviewState(
        db,
        cardId: 'resting',
        dueAt: testNow.add(const Duration(days: 5)),
      );
      await seedNewCard('n0', deckId: 'busy');

      final home = await read();

      expect(home.decks.map((deck) => deck.deckId), <String>['busy', 'quiet']);
      expect(home.studiableDecks.map((deck) => deck.deckId), <String>[
        'busy',
        'quiet',
      ]);
    });

    test('ties break on the folded name, then the id', () async {
      // Three decks with identical (0, 0, 0) workload. `Đà Nẵng` is the case that
      // makes the fold load-bearing: SQLite-s `lower()` leaves `Đ` alone, so an
      // ORDER BY in SQL would sort it by the uppercase byte and put it before
      // `apple` — Dart-s Unicode-aware fold does not.
      await insertRootDeck(db, id: 'z-id');
      await insertRootDeck(db, id: 'a-id');
      await insertRootDeck(db, id: 'diacritic');
      await db.customStatement(
        "UPDATE decks SET name = 'apple' WHERE id = 'z-id'",
      );
      await db.customStatement(
        "UPDATE decks SET name = 'apple' WHERE id = 'a-id'",
      );
      await db.customStatement(
        "UPDATE decks SET name = 'Đà Nẵng' WHERE id = 'diacritic'",
      );

      final home = await read();

      expect(home.decks.map((deck) => deck.deckId), <String>[
        'a-id',
        'z-id',
        'diacritic',
      ]);
    });
  });

  group('expiry', () {
    test('nextDueAt is the earliest card strictly after now', () async {
      await insertRootDeck(db, id: 'root');
      await insertCard(db, id: 'soon', deckId: 'root');
      await insertReviewState(
        db,
        cardId: 'soon',
        dueAt: testNow.add(const Duration(hours: 3)),
      );
      await insertCard(db, id: 'later', deckId: 'root');
      await insertReviewState(
        db,
        cardId: 'later',
        dueAt: testNow.add(const Duration(days: 9)),
      );

      final home = await read();

      expect(home.nextDueAt, testNow.add(const Duration(hours: 3)));
      // Nothing is due, so midnight moves nothing and no timer is asked for.
      expect(home.nextOverdueTickAt, isNull);
    });

    test('an open session arms the midnight tick even with nothing due', () async {
      // BR-182 offers a session back only while it belongs to the current study
      // day, and that window shuts at the same boundary the due split moves at.
      // A library of unlearned cards has no `due_at` at all, so `nextDueAt` is
      // null — and the tick was null too, which left a tab open across midnight
      // still offering a session BR-103 had already made stale.
      await insertRootDeck(db, id: 'root');
      await seedNewCard('c0', deckId: 'root');
      await insertSession(
        db,
        id: 's1',
        deckId: 'root',
        rootDeckId: 'root',
        sessionKind: 'learning',
        currentMode: 'browse',
      );
      await db.customInsert(
        'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
        "position, status) VALUES ('s1', 'browse', 1, 'c0', 0, 'pending')",
      );

      final home = await read();

      expect(home.resume, isNotNull);
      expect(home.nextDueAt, isNull);
      expect(home.nextOverdueTickAt, day.startOfDayAfter(1));
    });

    test(
      'the overdue tick is the next local midnight when anything is due',
      () async {
        await insertRootDeck(db, id: 'root');
        await seedDueCard(
          'c0',
          deckId: 'root',
          before: const Duration(hours: 1),
        );

        final home = await read();

        expect(home.nextOverdueTickAt, day.startOfDayAfter(1));
        // Every scheduled card is already due, so `nextDueAt` is null — which is
        // exactly the hole the tick exists to close (BR-161).
        expect(home.nextDueAt, isNull);
      },
    );
  });
}
