import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';

import 'support/study_harness.dart';

/// The seconds a `recall` turn had left, written down and read back (BR-133).
///
/// **Both halves in one file, because either alone proves nothing.** A write
/// nobody reads is a column that fills up; a read of something never written is
/// a widget that always starts at twenty seconds. Until now the app had exactly
/// the second of those: `RecallTimerSectionWidget` took `initialRemaining` from
/// the queue row, and no caller in `lib/` ever put a value there.
void main() {
  late StudyHarness harness;

  setUp(() => harness = StudyHarness());
  tearDown(() => harness.close());

  test('a suspended turn keeps its seconds for the next read', () async {
    final sessionId = await harness.openReview(
      cardCount: 3,
      mode: StudyMode.recall,
    );

    final before = await harness.repository.nextTurn(sessionId);
    expect(before!.item.remainingMs, isNull, reason: 'a fresh turn has none');

    await harness.repository.saveTurnProgress(
      sessionId: sessionId,
      mode: StudyMode.recall,
      cardId: before.cardId,
      remainingMs: 14000,
    );

    final after = await harness.repository.nextTurn(sessionId);
    expect(after!.cardId, before.cardId);
    expect(after.item.remainingMs, 14000);
  });

  test(
    'and an answered turn takes none, so Resume cannot serve it again',
    () async {
      // The lowest pending round is decided by whichever cards are left, so a
      // card answered a moment ago still resolves to *a* round. Writing progress
      // against its completed row would make Resume hand back a card the user has
      // already answered.
      final sessionId = await harness.openReview(
        cardCount: 3,
        mode: StudyMode.recall,
      );

      final turn = await harness.repository.nextTurn(sessionId);
      await harness.repository.submitAnswer(
        sessionId: sessionId,
        cardId: turn!.cardId,
        mode: StudyMode.recall,
        action: StudyAction.remembered,
        now: StudyHarness.now,
      );

      await harness.repository.saveTurnProgress(
        sessionId: sessionId,
        mode: StudyMode.recall,
        cardId: turn.cardId,
        remainingMs: 9000,
      );

      final rows = await harness.rows(
        'SELECT remaining_ms FROM study_queue_items '
        "WHERE session_id = '$sessionId' AND card_id = '${turn.cardId}' "
        "AND mode = 'recall' AND round = 1",
      );
      expect(rows.single.read<int?>('remaining_ms'), isNull);
    },
  );

  test('a later round of the same card starts the full limit again', () async {
    // BR-133's second sentence. Round 2 is a different turn, and its row is a
    // different row — the seconds written against round 1 stay there.
    final sessionId = await harness.openReview(
      cardCount: 3,
      mode: StudyMode.recall,
    );

    final turn = await harness.repository.nextTurn(sessionId);
    await harness.repository.saveTurnProgress(
      sessionId: sessionId,
      mode: StudyMode.recall,
      cardId: turn!.cardId,
      remainingMs: 14000,
    );
    await harness.repository.submitAnswer(
      sessionId: sessionId,
      cardId: turn.cardId,
      mode: StudyMode.recall,
      action: StudyAction.forgotten,
      now: StudyHarness.now,
    );

    final rows = await harness.rows(
      'SELECT remaining_ms FROM study_queue_items '
      "WHERE session_id = '$sessionId' AND card_id = '${turn.cardId}' "
      "AND mode = 'recall' AND round = 2",
    );
    expect(rows.single.read<int?>('remaining_ms'), isNull);
  });
}
