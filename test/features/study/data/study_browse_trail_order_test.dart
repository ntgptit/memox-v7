import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';

import 'support/study_harness.dart';

/// The order of the trail `browse` walks backwards (BR-155).
///
/// **This pins a contract; it does not catch the bug that prompted it.** Said
/// plainly because the difference matters: `completedCardsInRound` had no
/// `ORDER BY`, and the test below was written to fail on it. It did not. Rows
/// re-inserted in reverse still came back in `position` order, because the
/// planner reaches for the index on (session_id, mode, round) and that walks in
/// position order.
///
/// So the `ORDER BY` was added anyway, and this test stands for the order rather
/// than against the old query: `browse` walks the list backwards, so "the
/// previous card" is decided entirely by it, and an order that holds only
/// because of the current query plan is one nobody is told about when the plan
/// changes.
void main() {
  late StudyHarness harness;

  setUp(() => harness = StudyHarness());
  tearDown(() => harness.close());

  test('the trail comes back in the order the queue serves, not rowid', () async {
    final sessionId = await harness.openReview(
      cardCount: 3,
      mode: StudyMode.browse,
    );

    final queued = await harness.rows(
      'SELECT card_id, position FROM study_queue_items '
      "WHERE session_id = '$sessionId' AND mode = 'browse' AND round = 1 "
      'ORDER BY position',
    );
    expect(queued, hasLength(3));
    final byPosition = queued
        .map((row) => row.read<String>('card_id'))
        .toList();

    // Rewrite the three rows so that **rowid order is the reverse of position
    // order**, with the last card left pending so there is still a turn to read
    // the trail from. Nothing else about them changes. This is what failed to
    // break the unordered query — kept because it is still the hostile setup,
    // and a future plan change is exactly what it would catch.
    await harness.db.customStatement(
      "DELETE FROM study_queue_items WHERE session_id = '$sessionId'",
    );
    for (final row in queued.reversed) {
      final position = row.read<int>('position');
      final status = position == 2 ? 'pending' : 'completed';
      await harness.db.customStatement(
        'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
        'position, status, available_at, answers_in_session, is_revealed) '
        "VALUES ('$sessionId', 'browse', 1, '${row.read<String>('card_id')}', "
        "$position, '$status', 0, 0, 0)",
      );
    }

    final turn = await harness.repository.nextTurn(sessionId);

    // **Read through the app's own query, not a hand-written one.** The first
    // draft of this test wrote its own `ORDER BY` and so asserted nothing about
    // the app at all.
    expect(turn, isNotNull);
    expect(turn!.cardId, byPosition[2], reason: 'the one still pending');
    expect(
      turn.progress.completedCardIds,
      <String>[byPosition[0], byPosition[1]],
      reason:
          'the rows sit in the database in the opposite order, so an unordered '
          'read hands back the trail backwards and "the previous card" is the '
          'wrong card',
    );
  });

  test('a browsed card joins the trail, in its own position', () async {
    // The path the app actually takes: answer the first card and the trail has
    // exactly it, at the front.
    final sessionId = await harness.openReview(
      cardCount: 3,
      mode: StudyMode.browse,
    );

    final first = await harness.repository.nextTurn(sessionId);
    expect(first!.progress.completedCardIds, isEmpty, reason: 'nothing behind');

    await harness.repository.markBrowsed(
      sessionId: sessionId,
      cardId: first.cardId,
    );

    final second = await harness.repository.nextTurn(sessionId);
    expect(second!.cardId, isNot(first.cardId));
    expect(second.progress.completedCardIds, <String>[first.cardId]);
  });

  test('an answered card of another mode is not on browse-s trail', () async {
    // The trail is read per mode and per round, so a `self_assess` answer on
    // the same card cannot put it behind a `browse` turn.
    // `self_assess` is the harness default, so the mode is left unnamed.
    final sessionId = await harness.openReview(cardCount: 3);

    final turn = await harness.repository.nextTurn(sessionId);
    await harness.repository.submitAnswer(
      sessionId: sessionId,
      cardId: turn!.cardId,
      mode: StudyMode.selfAssess,
      action: StudyAction.remembered,
      now: StudyHarness.now,
    );

    final browseRows = await harness.rows(
      'SELECT card_id FROM study_queue_items '
      "WHERE session_id = '$sessionId' AND mode = 'browse'",
    );
    expect(browseRows, isEmpty);
  });
}
