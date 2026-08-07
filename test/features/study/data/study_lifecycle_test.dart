import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';

import 'support/study_harness.dart';

/// The five ways a session can end, and the one thing true of all of them.
///
/// **Every ending is checked twice**: that the row says what the matrix allows,
/// and that the turns already recorded are still there (BR-86). Losing history
/// on an abnormal ending is the failure mode nobody notices until a user asks
/// why a card they answered is due again.
void main() {
  late StudyHarness h;

  setUp(() => h = StudyHarness());
  tearDown(() => h.close());

  /// Opens a review session and records one turn, so every ending below has
  /// something to lose.
  Future<String> sessionWithOneAnswer() async {
    final sessionId = await h.openReview(cardCount: 3);
    final card = (await h.repository.nextTurn(sessionId))!.cardId;

    await h.repository.submitAnswer(
      sessionId: sessionId,
      cardId: card,
      mode: StudyMode.selfAssess,
      action: StudyAction.remembered,
      now: StudyHarness.now,
      nextDueAt: StudyHarness.now.add(const Duration(days: 2)),
      nextBox: 2,
    );

    return sessionId;
  }

  Future<({String status, String? reason, int? endedAt})> outcomeOf(
    String sessionId,
  ) async {
    final row = (await h.rows(
      'SELECT status, end_reason, ended_at FROM study_sessions '
      "WHERE id = '$sessionId'",
    )).single;

    return (
      status: row.read<String>('status'),
      reason: row.read<String?>('end_reason'),
      endedAt: row.read<int?>('ended_at'),
    );
  }

  /// Invariant 12: no `status` × `end_reason` pair outside the matrix.
  Future<void> expectMatrixIntact() async {
    final offenders = await h.rows('''
SELECT id FROM study_sessions
WHERE (status IN ('in_progress', 'completed') AND end_reason IS NOT NULL)
   OR (status = 'abandoned'
       AND end_reason NOT IN ('user_exit', 'interrupted'))
   OR (status = 'invalidated'
       AND end_reason NOT IN ('scheduler_reset', 'stale_generation'))
   OR (status = 'failed' AND end_reason <> 'persistence_error')
   OR (status NOT IN ('in_progress', 'completed') AND end_reason IS NULL)
''');

    expect(offenders, isEmpty);
  }

  Future<void> expectAnswersKept() async {
    expect(await h.rows('SELECT id FROM study_answers'), hasLength(1));
  }

  group('the five endings', () {
    test(
      'completed carries no reason, and does carry an end (BR-81)',
      () async {
        final sessionId = await sessionWithOneAnswer();

        await h.repository.endSession(
          sessionId: sessionId,
          status: StudySessionStatus.completed,
          reason: null,
          endedAt: StudyHarness.now,
        );

        final outcome = await outcomeOf(sessionId);
        expect(outcome.status, 'completed');
        expect(outcome.reason, isNull);
        expect(outcome.endedAt, isNotNull);
        await expectAnswersKept();
        await expectMatrixIntact();
      },
    );

    test('the user leaving is user_exit (BR-82)', () async {
      final sessionId = await sessionWithOneAnswer();

      await h.repository.endSession(
        sessionId: sessionId,
        status: StudySessionStatus.abandoned,
        reason: StudySessionEndReason.userExit,
        endedAt: StudyHarness.now,
      );

      expect((await outcomeOf(sessionId)).reason, 'user_exit');
      await expectAnswersKept();
      await expectMatrixIntact();
    });

    test('an earlier study day is interrupted, not user_exit (BR-103)', () async {
      // The distinction BR-76 makes for `kind`, applied to endings: the user did
      // not give up, the app was taken away.
      final sessionId = await sessionWithOneAnswer();

      final closed = await h.repository.abandonStaleSessions(
        dayStart: StudyHarness.now.add(const Duration(days: 1)),
      );

      final outcome = await outcomeOf(sessionId);
      expect(closed, 1);
      expect(outcome.status, 'abandoned');
      expect(outcome.reason, 'interrupted');
      await expectAnswersKept();
      await expectMatrixIntact();
    });

    test('a reset closes open sessions as scheduler_reset (BR-83)', () async {
      final sessionId = await sessionWithOneAnswer();

      final closed = await h.repository.invalidateSessionsForRoot(
        rootDeckId: 'd1',
        endedAt: StudyHarness.now,
      );

      final outcome = await outcomeOf(sessionId);
      expect(closed, 1);
      expect(outcome.status, 'invalidated');
      // `scheduler_reset`, not `stale_generation`: the difference is who
      // noticed. This is the reset closing its own sessions.
      expect(outcome.reason, 'scheduler_reset');
      await expectAnswersKept();
      await expectMatrixIntact();
    });

    test(
      'an unusable write ends the session as persistence_error (BR-85)',
      () async {
        final sessionId = await sessionWithOneAnswer();

        await h.repository.endSession(
          sessionId: sessionId,
          status: StudySessionStatus.failed,
          reason: StudySessionEndReason.persistenceError,
          endedAt: StudyHarness.now,
        );

        expect((await outcomeOf(sessionId)).status, 'failed');
        await expectAnswersKept();
        await expectMatrixIntact();
      },
    );

    test('a pair outside the matrix is refused before it is written', () async {
      final sessionId = await sessionWithOneAnswer();

      await expectLater(
        h.repository.endSession(
          sessionId: sessionId,
          status: StudySessionStatus.completed,
          reason: StudySessionEndReason.schedulerReset,
          endedAt: StudyHarness.now,
        ),
        throwsA(isA<Object>()),
      );

      // Still open: a refused ending must not half-close a session.
      expect((await outcomeOf(sessionId)).status, 'in_progress');
      await expectMatrixIntact();
    });
  });

  group('an interrupted turn (BR-133)', () {
    test('what was left of it is stored, and the row stays pending', () async {
      final sessionId = await h.openReview(
        cardCount: 3,
        mode: StudyMode.recall,
      );
      final card = (await h.repository.nextTurn(sessionId))!.cardId;

      await h.repository.saveTurnProgress(
        sessionId: sessionId,
        mode: StudyMode.recall,
        cardId: card,
        remainingMs: 4200,
        isRevealed: true,
      );

      final row = (await h.rows(
        'SELECT remaining_ms, is_revealed, status FROM study_queue_items '
        "WHERE session_id = '$sessionId' AND card_id = '$card'",
      )).single;

      expect(row.read<int>('remaining_ms'), 4200);
      expect(row.read<int>('is_revealed'), 1);
      // Suspended, not finished: Resume has to serve this card again.
      expect(row.read<String>('status'), 'pending');
    });

    test('the next read carries it back', () async {
      final sessionId = await h.openReview(
        cardCount: 3,
        mode: StudyMode.recall,
      );
      final card = (await h.repository.nextTurn(sessionId))!.cardId;

      await h.repository.saveTurnProgress(
        sessionId: sessionId,
        mode: StudyMode.recall,
        cardId: card,
        remainingMs: 4200,
        isRevealed: true,
      );

      final turn = (await h.repository.nextTurn(sessionId))!;

      // Handing back a fresh twenty seconds would give back time the user
      // already spent; hiding the answer again would ask them to un-know it.
      expect(turn.item.remainingMs, 4200);
      expect(turn.item.isRevealed, isTrue);
    });

    test('a turn that has already ended is not resurrected', () async {
      final sessionId = await h.openReview(cardCount: 2);
      final card = (await h.repository.nextTurn(sessionId))!.cardId;

      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: card,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        now: StudyHarness.now,
      );

      await h.repository.saveTurnProgress(
        sessionId: sessionId,
        mode: StudyMode.selfAssess,
        cardId: card,
        remainingMs: 9999,
      );

      final row = (await h.rows(
        'SELECT status, remaining_ms FROM study_queue_items '
        "WHERE session_id = '$sessionId' AND card_id = '$card'",
      )).single;

      // Writing progress for a finished turn would make Resume serve a card the
      // user has already answered.
      expect(row.read<String>('status'), 'completed');
      expect(row.read<int?>('remaining_ms'), isNull);
    });
  });
}
