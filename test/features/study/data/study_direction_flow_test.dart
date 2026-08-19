import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';

import 'support/study_harness.dart';

/// What the direction has to be true of once it is in the tables (BR-205,
/// BR-206).
///
/// The other half — that nothing outside BR-203 can reach any of it, and that
/// no refusal leaves a fragment behind — is in `study_direction_guard_test.dart`,
/// split when the two together crossed the guard's 400 lines.
///
/// **Driven through a real database, because every claim here is about rows.**
/// That a Mixed assignment survives BR-26's comeback and a process restart is a
/// property of a column, not of an object graph — a fake would only prove the
/// code calls the methods it was written to call.
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

  group('a fixed direction', () {
    test('lands on the session and on every queue row', () async {
      final sessionId = await h.openReview(
        cardCount: 4,
        schedulerType: 'sm2',
        direction: StudySessionDirection.meaningToKorean,
      );

      expect(await sessionDirection(sessionId), 'meaning_to_korean');
      expect(
        await queueDirections(sessionId),
        List<String>.filled(4, 'meaning_to_korean'),
      );
    });

    test('reaches the turn the screen renders from', () async {
      final sessionId = await h.openReview(
        cardCount: 2,
        schedulerType: 'sm2',
        direction: StudySessionDirection.meaningToKorean,
      );

      final turn = (await h.repository.nextTurn(sessionId))!;

      expect(turn.item.direction, StudyRecallDirection.meaningToKorean);
    });
  });

  group('mixed (BR-205)', () {
    test('splits the queue to within one card', () async {
      final sessionId = await h.openReview(
        cardCount: 9,
        schedulerType: 'sm2',
        direction: StudySessionDirection.mixed,
      );

      final directions = await queueDirections(sessionId);
      final korean = directions
          .where((value) => value == 'korean_to_meaning')
          .length;
      final meaning = directions
          .where((value) => value == 'meaning_to_korean')
          .length;

      expect(korean + meaning, 9);
      expect(korean - meaning, inInclusiveRange(-1, 1));
    });

    test('the session keeps `mixed`, and no row does', () async {
      // A turn is asked one way or the other; only the *choice* is mixed. A row
      // carrying it would be a card the screen could not draw.
      final sessionId = await h.openReview(
        cardCount: 6,
        schedulerType: 'sm2',
        direction: StudySessionDirection.mixed,
      );

      expect(await sessionDirection(sessionId), 'mixed');
      expect(await queueDirections(sessionId), isNot(contains('mixed')));
    });

    test('a forgotten card comes back asking the same way (BR-26)', () async {
      // `self_assess` retries in the row it already has, so the direction is
      // carried by construction — which is exactly the property that would break
      // silently if it were ever re-drawn at render time.
      final sessionId = await h.openReview(
        cardCount: 5,
        schedulerType: 'sm2',
        direction: StudySessionDirection.mixed,
      );

      final first = (await h.repository.nextTurn(sessionId))!;
      final before = first.item.direction;

      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: first.cardId,
        mode: StudyMode.selfAssess,
        action: StudyAction.again,
        now: StudyHarness.now,
      );

      // Three cards later, BR-26 lets it back.
      for (var index = 0; index < 3; index++) {
        await answer(sessionId, StudyAction.good);
      }

      final again = (await h.repository.nextTurn(sessionId))!;

      expect(again.cardId, first.cardId);
      expect(again.item.direction, before);
    });

    test('a restart reads the same hand back', () async {
      // The process is gone and the generator with it. A seeded deal would come
      // back different here — a column does not.
      final sessionId = await h.openReview(
        cardCount: 8,
        schedulerType: 'sm2',
        direction: StudySessionDirection.mixed,
      );
      final before = await queueDirections(sessionId);

      // A second repository over the same database, with a *different* seed:
      // the deal must owe nothing to whichever generator happens to be alive.
      final restarted = StudyRepositoryImpl(
        StudyDao(h.db),
        idGenerator: () => 'restarted',
        random: Random(999),
      );
      final turn = await restarted.nextTurn(sessionId);

      expect(await queueDirections(sessionId), before);
      expect(turn!.item.direction, isNotNull);
    });
  });

  group('the history row (BR-206)', () {
    test('copies the direction of the row it was answered on', () async {
      final sessionId = await h.openReview(
        cardCount: 3,
        schedulerType: 'sm2',
        direction: StudySessionDirection.meaningToKorean,
      );

      await answer(sessionId, StudyAction.good);

      expect(await answerDirections(sessionId), <String>['meaning_to_korean']);
    });

    test('a mixed session writes each turn its own', () async {
      final sessionId = await h.openReview(
        cardCount: 4,
        schedulerType: 'sm2',
        direction: StudySessionDirection.mixed,
      );

      final expected = <String, String?>{};
      for (var index = 0; index < 4; index++) {
        final turn = (await h.repository.nextTurn(sessionId))!;
        expected[turn.cardId] = turn.item.direction?.dbValue;
        await h.repository.submitAnswer(
          sessionId: sessionId,
          cardId: turn.cardId,
          mode: StudyMode.selfAssess,
          action: StudyAction.good,
          now: StudyHarness.now,
        );
      }

      final rows = await h.rows(
        'SELECT card_id, direction FROM study_answers '
        "WHERE session_id = '$sessionId'",
      );

      expect(rows, hasLength(4));
      for (final row in rows) {
        expect(
          row.read<String?>('direction'),
          expected[row.read<String>('card_id')],
        );
      }
    });
  });
}
