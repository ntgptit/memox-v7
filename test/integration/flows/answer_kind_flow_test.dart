import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/usecases/submit_study_answer_use_case.dart';

import '../../database/support/test_database.dart';

/// `HOST-FLOW` for **what a turn writes down and what it is called** — six
/// rules the coverage map found no host test mentioning: BR-21, BR-27, BR-28,
/// BR-75, BR-140 and BR-143.
///
/// Scenarios: IT-REVIEW-005, IT-LEARN-005, IT-LEARN-006, IT-LEARN-009,
/// IT-LEARN-010 and IT-STUDY-006.
///
/// **`kind` is stored, never inferred, and this is the file that holds that
/// line.** Deriving it later by diffing the schedule before and after gets a
/// `scheduled` review of a box-8 card wrong — the box does not move, so the
/// diff says nothing happened. History written with the wrong label cannot be
/// recomputed, which is why the column exists and why it is worth a test that
/// reads the row back out of SQLite rather than trusting the call that wrote
/// it.
void main() {
  final now = DateTime.utc(2026, 8, 7, 2);
  const vietnam = Duration(hours: 7);

  late AppDatabase db;
  late StudyRepositoryImpl repository;
  var idCounter = 0;

  setUp(() {
    db = openTestDatabase();
    idCounter = 0;
    repository = StudyRepositoryImpl(
      StudyDao(db),
      idGenerator: () => 'id-${idCounter++}',
      // Seeded: the shuffle is real (BR-117) and the same every run.
      random: Random(11),
    );
  });

  tearDown(() => db.close());

  Future<List<QueryRow>> rows(String sql) => db.customSelect(sql).get();

  Future<void> seed({required int cardCount, bool learned = false}) async {
    await db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('d1', 'Korean', 'd1', 'card', 'eight_box', 1, 1, 0, 0)",
    );
    for (var i = 0; i < cardCount; i++) {
      await db.customStatement(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, example, created_at, updated_at) '
        "VALUES ('c$i', 'd1', 'f$i', 'b$i', 'f$i', 'b$i', 'ex$i', $i, $i)",
      );
      final schedule = learned
          ? ', learned_at = ${_secs(now.subtract(const Duration(days: 30)))}'
                ', due_at = ${_secs(now.subtract(const Duration(days: 1)))}'
          : '';
      await db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        "current_box) VALUES ('c$i', 'eight_box', 1, 1, 0, 0, 3)",
      );
      if (schedule.isEmpty) continue;
      await db.customStatement(
        'UPDATE card_study_states SET '
        '${schedule.substring(2)} '
        "WHERE card_id = 'c$i'",
      );
    }
  }

  /// Opens a session of [kind] running exactly [mode], and answers every card
  /// of the first round with [action].
  Future<String> answerWholeRound({
    required StudySessionKind kind,
    required StudyMode mode,
    required StudyAction action,
    int cardCount = 2,
  }) async {
    await seed(
      cardCount: cardCount,
      learned: kind == StudySessionKind.reviewing,
    );
    final session = await repository.openSession(
      deckId: 'd1',
      kind: kind,
      stageSequence: <StudyMode>[mode],
      cardLimit: 20,
      newCardOrder: NewCardOrder.created,
      now: now,
    );

    for (var i = 0; i < cardCount; i++) {
      final turn = await repository.nextTurn(session.id);
      if (turn == null) break;
      await SubmitStudyAnswerUseCase(repository).call(
        session: session.copyWith(currentMode: mode),
        cardId: turn.cardId,
        mode: mode,
        action: action,
        now: now,
        utcOffset: vietnam,
      );
    }

    return session.id;
  }

  Future<List<String>> kindsWritten() async {
    final result = await rows(
      'SELECT kind FROM study_answers ORDER BY answered_at, card_id',
    );

    return result.map((r) => r.read<String>('kind')).toList();
  }

  group('BR-75 · BR-143 · the label a turn is filed under', () {
    test('IT-LEARN-010 · a learning session writes `learning`, never '
        '`scheduled`', () async {
      await answerWholeRound(
        kind: StudySessionKind.learning,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
      );

      final kinds = await kindsWritten();
      expect(kinds, isNotEmpty);
      expect(kinds, everyElement('learning'));
      expect(
        kinds,
        isNot(contains('scheduled')),
        reason:
            'BR-143: `scheduled` belongs to a reviewing session and cannot '
            'appear here — a learning turn records history without touching '
            'the long-term schedule',
      );
    });

    test('IT-REVIEW-005 · a reviewing session writes `scheduled`, never '
        '`learning`', () async {
      await answerWholeRound(
        kind: StudySessionKind.reviewing,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
      );

      final kinds = await kindsWritten();
      expect(kinds, isNotEmpty);
      expect(kinds.first, 'scheduled');
      expect(
        kinds,
        isNot(contains('learning')),
        reason: 'BR-143 forbids `learning` in a reviewing session outright',
      );
    });

    test('the column admits exactly the three values BR-75 names', () async {
      // A CHECK constraint is the only thing that stops a fourth label being
      // invented by a future caller, and a constraint nobody exercises is a
      // constraint nobody knows is missing.
      await answerWholeRound(
        kind: StudySessionKind.reviewing,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        cardCount: 1,
      );

      await expectLater(
        db.customStatement(
          "UPDATE study_answers SET kind = 'graduated' WHERE 1",
        ),
        throwsA(anything),
        reason: 'BR-75 fixes the vocabulary at learning, scheduled, relearning',
      );
    });
  });

  test('BR-27 · IT-LEARN-010 · a learning turn leaves the long-term schedule '
      'untouched', () async {
    // The schedule is written when the *chain finishes*, not by each answer in
    // it (BR-144). A learning turn that moved `due_at` would schedule a card
    // the user has not finished learning — and because the move would look
    // exactly like a review, nothing downstream could tell the two apart.
    await answerWholeRound(
      kind: StudySessionKind.learning,
      mode: StudyMode.selfAssess,
      action: StudyAction.remembered,
    );

    final answers = await rows(
      "SELECT next_due_at FROM study_answers WHERE kind = 'learning'",
    );
    expect(answers, isNotEmpty);
    expect(
      answers.map((r) => r.read<DateTime?>('next_due_at')),
      everyElement(isNull),
      reason:
          'a learning turn has no next due date to record — it is not a '
          'scheduling event',
    );

    // And the card itself is still unscheduled: one stage of the chain is not
    // the chain.
    final states = await rows('SELECT due_at FROM card_study_states');
    expect(
      states.map((r) => r.read<DateTime?>('due_at')),
      everyElement(isNull),
    );
  });

  test('BR-21 · IT-REVIEW-005 · a graded turn records the pair of states it '
      'moved between', () async {
    // Not just the outcome: the before/after pair is the data that makes it
    // possible to judge the algorithm later. An answer row that stored only
    // the action can never answer "did box 3 help?".
    await answerWholeRound(
      kind: StudySessionKind.reviewing,
      mode: StudyMode.selfAssess,
      action: StudyAction.remembered,
      cardCount: 1,
    );

    final answer = (await rows(
      'SELECT card_id, session_id, scheduler_type, scheduler_generation, '
      'kind, action, answered_at, next_due_at, previous_box, next_box '
      'FROM study_answers',
    )).single;

    expect(answer.read<String>('card_id'), 'c0');
    expect(answer.read<String>('scheduler_type'), 'eight_box');
    expect(answer.read<int>('scheduler_generation'), 1);
    expect(answer.read<String>('kind'), 'scheduled');
    expect(answer.read<String>('action'), 'remembered');
    expect(answer.read<DateTime?>('answered_at'), isNotNull);
    expect(
      answer.read<DateTime?>('next_due_at'),
      isNotNull,
      reason: 'a scheduled turn is the one kind that does move the schedule',
    );
    expect(answer.read<int?>('previous_box'), 3);
    expect(
      answer.read<int?>('next_box'),
      4,
      reason: 'remembered moves a box-3 card up one; the pair is what shows it',
    );
  });

  test('BR-28 · a card answered `forgotten` stays in the round, and one '
      'answered `remembered` leaves it', () async {
    await seed(cardCount: 2, learned: true);
    final session = await repository.openSession(
      deckId: 'd1',
      kind: StudySessionKind.reviewing,
      stageSequence: const <StudyMode>[StudyMode.selfAssess],
      cardLimit: 20,
      newCardOrder: NewCardOrder.created,
      now: now,
    );

    final first = await repository.nextTurn(session.id);
    await SubmitStudyAnswerUseCase(repository).call(
      session: session.copyWith(currentMode: StudyMode.selfAssess),
      cardId: first!.cardId,
      mode: StudyMode.selfAssess,
      action: StudyAction.forgotten,
      now: now,
      utcOffset: vietnam,
    );

    final pending = await rows(
      "SELECT card_id FROM study_queue_items WHERE status = 'pending'",
    );
    expect(
      pending.map((r) => r.read<String>('card_id')),
      contains(first.cardId),
      reason:
          'BR-28: only an action other than forgotten/again releases a '
          'card from the queue',
    );
  });
}

int _secs(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;
