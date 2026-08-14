import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import 'support/study_harness.dart';

/// What the direction must **not** reach, and what a refusal must not leave
/// behind (BR-182, BR-187, BR-188).
///
/// **Driven through a real database, because every claim here is about rows.**
/// "`eight_box` stores no direction anywhere" and "a refused open writes no
/// session" are both statements about what is in the tables afterwards; a fake
/// would only prove the code calls the methods it was written to call.
///
/// The positive half — assignment, persistence and the history copy — is in
/// `study_direction_flow_test.dart`.
void main() {
  late StudyHarness h;

  setUp(() => h = StudyHarness());
  tearDown(() => h.close());

  Future<List<String?>> queueDirections(String sessionId) async {
    final rows = await h.rows(
      'SELECT direction FROM study_queue_items '
      "WHERE session_id = '$sessionId' ORDER BY position",
    );

    return rows.map((row) => row.read<String?>('direction')).toList();
  }

  Future<String?> sessionDirection(String sessionId) async {
    final row = (await h.rows(
      "SELECT direction FROM study_sessions WHERE id = '$sessionId'",
    )).single;

    return row.read<String?>('direction');
  }

  Future<List<String?>> answerDirections(String sessionId) async {
    final rows = await h.rows(
      'SELECT direction FROM study_answers '
      "WHERE session_id = '$sessionId' ORDER BY answered_at, id",
    );

    return rows.map((row) => row.read<String?>('direction')).toList();
  }

  /// Answers the turn the queue is serving, and returns the card it was.
  Future<String> answer(String sessionId, StudyAction action) async {
    final turn = (await h.repository.nextTurn(sessionId))!;
    await h.repository.submitAnswer(
      sessionId: sessionId,
      cardId: turn.cardId,
      mode: StudyMode.selfAssess,
      action: action,
      now: StudyHarness.now,
    );

    return turn.cardId;
  }

  group('eight_box cannot reach any of it (BR-182)', () {
    test('a review of it stores no direction anywhere', () async {
      final sessionId = await h.openReview(cardCount: 3);

      await answer(sessionId, StudyAction.remembered);

      expect(await sessionDirection(sessionId), isNull);
      expect(await queueDirections(sessionId), everyElement(isNull));
      expect(await answerDirections(sessionId), everyElement(isNull));
    });

    test('a graded stage handed one is refused outright', () async {
      // **The repository's own gate, and it refuses rather than filters.** An
      // earlier draft only gated the queue rows, so this call succeeded and left
      // a `study_sessions` row carrying `mixed` under a `match` review — a row
      // invariant 31 calls invalid, written by the layer that is supposed to
      // prevent it. The use case refuses this first (BR-187); the two guards
      // fail for different reasons, and only this one is at the write.
      await h.seedDeck(cardCount: 3);

      await expectLater(
        h.repository.openSession(
          deckId: 'd1',
          kind: StudySessionKind.reviewing,
          stageSequence: const <StudyMode>[StudyMode.match],
          cardLimit: 20,
          newCardOrder: NewCardOrder.created,
          now: StudyHarness.now,
          direction: StudySessionDirection.mixed,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(await h.rows('SELECT id FROM study_sessions'), isEmpty);
      expect(await h.rows('SELECT card_id FROM study_queue_items'), isEmpty);
    });
  });

  test('a learning chain handed a direction is refused, not filtered', () async {
    // **The behaviour this replaced was worse than useless.** An earlier draft
    // stamped the chain's `self_assess` rows and left its `browse` rows clean,
    // which reads as tidy and is a state invariant 31 calls invalid: a learning
    // chain does not choose its stages (BR-109), so it has no direction to
    // record on any of them. Refusing is the only answer that leaves the
    // database describable.
    await h.seedDeck(cardCount: 3, schedulerType: 'sm2');

    await expectLater(
      h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.learning,
        stageSequence: const <StudyMode>[
          StudyMode.browse,
          StudyMode.selfAssess,
        ],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
        direction: StudySessionDirection.koreanToMeaning,
      ),
      throwsA(isA<ConflictFailure>()),
    );

    expect(await h.rows('SELECT id FROM study_sessions'), isEmpty);
    expect(await h.rows('SELECT card_id FROM study_queue_items'), isEmpty);
  });

  test('a learning chain without one opens exactly as before', () async {
    // The other side of the refusal: nothing about BR-182 makes an ordinary
    // chain harder to open, and none of its rows gains a direction.
    await h.seedDeck(cardCount: 3, schedulerType: 'sm2');

    final session = await h.repository.openSession(
      deckId: 'd1',
      kind: StudySessionKind.learning,
      stageSequence: const <StudyMode>[StudyMode.browse, StudyMode.selfAssess],
      cardLimit: 20,
      newCardOrder: NewCardOrder.created,
      now: StudyHarness.now,
    );

    expect(await sessionDirection(session.id), isNull);
    expect(await queueDirections(session.id), everyElement(isNull));
  });

  group('the schedule is untouched (BR-188)', () {
    /// Every SRS number one `scheduled` turn wrote.
    Future<Map<String, Object?>> scheduleAfter(
      StudySessionDirection direction,
    ) async {
      final harness = StudyHarness();
      addTearDown(harness.close);

      final ids = await harness.seedDeck(cardCount: 1, schedulerType: 'sm2');
      await harness.makeDue(ids.single);

      final session = await harness.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        stageSequence: const <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
        direction: direction,
      );

      await harness.repository.submitAnswer(
        sessionId: session.id,
        cardId: ids.single,
        mode: StudyMode.selfAssess,
        action: StudyAction.hard,
        now: StudyHarness.now,
        nextDueAt: StudyHarness.now.add(const Duration(days: 3)),
        nextEaseFactor: 2.36,
        nextIntervalDays: 3,
      );

      final row = (await harness.rows(
        'SELECT due_at, ease_factor, interval_days, current_box, repetitions, '
        "answer_count, lapse_count FROM card_study_states "
        "WHERE card_id = '${ids.single}'",
      )).single;

      return row.data;
    }

    test('all three choices leave the same numbers behind', () async {
      // Direction changes the recall surface and nothing else. Asserted as
      // equality between whole rows rather than field by field, so a column
      // added later is covered without anyone remembering to add it here.
      final korean = await scheduleAfter(StudySessionDirection.koreanToMeaning);
      final meaning = await scheduleAfter(
        StudySessionDirection.meaningToKorean,
      );
      final mixed = await scheduleAfter(StudySessionDirection.mixed);

      expect(meaning, korean);
      expect(mixed, korean);
    });
  });

  group('refusals leave nothing behind', () {
    test('a direction this build cannot name is refused', () async {
      await h.seedDeck(cardCount: 2, schedulerType: 'sm2');

      await expectLater(
        h.repository.openSession(
          deckId: 'd1',
          kind: StudySessionKind.reviewing,
          stageSequence: const <StudyMode>[StudyMode.selfAssess],
          cardLimit: 20,
          newCardOrder: NewCardOrder.created,
          now: StudyHarness.now,
          direction: StudySessionDirection.unknown,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(await h.rows('SELECT id FROM study_sessions'), isEmpty);
    });

    test('nothing due writes no session and no queue row', () async {
      // BR-101 and BR-145, with a direction in hand: the refusal happens inside
      // the transaction, so a half-written session carrying a direction is not a
      // state this database can reach.
      await h.seedDeck(cardCount: 2, schedulerType: 'sm2');

      await expectLater(
        h.repository.openSession(
          deckId: 'd1',
          kind: StudySessionKind.reviewing,
          stageSequence: const <StudyMode>[StudyMode.selfAssess],
          cardLimit: 20,
          newCardOrder: NewCardOrder.created,
          now: StudyHarness.now,
          direction: StudySessionDirection.mixed,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(await h.rows('SELECT id FROM study_sessions'), isEmpty);
      expect(await h.rows('SELECT card_id FROM study_queue_items'), isEmpty);
    });

    test('a stale generation writes no answer, and no direction', () async {
      // BR-84. The turn is refused outright, so the history row that would have
      // carried the direction is never written.
      final sessionId = await h.openReview(
        cardCount: 2,
        schedulerType: 'sm2',
        direction: StudySessionDirection.mixed,
      );
      final turn = (await h.repository.nextTurn(sessionId))!;

      await h.db.customStatement(
        "UPDATE decks SET scheduler_generation = 2 WHERE id = 'd1'",
      );

      await expectLater(
        h.repository.submitAnswer(
          sessionId: sessionId,
          cardId: turn.cardId,
          mode: StudyMode.selfAssess,
          action: StudyAction.good,
          now: StudyHarness.now,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(await answerDirections(sessionId), isEmpty);
      expect(
        (await h.rows(
          "SELECT status FROM study_sessions WHERE id = '$sessionId'",
        )).single.read<String>('status'),
        'invalidated',
      );
    });
  });

  test('card content is never rewritten (BR-188)', () async {
    // The direction is a property of how a turn asked, not of the card. If it
    // ever became a property of the card, one learner's choice would rewrite
    // content every other stage reads.
    final sessionId = await h.openReview(
      cardCount: 3,
      schedulerType: 'sm2',
      direction: StudySessionDirection.meaningToKorean,
    );
    final before = await h.rows(
      'SELECT id, front, back, front_folded, back_folded, updated_at '
      'FROM cards ORDER BY id',
    );

    await answer(sessionId, StudyAction.good);

    final after = await h.rows(
      'SELECT id, front, back, front_folded, back_folded, updated_at '
      'FROM cards ORDER BY id',
    );

    expect(
      after.map((row) => row.data),
      before.map((row) => row.data).toList(),
    );
  });
}
