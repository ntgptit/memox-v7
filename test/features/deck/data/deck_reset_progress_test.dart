import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/failures/deck_conflict_failure.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import 'support/deck_repository_harness.dart';

/// Reset learning progress, against a real database (UC-07).
///
/// **Every claim here is about what is in the tables afterwards**, because that
/// is what the rules are about: BR-42 says which columns go back, BR-43 says
/// which rows stay, BR-49 says the tree may not end up holding two generations.
/// A fake repository could only assert that the code called the methods the code
/// calls.
void main() {
  final h = installDeckRepositoryHarness();

  /// A root with one card deck under it, one card in it, and that card learned
  /// and scheduled — the state a reset is meant to undo.
  Future<({String rootId, String cardId})> learnedTree({
    String scheduler = 'eight_box',
  }) async {
    await h.db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'first_answered_at, created_at, updated_at) '
      "VALUES ('root', 'Korean', 'root', 'deck', '$scheduler', 1, 1, "
      '1000, 0, 0)',
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
      'scheduler_version, scheduler_generation, learned_at, due_at, '
      'last_answered_at, answer_count, lapse_count, current_box) '
      "VALUES ('c1', '$scheduler', 1, 1, 1000, 2000, 1500, 4, 2, 6)",
    );

    return (rootId: 'root', cardId: 'c1');
  }

  Future<Map<String, Object?>> stateOf(String cardId) async {
    final rows = await h.db
        .customSelect(
          "SELECT * FROM card_study_states WHERE card_id = '$cardId'",
        )
        .get();

    return rows.single.data;
  }

  test(
    'it puts the card back where it started, and bumps the generation',
    () async {
      final tree = await learnedTree();

      await h.deckRepository.resetLearningProgress(
        rootDeckId: tree.rootId,
        schedulerType: SchedulerType.eightBox,
      );

      final state = await stateOf(tree.cardId);
      // BR-42 and BR-152: `learned_at` and `due_at` go NULL together, so the card
      // is back in the New set (BR-142) rather than merely due.
      expect(state['learned_at'], isNull);
      expect(state['due_at'], isNull);
      expect(state['last_answered_at'], isNull);
      expect(state['answer_count'], 0);
      expect(state['lapse_count'], 0);
      // BR-09's initialisation table — the state a card is *born* in, not a third
      // state that only exists after a reset.
      expect(state['current_box'], 1);
      // BR-40: exactly one.
      expect(state['scheduler_generation'], 2);

      final deck = await h.db
          .customSelect("SELECT * FROM decks WHERE id = 'root'")
          .getSingle();
      expect(deck.data['scheduler_generation'], 2);
      // BR-44: unlocked, and this is the only mechanism that unlocks it.
      expect(deck.data['first_answered_at'], isNull);
    },
  );

  test('it changes the scheduler, and the card follows the root', () async {
    // BR-13 locks the choice after the first card is learned; BR-44 makes this
    // the way out. Invariant 9 is the thing being protected: the tree must not
    // end up with a root on one algorithm and cards on another.
    final tree = await learnedTree();

    await h.deckRepository.resetLearningProgress(
      rootDeckId: tree.rootId,
      schedulerType: SchedulerType.sm2,
    );

    final state = await stateOf(tree.cardId);
    expect(state['scheduler_type'], 'sm2');
    expect(state['current_box'], isNull);
    expect(state['ease_factor'], 2.5);
    expect(state['interval_days'], 0);
    expect(state['repetitions'], 0);

    final deck = await h.db
        .customSelect("SELECT * FROM decks WHERE id = 'root'")
        .getSingle();
    expect(deck.data['scheduler_type'], 'sm2');
  });

  test(
    'it keeps the content, and it keeps the history (BR-41, BR-43)',
    () async {
      final tree = await learnedTree();
      await h.db.customStatement(
        'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
        'scheduler_generation, status, session_kind, current_mode, cursor, '
        'card_limit, started_at) '
        "VALUES ('s1', 'root', 'root', 1, 'in_progress', 'reviewing', "
        "'match', 0, 20, 0)",
      );
      await h.db.customStatement(
        'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
        'scheduler_generation, kind, mode, action, answered_at) '
        "VALUES ('a1', 'c1', 's1', 'eight_box', 1, 'scheduled', 'match', "
        "'remembered', 100)",
      );

      await h.deckRepository.resetLearningProgress(
        rootDeckId: tree.rootId,
        schedulerType: SchedulerType.eightBox,
      );

      // BR-43: the old turns stay, carrying the old generation. They are the
      // record of what happened, and a reset is not a claim that it did not.
      final answers = await h.db
          .customSelect('SELECT scheduler_generation FROM study_answers')
          .get();
      expect(answers, hasLength(1));
      expect(answers.single.data['scheduler_generation'], 1);

      // BR-41: the tree and its content are untouched.
      final decks = await h.db.customSelect('SELECT id FROM decks').get();
      expect(decks.map((row) => row.data['id']), <String>{'root', 'child'});
      final cards = await h.db.customSelect('SELECT id FROM cards').get();
      expect(cards, hasLength(1));
    },
  );

  test('it closes the open session as invalidated (BR-83, M5.14)', () async {
    // The one thing Reset owes Study, and the reason Deck reaches for Study's
    // contract at all. `scheduler_reset`, not `stale_generation`: this is the
    // reset closing its own sessions, not a session finding out afterwards.
    final tree = await learnedTree();
    await h.db.customStatement(
      'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
      'scheduler_generation, status, session_kind, current_mode, cursor, '
      'card_limit, started_at) '
      "VALUES ('s1', 'root', 'root', 1, 'in_progress', 'reviewing', "
      "'match', 0, 20, 0)",
    );

    await h.deckRepository.resetLearningProgress(
      rootDeckId: tree.rootId,
      schedulerType: SchedulerType.eightBox,
    );

    final session = await h.db
        .customSelect("SELECT * FROM study_sessions WHERE id = 's1'")
        .getSingle();
    expect(session.data['status'], 'invalidated');
    expect(session.data['end_reason'], 'scheduler_reset');
    expect(session.data['ended_at'], isNotNull);
  });

  test('a branch is refused, and nothing moves (A4)', () async {
    final tree = await learnedTree();

    await expectLater(
      h.deckRepository.resetLearningProgress(
        rootDeckId: 'child',
        schedulerType: SchedulerType.sm2,
      ),
      throwsA(
        isA<ConflictFailure>().having(
          (f) => f.reason,
          'reason',
          DeckConflictReason.resetNeedsRootDeck,
        ),
      ),
    );

    // The refusal is before any write, not a rollback after part of one.
    final state = await stateOf(tree.cardId);
    expect(state['learned_at'], isNotNull);
    expect(state['scheduler_generation'], 1);
  });

  test('an unknown scheduler is refused, and nothing moves', () async {
    final tree = await learnedTree();

    await expectLater(
      h.deckRepository.resetLearningProgress(
        rootDeckId: tree.rootId,
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

    final deck = await h.db
        .customSelect("SELECT * FROM decks WHERE id = 'root'")
        .getSingle();
    expect(deck.data['scheduler_generation'], 1);
    expect(deck.data['first_answered_at'], isNotNull);
  });
}
