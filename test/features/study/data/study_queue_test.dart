import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';

import 'support/study_harness.dart';

/// The queue engine: the comeback gap of BR-26, and the rounds of BR-115.
///
/// This is where every Study rule that needs the data *at the moment of writing*
/// actually runs — which is why it is driven through a real database rather than
/// asserted against a fake. What a single turn writes is in
/// `study_answer_test.dart`.
void main() {
  late StudyHarness h;

  setUp(() => h = StudyHarness());
  tearDown(() => h.close());

  group('BR-26 · the comeback gap in self_assess', () {
    test('a forgotten card waits behind three others', () async {
      final sessionId = await h.openReview(cardCount: 5);
      final first = (await h.repository.nextTurn(sessionId))!;

      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: first.cardId,
        mode: StudyMode.selfAssess,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
      );

      // Cursor is 1 StudyHarness.now, so the card may not come back before cursor 4.
      final row = (await h.rows(
        "SELECT available_at, status FROM study_queue_items "
        "WHERE session_id = '$sessionId' AND card_id = '${first.cardId}'",
      )).single;

      expect(row.read<int>('available_at'), 4);
      expect(row.read<String>('status'), 'pending');

      final second = await h.repository.nextTurn(sessionId);
      expect(second!.cardId, isNot(first.cardId));
    });

    test('with fewer than three others it still comes back, at the end', () async {
      // The second half of BR-26, and the branch a naive implementation drops:
      // the gap cannot be honoured, so the card is simply last.
      final sessionId = await h.openReview(cardCount: 2);
      final first = (await h.repository.nextTurn(sessionId))!;

      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: first.cardId,
        mode: StudyMode.selfAssess,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
      );
      final second = (await h.repository.nextTurn(sessionId))!;
      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: second.cardId,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        now: StudyHarness.now,
      );

      // Nothing is servable yet — the forgotten card is still waiting — but the
      // stage is not finished either. Conflating the two ends the session here.
      expect(await h.repository.nextTurn(sessionId), isNull);
      expect(await h.repository.isStageExhausted(sessionId), isFalse);
    });

    test(
      'three relearning turns push the card out and flag it (BR-104)',
      () async {
        final sessionId = await h.openReview(cardCount: 4);
        final card = (await h.repository.nextTurn(sessionId))!.cardId;

        for (var turn = 0; turn < 3; turn++) {
          await h.repository.submitAnswer(
            sessionId: sessionId,
            cardId: card,
            mode: StudyMode.selfAssess,
            action: StudyAction.forgotten,
            now: StudyHarness.now,
          );
        }

        final queue = (await h.rows(
          "SELECT status FROM study_queue_items "
          "WHERE session_id = '$sessionId' AND card_id = '$card'",
        )).single;
        final flagged = (await h.rows(
          "SELECT is_flagged FROM cards WHERE id = '$card'",
        )).single;

        expect(queue.read<String>('status'), 'completed');
        // The system may turn the flag on; only the user turns it off (BR-92).
        expect(flagged.read<int>('is_flagged'), 1);
      },
    );
  });

  group('BR-115 / BR-116 · rounds', () {
    test('a wrong answer enrols the card in the next round', () async {
      final sessionId = await h.openReview(cardCount: 4, mode: StudyMode.match);
      final card = (await h.repository.nextTurn(sessionId))!.cardId;

      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: card,
        mode: StudyMode.match,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
      );

      final round2 = await h.rows(
        "SELECT card_id FROM study_queue_items "
        "WHERE session_id = '$sessionId' AND round = 2",
      );

      expect(round2.map((r) => r.read<String>('card_id')), <String>[card]);
    });

    test(
      'answering correctly afterwards does not undo the failure (BR-116)',
      () async {
        // The case the rule is written for, and the one an implementation that
        // computed the failed set at the end of the round would get wrong: in
        // `match` a card can be re-attempted until it clears the board, and
        // clearing it is not the same as having known it.
        final sessionId = await h.openReview(
          cardCount: 4,
          mode: StudyMode.match,
        );
        final card = (await h.repository.nextTurn(sessionId))!.cardId;

        await h.repository.submitAnswer(
          sessionId: sessionId,
          cardId: card,
          mode: StudyMode.match,
          action: StudyAction.forgotten,
          now: StudyHarness.now,
        );
        await h.repository.submitAnswer(
          sessionId: sessionId,
          cardId: card,
          mode: StudyMode.match,
          action: StudyAction.remembered,
          now: StudyHarness.now,
        );

        final round2 = await h.rows(
          "SELECT card_id FROM study_queue_items "
          "WHERE session_id = '$sessionId' AND round = 2",
        );

        expect(round2, hasLength(1));
      },
    );

    test('failing twice in one round does not enrol the card twice', () async {
      final sessionId = await h.openReview(cardCount: 4, mode: StudyMode.match);
      final card = (await h.repository.nextTurn(sessionId))!.cardId;

      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: card,
        mode: StudyMode.match,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
      );
      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: card,
        mode: StudyMode.match,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
      );

      final round2 = await h.rows(
        "SELECT card_id FROM study_queue_items "
        "WHERE session_id = '$sessionId' AND round = 2",
      );

      expect(round2, hasLength(1));
    });

    test('a clean round leaves no next round to build (BR-119)', () async {
      final sessionId = await h.openReview(cardCount: 4, mode: StudyMode.match);

      for (var i = 0; i < 4; i++) {
        final item = (await h.repository.nextTurn(sessionId))!;
        await h.repository.submitAnswer(
          sessionId: sessionId,
          cardId: item.cardId,
          mode: StudyMode.match,
          action: StudyAction.remembered,
          now: StudyHarness.now,
        );
      }

      expect(await h.repository.buildNextRound(sessionId), isFalse);
      expect(await h.repository.isStageExhausted(sessionId), isTrue);
    });
  });
}
