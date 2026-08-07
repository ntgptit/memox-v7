import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/failures/study_refusal_failure.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import 'support/study_harness.dart';

/// What one answer writes, and what completing the chain writes instead.
///
/// The two halves of BR-141/BR-144: a turn inside a review session moves the
/// schedule exactly once, and a learning session moves it never — completion is
/// an event of its own.
void main() {
  late StudyHarness h;

  setUp(() => h = StudyHarness());
  tearDown(() => h.close());

  group('what a turn writes', () {
    Future<String> openSelfAssessReview() async {
      final ids = await h.seedDeck(cardCount: 3);
      for (final id in ids) {
        await h.makeDue(id);
      }

      final session = await h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        stageSequence: <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );

      return session.id;
    }

    test('the first turn is scheduled and the next is relearning', () async {
      final sessionId = await openSelfAssessReview();
      final card = (await h.repository.nextItem(sessionId))!.cardId;

      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: card,
        mode: StudyMode.selfAssess,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
        nextDueAt: StudyHarness.now.add(const Duration(days: 1)),
        nextBox: 1,
      );
      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: card,
        mode: StudyMode.selfAssess,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
      );

      final kinds = await h.rows(
        "SELECT kind FROM study_answers WHERE card_id = '$card' "
        'ORDER BY rowid',
      );

      expect(kinds.map((r) => r.read<String>('kind')), <String>[
        'scheduled',
        'relearning',
      ]);
    });

    test('a relearning turn moves the stamp and nothing else (BR-78)', () async {
      final sessionId = await openSelfAssessReview();
      final card = (await h.repository.nextItem(sessionId))!.cardId;
      final due = StudyHarness.now.add(const Duration(days: 4));

      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: card,
        mode: StudyMode.selfAssess,
        action: StudyAction.forgotten,
        now: StudyHarness.now,
        nextDueAt: due,
        nextBox: 3,
      );
      await h.repository.submitAnswer(
        sessionId: sessionId,
        cardId: card,
        mode: StudyMode.selfAssess,
        action: StudyAction.forgotten,
        now: StudyHarness.now.add(const Duration(minutes: 1)),
        // A scheduler would not be consulted for a relearning turn, but passing
        // values it must ignore is the only way to prove it ignores them.
        nextDueAt: StudyHarness.now.add(const Duration(days: 99)),
        nextBox: 8,
      );

      final state = (await h.rows(
        "SELECT due_at, current_box, answer_count FROM card_study_states "
        "WHERE card_id = '$card'",
      )).single;

      expect(state.read<int>('due_at'), due.millisecondsSinceEpoch ~/ 1000);
      expect(state.read<int>('current_box'), 3);
      // Only `scheduled` turns count (BR-20).
      expect(state.read<int>('answer_count'), 1);
    });

    test(
      'a learning session writes no scheduled turn at all (BR-141)',
      () async {
        await h.seedDeck(cardCount: 3);

        final session = await h.repository.openSession(
          deckId: 'd1',
          kind: StudySessionKind.learning,
          stageSequence: <StudyMode>[StudyMode.match],
          cardLimit: 20,
          newCardOrder: NewCardOrder.created,
          now: StudyHarness.now,
        );
        final card = (await h.repository.nextItem(session.id))!.cardId;

        await h.repository.submitAnswer(
          sessionId: session.id,
          cardId: card,
          mode: StudyMode.match,
          action: StudyAction.remembered,
          now: StudyHarness.now,
        );

        final answer = (await h.rows(
          "SELECT kind FROM study_answers WHERE card_id = '$card'",
        )).single;
        final state = (await h.rows(
          "SELECT learned_at, due_at FROM card_study_states "
          "WHERE card_id = '$card'",
        )).single;

        expect(answer.read<String>('kind'), 'learning');
        // The chain changes nothing until the card finishes it (BR-144).
        expect(state.read<int?>('learned_at'), isNull);
        expect(state.read<int?>('due_at'), isNull);
      },
    );

    test(
      'a stale generation invalidates the session and writes nothing',
      () async {
        final sessionId = await openSelfAssessReview();
        final card = (await h.repository.nextItem(sessionId))!.cardId;

        // A Reset, from the session's point of view (BR-40, BR-84).
        await h.db.customStatement(
          "UPDATE decks SET scheduler_generation = 2 WHERE id = 'd1'",
        );

        await expectLater(
          h.repository.submitAnswer(
            sessionId: sessionId,
            cardId: card,
            mode: StudyMode.selfAssess,
            action: StudyAction.remembered,
            now: StudyHarness.now,
          ),
          throwsA(
            isA<ConflictFailure>().having(
              (f) => f.reason,
              'reason',
              StudyRefusalReason.staleGeneration,
            ),
          ),
        );

        final session = (await h.rows(
          "SELECT status, end_reason FROM study_sessions WHERE id = '$sessionId'",
        )).single;

        expect(session.read<String>('status'), 'invalidated');
        expect(session.read<String>('end_reason'), 'stale_generation');
        expect(await h.rows('SELECT id FROM study_answers'), isEmpty);
      },
    );
  });

  group('BR-144 · completing the learning chain', () {
    test('it sets both columns and writes no scheduled turn', () async {
      final ids = await h.seedDeck(cardCount: 1);
      final learned = StudyHarness.now;
      final due = StudyHarness.now.add(const Duration(days: 1));

      await h.repository.completeLearning(
        cardId: ids.single,
        learnedAt: learned,
        dueAt: due,
      );

      final state = (await h.rows(
        'SELECT learned_at, due_at, current_box, answer_count '
        "FROM card_study_states WHERE card_id = '${ids.single}'",
      )).single;

      expect(
        state.read<int>('learned_at'),
        learned.millisecondsSinceEpoch ~/ 1000,
      );
      expect(state.read<int>('due_at'), due.millisecondsSinceEpoch ~/ 1000);
      expect(state.read<int>('current_box'), 1);
      // Completion is an event, not an answer.
      expect(state.read<int>('answer_count'), 0);
      expect(await h.rows('SELECT id FROM study_answers'), isEmpty);
    });

    test('invariants 24 and 28 stay empty afterwards', () async {
      final ids = await h.seedDeck(cardCount: 2);
      await h.repository.completeLearning(
        cardId: ids.first,
        learnedAt: StudyHarness.now,
        dueAt: StudyHarness.now.add(const Duration(days: 1)),
      );

      expect(
        await h.rows(
          'SELECT card_id FROM card_study_states '
          'WHERE learned_at IS NOT NULL AND due_at IS NULL',
        ),
        isEmpty,
      );
      expect(
        await h.rows(
          'SELECT card_id FROM card_study_states '
          'WHERE learned_at IS NULL AND due_at IS NOT NULL',
        ),
        isEmpty,
      );
    });
  });
}
