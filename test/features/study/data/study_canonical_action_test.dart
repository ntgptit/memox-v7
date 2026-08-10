import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import 'support/study_harness.dart';

/// What may reach `study_answers.action`, and what a wrong answer does to the
/// round (BR-120, BR-132, BR-116).
///
/// **The two halves are asserted together on purpose.** BR-120 says a level
/// that is not "right" goes into the round-s failed set *and* never appears in
/// the column; checking either alone passes on an implementation that gets the
/// other one wrong. The failed set is driven by `isLapse`, and `isLapse` is only
/// meaningful for an action the card-s own algorithm declares — so the two
/// clauses are one mechanism, and this file is where that shows.
///
/// A real database rather than a fake repository: the claim is about a column-s
/// contents and about rows appearing in round 2, and a fake would only assert
/// that the code calls the methods the code calls.
void main() {
  late StudyHarness harness;

  setUp(() => harness = StudyHarness());
  tearDown(() => harness.close());

  Future<List<String>> actionsIn(String sessionId) async {
    final rows = await harness.rows(
      "SELECT action FROM study_answers WHERE session_id = '$sessionId'",
    );

    return rows.map((row) => row.read<String>('action')).toList();
  }

  Future<List<int>> roundsOf(String cardId) async {
    final rows = await harness.rows(
      'SELECT round FROM study_queue_items '
      "WHERE card_id = '$cardId' ORDER BY round",
    );

    return rows.map((row) => row.read<int>('round')).toList();
  }

  group('a wrong match answer', () {
    test('lands in the next round and stores the canonical action', () async {
      final sessionId = await harness.openReview(
        cardCount: 3,
        mode: StudyMode.match,
      );

      await harness.repository.submitAnswer(
        sessionId: sessionId,
        cardId: 'c0',
        mode: StudyMode.match,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
      );

      // BR-116: enrolled at the moment of failure, so a later correct answer
      // cannot erase it.
      expect(await roundsOf('c0'), <int>[1, 2]);

      // BR-120, BR-132: the algorithm-s own vocabulary, not a feedback level and
      // not the word on the button.
      expect(await actionsIn(sessionId), <String>['forgotten']);
    });

    test(
      'still counts as failed after the card is later answered right',
      () async {
        final sessionId = await harness.openReview(
          cardCount: 3,
          mode: StudyMode.match,
        );

        await harness.repository.submitAnswer(
          sessionId: sessionId,
          cardId: 'c0',
          mode: StudyMode.match,
          action: StudyAction.forgotten,
          now: StudyHarness.now,
        );
        await harness.repository.submitAnswer(
          sessionId: sessionId,
          cardId: 'c0',
          mode: StudyMode.match,
          action: StudyAction.remembered,
          now: StudyHarness.now,
        );

        expect(await roundsOf('c0'), <int>[1, 2]);
        expect(await actionsIn(sessionId), <String>['forgotten', 'remembered']);
      },
    );
  });

  group('an action the card-s algorithm does not use', () {
    test('is refused before anything is written', () async {
      final sessionId = await harness.openReview(
        cardCount: 3,
        mode: StudyMode.match,
      );

      // `easy` is `sm2` vocabulary. It stores cleanly and reads as nonsense
      // afterwards: `isLapse` says it was not a lapse, and `EightBoxScheduler`
      // has no branch for it, so the row would grade as "right" forever.
      await expectLater(
        harness.repository.submitAnswer(
          sessionId: sessionId,
          cardId: 'c0',
          mode: StudyMode.match,
          action: StudyAction.easy,
          now: StudyHarness.now,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(await actionsIn(sessionId), isEmpty);

      // Refused *before* the write, not rolled back after part of it: the card
      // is still where it was, with no round 2 and no cursor movement.
      expect(await roundsOf('c0'), <int>[1]);

      final session = await harness.rows(
        "SELECT cursor FROM study_sessions WHERE id = '$sessionId'",
      );
      expect(session.single.read<int>('cursor'), 0);
    });

    test('is refused for the other algorithm too', () async {
      final ids = await harness.seedDeck(cardCount: 3, schedulerType: 'sm2');
      for (final id in ids) {
        await harness.makeDue(id);
      }

      final session = await harness.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        stageSequence: const <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );

      await expectLater(
        harness.repository.submitAnswer(
          sessionId: session.id,
          cardId: 'c0',
          mode: StudyMode.selfAssess,
          action: StudyAction.remembered,
          now: StudyHarness.now,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(await actionsIn(session.id), isEmpty);

      // And the algorithm-s own action goes through, so the refusal is a rule
      // about vocabulary rather than a stage that stopped accepting answers.
      await harness.repository.submitAnswer(
        sessionId: session.id,
        cardId: 'c0',
        mode: StudyMode.selfAssess,
        action: StudyAction.good,
        now: StudyHarness.now,
      );

      expect(await actionsIn(session.id), <String>['good']);
    });
  });

  group('what a wrong `match` pair does to the queue (BR-118)', () {
    /// Every queue row of this session, as `(round, cardId, status)`.
    ///
    /// Read from the database rather than through the repository: the claim is
    /// about which rows exist and what state they are in, and the read API
    /// deliberately hides that.
    Future<List<(int, String, String)>> queueRows(String sessionId) async {
      final rows = await harness.rows(
        "SELECT round, card_id, status FROM study_queue_items "
        "WHERE session_id = '$sessionId' AND mode = 'match' "
        'ORDER BY round, card_id',
      );

      return <(int, String, String)>[
        for (final row in rows)
          (
            row.read<int>('round'),
            row.read<String>('card_id'),
            row.read<String>('status'),
          ),
      ];
    }

    test('keeps this round pending and enrols the next one, once', () async {
      final sessionId = await harness.openReview(
        cardCount: 2,
        mode: StudyMode.match,
      );
      final cardId = (await harness.repository.nextTurn(sessionId))!.cardId;

      // Twice, because a board keeps the pair on screen and a person who got it
      // wrong once will reach for it again.
      for (var i = 0; i < 2; i++) {
        await harness.repository.submitAnswer(
          sessionId: sessionId,
          cardId: cardId,
          mode: StudyMode.match,
          action: StudyAction.forgotten,
          now: StudyHarness.now,
        );
      }

      final rows = await queueRows(sessionId);

      // The row it was answered on is still open: the pair is still on the
      // board, and `completedCardIds` — which is what empties a slot — must not
      // contain it.
      expect(
        rows.where((row) => row.$1 == 1 && row.$2 == cardId),
        <(int, String, String)>[(1, cardId, 'pending')],
      );

      // And exactly one round-2 row, not two. `enrolInRound` inserts-or-ignores
      // for precisely this: failing the same card four times is one enrolment
      // (BR-116).
      expect(rows.where((row) => row.$1 == 2 && row.$2 == cardId).length, 1);
    });

    test('a later correct pair completes the row it was answered on', () async {
      final sessionId = await harness.openReview(
        cardCount: 2,
        mode: StudyMode.match,
      );
      final cardId = (await harness.repository.nextTurn(sessionId))!.cardId;

      for (final action in <StudyAction>[
        StudyAction.forgotten,
        StudyAction.remembered,
      ]) {
        await harness.repository.submitAnswer(
          sessionId: sessionId,
          cardId: cardId,
          mode: StudyMode.match,
          action: action,
          now: StudyHarness.now,
        );
      }

      final rows = await queueRows(sessionId);

      expect(
        rows.where((row) => row.$1 == 1 && row.$2 == cardId),
        <(int, String, String)>[(1, cardId, 'completed')],
      );

      // The enrolment stands. BR-116: a card that failed at any point in a
      // round belongs to that round's failed set *even after* it is answered
      // correctly to clear the board — clearing it here is what would let a
      // later right answer erase the earlier wrong one.
      expect(rows.where((row) => row.$1 == 2 && row.$2 == cardId).length, 1);
    });

    test(
      'a reopened session sees the same cleared and pending pairs',
      () async {
        final sessionId = await harness.openReview(
          cardCount: 2,
          mode: StudyMode.match,
        );
        final cards = await harness.repository.sessionCards(sessionId);

        await harness.repository.submitAnswer(
          sessionId: sessionId,
          cardId: cards.first.id,
          mode: StudyMode.match,
          action: StudyAction.remembered,
          now: StudyHarness.now,
        );
        await harness.repository.submitAnswer(
          sessionId: sessionId,
          cardId: cards.last.id,
          mode: StudyMode.match,
          action: StudyAction.forgotten,
          now: StudyHarness.now,
        );

        // What the board reads back to decide which slots are empty. The one
        // answered wrongly must not be in it, or the pair the user still has to
        // find disappears when the screen next refreshes.
        final turn = await harness.repository.nextTurn(sessionId);
        expect(turn!.progress.completedCardIds, <String>[cards.first.id]);
      },
    );
  });

  group('the counter a turn carries', () {
    // **The one place this is checkable.** Every widget above is handed a
    // `StudyStageProgressModel` built by the test, so a counting query that read
    // the wrong round — or the whole stage — would leave all of them green and
    // put a bar on screen that walks backwards as failed cards enrol into the
    // next round (BR-116).
    test('counts the round being served, not the stage', () async {
      final sessionId = await harness.openReview(
        cardCount: 3,
        mode: StudyMode.match,
      );

      final first = await harness.repository.nextTurn(sessionId);
      expect(first!.progress.done, 0);
      expect(first.progress.total, 3);

      // One right and one wrong. The wrong one also enrols a round-2 row, which
      // is exactly what a stage-wide count would fold into the total.
      await harness.repository.submitAnswer(
        sessionId: sessionId,
        cardId: first.cardId,
        mode: StudyMode.match,
        action: StudyAction.remembered,
        now: StudyHarness.now,
      );

      final second = await harness.repository.nextTurn(sessionId);
      await harness.repository.submitAnswer(
        sessionId: sessionId,
        cardId: second!.cardId,
        mode: StudyMode.match,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
      );

      // **One, not two: only the correct pair is done** (BR-118). `match` lays
      // the whole round out at once, so a card answered wrongly is still on
      // screen and still has to be paired — its row stays `pending`, and the
      // counter says how many pairs have left the board rather than how many
      // taps were taken.
      final third = await harness.repository.nextTurn(sessionId);
      expect(third!.progress.done, 1);
      expect(third.progress.total, 3, reason: 'round 2 is a separate total');
    });

    test('and starts over when the next round begins', () async {
      final sessionId = await harness.openReview(
        cardCount: 2,
        mode: StudyMode.match,
      );

      // Both cards by id, because `match` serves the board rather than one
      // card: after this the queue's head does not move on a wrong answer, so
      // reading `nextTurn` twice would answer the same pair twice.
      final cardIds = <String>[
        for (final card in await harness.repository.sessionCards(sessionId))
          card.id,
      ];

      Future<void> answerAll(StudyAction action) async {
        for (final cardId in cardIds) {
          await harness.repository.submitAnswer(
            sessionId: sessionId,
            cardId: cardId,
            mode: StudyMode.match,
            action: action,
            now: StudyHarness.now,
          );
        }
      }

      await answerAll(StudyAction.forgotten);

      // **A wrong pair does not finish the round, and that is the point**
      // (BR-118). Both rows are still `pending`, so the board still holds both
      // pairs and round 1 is still what the session is serving. The old effect
      // marked them `completed` and the board they were on emptied under the
      // user.
      final stillRoundOne = await harness.repository.nextTurn(sessionId);
      expect(stillRoundOne!.item.round, 1);
      expect(stillRoundOne.progress.done, 0);

      await answerAll(StudyAction.remembered);

      // Paired at last, so round 1 closes — and both are in round 2 anyway,
      // because failing once put them there (BR-116).
      final roundTwo = await harness.repository.nextTurn(sessionId);
      expect(roundTwo!.item.round, 2);
      expect(roundTwo.progress.done, 0);
      expect(roundTwo.progress.total, 2);
    });
  });
}
