import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/failures/deck_conflict_failure.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// Changing the study mode while the scheduler is still unlocked (UC-03,
/// BR-12), against a real database.
///
/// **The whole reason this is not `resetLearningProgress` with a flag is one
/// column**, and every test here is ultimately about it: `scheduler_generation`
/// must not move (UC-03 postcondition). A deck where nothing has been learned
/// has no cycle to throw away, so spending a generation would file an empty
/// history under a superseded number and make the *next* reset the second one.
void main() {
  final h = installDeckRepositoryHarness();

  /// A root with a card deck under it and one card that has never been learned
  /// — the state BR-12 calls unlocked.
  Future<void> unlockedTree({String scheduler = 'eight_box'}) async {
    await h.db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('root', 'Korean', 'root', 'deck', '$scheduler', 1, 1, 0, 0)",
    );
    await h.db.customStatement(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('child', 'Chapter 1', 'root', 'root', 'card', 0, 0)",
    );
    await h.db.customStatement(
      'INSERT INTO cards (id, deck_id, front, back, front_folded, '
      'back_folded, created_at, updated_at) '
      "VALUES ('c1', 'child', 'front', 'back', 'front', 'back', 0, 0)",
    );
    await h.db.customStatement(
      'INSERT INTO card_study_states (card_id, scheduler_type, '
      'scheduler_version, scheduler_generation, answer_count, lapse_count, '
      "current_box) VALUES ('c1', '$scheduler', 1, 1, 0, 0, 1)",
    );
  }

  Future<Map<String, Object?>> rowOf(String sql) async =>
      (await h.db.customSelect(sql).get()).single.data;

  Future<Map<String, Object?>> deckRow(String id) =>
      rowOf("SELECT * FROM decks WHERE id = '$id'");

  Future<Map<String, Object?>> stateOf(String cardId) =>
      rowOf("SELECT * FROM card_study_states WHERE card_id = '$cardId'");

  test('eight-box to SM-2 re-seeds the tree in the new shape', () async {
    await unlockedTree();

    await h.deckRepository.changeUnlockedScheduler(
      rootDeckId: 'root',
      schedulerType: SchedulerType.sm2,
    );

    expect((await deckRow('root'))['scheduler_type'], 'sm2');

    final state = await stateOf('c1');
    // BR-14: the card is initialised for the algorithm it now runs. An `sm2`
    // card holding a box is exactly the mixed shape invariant 9 catches.
    expect(state['scheduler_type'], 'sm2');
    expect(state['current_box'], isNull);
    expect(state['interval_days'], isNotNull);
    expect(state['ease_factor'], isNotNull);
  });

  test('SM-2 to eight-box re-seeds it the other way', () async {
    await unlockedTree(scheduler: 'sm2');

    await h.deckRepository.changeUnlockedScheduler(
      rootDeckId: 'root',
      schedulerType: SchedulerType.eightBox,
    );

    final state = await stateOf('c1');
    expect((await deckRow('root'))['scheduler_type'], 'eight_box');
    expect(state['scheduler_type'], 'eight_box');
    expect(state['current_box'], isNotNull);
    expect(state['interval_days'], isNull);
  });

  test('the generation does not move, and the deck stays unlocked', () async {
    await unlockedTree();

    await h.deckRepository.changeUnlockedScheduler(
      rootDeckId: 'root',
      schedulerType: SchedulerType.sm2,
    );

    final root = await deckRow('root');
    // The line that makes this a different operation from Reset.
    expect(root['scheduler_generation'], 1);
    expect(root['first_answered_at'], isNull);
    // And the card keeps the root's number, so invariant 9 stays quiet.
    expect((await stateOf('c1'))['scheduler_generation'], 1);
  });

  test('content, tags and history are not touched', () async {
    await unlockedTree();

    await h.deckRepository.changeUnlockedScheduler(
      rootDeckId: 'root',
      schedulerType: SchedulerType.sm2,
    );

    final card = await rowOf("SELECT * FROM cards WHERE id = 'c1'");
    expect(card['front'], 'front');
    expect(card['back'], 'back');
    expect(
      await h.db.customSelect('SELECT id FROM study_answers').get(),
      isEmpty,
    );
  });

  test('choosing the mode it already runs is accepted and changes nothing the '
      'user can see', () async {
    await unlockedTree();

    await h.deckRepository.changeUnlockedScheduler(
      rootDeckId: 'root',
      schedulerType: SchedulerType.eightBox,
    );

    final root = await deckRow('root');
    expect(root['scheduler_type'], 'eight_box');
    expect(root['scheduler_generation'], 1);
    expect(root['first_answered_at'], isNull);
    // Not even `updated_at`: the operation returns before the write, so this
    // deck does not jump to the top of the Recent sort for a change of nothing.
    expect(root['updated_at'], 0);
    expect((await stateOf('c1'))['scheduler_type'], 'eight_box');
  });

  group('what it refuses', () {
    test('a locked root, without changing anything (BR-13)', () async {
      await unlockedTree();
      await h.db.customStatement(
        "UPDATE decks SET first_answered_at = 1000 WHERE id = 'root'",
      );

      await expectLater(
        h.deckRepository.changeUnlockedScheduler(
          rootDeckId: 'root',
          schedulerType: SchedulerType.sm2,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            DeckConflictReason.schedulerLocked,
          ),
        ),
      );

      // Nothing moved: not the deck, and not the tree it would have re-seeded.
      expect((await deckRow('root'))['scheduler_type'], 'eight_box');
      expect((await stateOf('c1'))['scheduler_type'], 'eight_box');
    });

    test('a sub-deck (BR-05, BR-06)', () async {
      await unlockedTree();

      await expectLater(
        h.deckRepository.changeUnlockedScheduler(
          rootDeckId: 'child',
          schedulerType: SchedulerType.sm2,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            DeckConflictReason.schedulerNeedsRootDeck,
          ),
        ),
      );

      expect((await deckRow('root'))['scheduler_type'], 'eight_box');
      expect((await deckRow('child'))['scheduler_type'], isNull);
    });

    test('a scheduler this build does not know', () async {
      await unlockedTree();

      await expectLater(
        h.deckRepository.changeUnlockedScheduler(
          rootDeckId: 'root',
          schedulerType: SchedulerType.unknown,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            DeckConflictReason.resetSchedulerUnknown,
          ),
        ),
      );

      expect((await deckRow('root'))['scheduler_type'], 'eight_box');
    });

    test('a deck that is not there', () async {
      await expectLater(
        h.deckRepository.changeUnlockedScheduler(
          rootDeckId: 'ghost',
          schedulerType: SchedulerType.sm2,
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  test(
    'a failure part-way through leaves the deck and the tree as they were',
    () async {
      // The unknown-scheduler refusal is thrown *after* the root has been read and
      // before anything is written, so it also proves the transaction boundary:
      // a partial run would leave a root on one algorithm and its cards on
      // another, which is invariant 9's whole subject.
      await unlockedTree();
      await h.db.customStatement(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, created_at, updated_at) '
        "VALUES ('c2', 'child', 'f2', 'b2', 'f2', 'b2', 0, 0)",
      );
      await h.db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        "current_box) VALUES ('c2', 'eight_box', 1, 1, 0, 0, 1)",
      );

      await expectLater(
        h.deckRepository.changeUnlockedScheduler(
          rootDeckId: 'root',
          schedulerType: SchedulerType.unknown,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      final mixed = await h.db
          .customSelect(
            'SELECT s.card_id FROM card_study_states s '
            'JOIN cards c ON c.id = s.card_id '
            'JOIN decks d ON d.id = c.deck_id '
            'JOIN decks root ON root.id = d.root_deck_id '
            'WHERE s.scheduler_type <> root.scheduler_type',
          )
          .get();
      expect(mixed, isEmpty);
    },
  );

  group('the open session', () {
    /// The Study repository over the *same* database, so a session opened here
    /// is the session the deck operation has to close.
    StudyRepositoryImpl studyRepository() =>
        StudyRepositoryImpl(StudyDao(h.db), idGenerator: () => 'session-1');

    Future<String> openSession() async {
      final session = await studyRepository().openSession(
        deckId: 'root',
        kind: StudySessionKind.learning,
        stageSequence: <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: testNow,
      );

      return session.id;
    }

    test('is invalidated by the change, in the same transaction', () async {
      // **The policy, and it is system-owned.** The queue was dealt for the old
      // algorithm; the generation is unchanged, so BR-84's stale check would
      // wave every one of its answers straight through into a tree that has
      // just been re-seeded. Leaving it open and asking the user to reset is
      // handing them a chore to fix something the app did.
      await unlockedTree();
      final sessionId = await openSession();

      await h.deckRepository.changeUnlockedScheduler(
        rootDeckId: 'root',
        schedulerType: SchedulerType.sm2,
      );

      final session = await rowOf(
        "SELECT * FROM study_sessions WHERE id = '$sessionId'",
      );
      expect(session['status'], 'invalidated');
      expect(session['end_reason'], 'scheduler_reset');
      expect(session['ended_at'], isNotNull);
    });

    test('a no-op change leaves the session open', () async {
      // Confirming the row that was already selected is not a change, and it
      // must not cost the user the session they are in the middle of. Without
      // the short-circuit this re-seeds the tree and kills the session for a
      // difference of nothing.
      await unlockedTree();
      final sessionId = await openSession();

      await h.deckRepository.changeUnlockedScheduler(
        rootDeckId: 'root',
        schedulerType: SchedulerType.eightBox,
      );

      final session = await rowOf(
        "SELECT * FROM study_sessions WHERE id = '$sessionId'",
      );
      expect(session['status'], 'in_progress');
    });

    test('a refused change leaves the session open', () async {
      await unlockedTree();
      final sessionId = await openSession();
      await h.db.customStatement(
        "UPDATE decks SET first_answered_at = 1000 WHERE id = 'root'",
      );

      await expectLater(
        h.deckRepository.changeUnlockedScheduler(
          rootDeckId: 'root',
          schedulerType: SchedulerType.sm2,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      final session = await rowOf(
        "SELECT * FROM study_sessions WHERE id = '$sessionId'",
      );
      expect(session['status'], 'in_progress');
      expect(session['end_reason'], isNull);
    });
  });

  test(
    'once a card finishes the chain the change is refused and Reset is not',
    () async {
      // **The two halves of this task meeting.** BR-13's lock is written by
      // `completeLearning`; BR-12's change reads it. Before the lock existed the
      // first assertion here passed for the wrong reason — the column was NULL
      // forever — so a fully learned deck could have its algorithm swapped.
      await unlockedTree();
      await StudyRepositoryImpl(StudyDao(h.db)).completeLearning(
        cardId: 'c1',
        learnedAt: testNow,
        dueAt: testNow.add(const Duration(days: 1)),
      );

      await expectLater(
        h.deckRepository.changeUnlockedScheduler(
          rootDeckId: 'root',
          schedulerType: SchedulerType.sm2,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            DeckConflictReason.schedulerLocked,
          ),
        ),
      );

      // BR-44: Reset is the way through, and it unlocks the deck again.
      await h.deckRepository.resetLearningProgress(
        rootDeckId: 'root',
        schedulerType: SchedulerType.sm2,
      );

      final root = await deckRow('root');
      expect(root['first_answered_at'], isNull);
      expect(root['scheduler_generation'], 2);
      expect(root['scheduler_type'], 'sm2');
    },
  );
}
