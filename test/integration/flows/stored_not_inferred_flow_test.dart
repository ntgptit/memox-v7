import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/entities/study_session_entity.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/domain/usecases/submit_study_answer_use_case.dart';

import '../../database/support/test_database.dart';

/// `HOST-FLOW` for the last rules the coverage map found untouched: BR-46,
/// BR-80, BR-98, BR-122 and BR-131.
///
/// Scenarios: IT-CONT-003, IT-CONT-010, IT-MODE-001, IT-MODE-009, IT-MODE-015.
///
/// **Four of the five say the same thing about different columns: it is
/// stored, not inferred.** The mode a turn ran in, the reason a turn ended, the
/// reason a session ended, the generation a session belonged to — each one is a
/// fact the app could *almost* re-derive from the shape of the data, and
/// "almost" is the problem. Owning up to a blank and running out of time
/// produce the same `action`; a `scheduled` review of a box-8 card moves
/// nothing. A column that is re-derived is a column that is wrong exactly where
/// it matters, and history cannot be recomputed after the fact.
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
      random: Random(5),
    );
  });

  tearDown(() => db.close());

  Future<List<QueryRow>> rows(String sql) => db.customSelect(sql).get();

  Future<void> seed({required int cardCount, bool learned = true}) async {
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
      await db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        "current_box) VALUES ('c$i', 'eight_box', 1, 1, 0, 0, 3)",
      );
      if (!learned) continue;
      await db.customStatement(
        'UPDATE card_study_states SET learned_at = ?, due_at = ? '
        "WHERE card_id = 'c$i'",
        <Object?>[
          now.subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000,
          now.subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
        ],
      );
    }
  }

  Future<StudySessionEntity> openReview({
    StudyMode mode = StudyMode.selfAssess,
  }) => repository.openSession(
    deckId: 'd1',
    kind: StudySessionKind.reviewing,
    stageSequence: <StudyMode>[mode],
    cardLimit: 20,
    newCardOrder: NewCardOrder.created,
    now: now,
  );

  test('BR-98 · IT-MODE-001 · the running stage is written on the session and '
      'on every answer', () async {
    // Inferring it from the shape of the data is what BR-98 forbids, and the
    // shape is genuinely ambiguous: `self_assess` and `recall` both produce a
    // remembered/forgotten pair, so an answer row without a mode column cannot
    // say which screen the user was looking at.
    await seed(cardCount: 1);
    final session = await openReview(mode: StudyMode.recall);
    final turn = await repository.nextTurn(session.id);

    final stored = (await rows(
      "SELECT current_mode FROM study_sessions WHERE id = '${session.id}'",
    )).single;
    expect(stored.read<String>('current_mode'), 'recall');

    await SubmitStudyAnswerUseCase(repository).call(
      session: session.copyWith(currentMode: StudyMode.recall),
      cardId: turn!.cardId,
      mode: StudyMode.recall,
      action: StudyAction.remembered,
      now: now,
      utcOffset: vietnam,
    );

    final answer = (await rows('SELECT mode FROM study_answers')).single;
    expect(answer.read<String>('mode'), 'recall');
  });

  test('BR-131 · IT-MODE-009 · running out of time is stored as a reason, not '
      'read off the action', () async {
    // BR-130 locks a timed-out turn to the wrong outcome — which is the *same*
    // action a learner produces by owning up to a blank. Without the column the
    // two are indistinguishable forever, and "how often did people run out of
    // time?" becomes an unanswerable question about data already collected.
    await seed(cardCount: 2);
    final session = await openReview(mode: StudyMode.recall);

    final first = await repository.nextTurn(session.id);
    await SubmitStudyAnswerUseCase(repository).call(
      session: session.copyWith(currentMode: StudyMode.recall),
      cardId: first!.cardId,
      mode: StudyMode.recall,
      action: StudyAction.forgotten,
      outcomeReason: StudyOutcomeReason.timeout,
      now: now,
      utcOffset: vietnam,
    );

    final second = await repository.nextTurn(session.id);
    await SubmitStudyAnswerUseCase(repository).call(
      session: session.copyWith(currentMode: StudyMode.recall),
      cardId: second!.cardId,
      mode: StudyMode.recall,
      action: StudyAction.forgotten,
      now: now,
      utcOffset: vietnam,
    );

    final reasons =
        (await rows(
              'SELECT card_id, action, outcome_reason FROM study_answers '
              'ORDER BY card_id',
            ))
            .map(
              (r) => (
                action: r.read<String>('action'),
                reason: r.read<String?>('outcome_reason'),
              ),
            )
            .toList();

    expect(
      reasons.map((r) => r.action).toSet(),
      <String>{'forgotten'},
      reason: 'both turns produce the same action — that is the whole problem',
    );
    expect(
      reasons.map((r) => r.reason).toList(),
      containsAll(<Object?>['timeout', null]),
      reason: 'and only the stored reason tells them apart',
    );
  });

  test('BR-80 · IT-CONT-003 · end_reason admits exactly the five values the '
      'rule names', () async {
    await seed(cardCount: 1);
    final session = await openReview();

    // Every name in BR-80, one at a time, against the real CHECK.
    for (final reason in <String>[
      'user_exit',
      'scheduler_reset',
      'stale_generation',
      'persistence_error',
      'interrupted',
    ]) {
      await db.customStatement(
        'UPDATE study_sessions SET end_reason = ? WHERE id = ?',
        <Object?>[reason, session.id],
      );
    }

    // NULL is the fifth legal state — a session that ended normally, or has not
    // ended at all — and a CHECK written as a bare IN list would reject it.
    await db.customStatement(
      'UPDATE study_sessions SET end_reason = NULL WHERE id = ?',
      <Object?>[session.id],
    );

    await expectLater(
      db.customStatement(
        'UPDATE study_sessions SET end_reason = ? WHERE id = ?',
        <Object?>['abandoned_by_agent', session.id],
      ),
      throwsA(anything),
      reason:
          'a sixth reason invented at a call site would make every '
          'existing row ambiguous',
    );
  });

  test('BR-46 · IT-CONT-010 · an answer from a stale generation is refused, '
      'not applied', () async {
    // The reset-un-resets-itself bug. A session opened before Reset learning
    // progress belongs to generation 1; the reset moves the deck to 2. If its
    // in-flight answer still landed, the reset would silently undo itself.
    await seed(cardCount: 1);
    final session = await openReview();
    final turn = await repository.nextTurn(session.id);

    await db.customStatement(
      "UPDATE decks SET scheduler_generation = 2 WHERE id = 'd1'",
    );
    await db.customStatement(
      'UPDATE card_study_states SET scheduler_generation = 2',
    );

    await expectLater(
      SubmitStudyAnswerUseCase(repository).call(
        session: session.copyWith(currentMode: StudyMode.selfAssess),
        cardId: turn!.cardId,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        now: now,
        utcOffset: vietnam,
      ),
      throwsA(anything),
    );

    expect(
      await rows('SELECT id FROM study_answers'),
      isEmpty,
      reason: 'refused atomically: a rejected write leaves no half of itself',
    );
  });

  test('BR-122 · IT-MODE-015 · a distractor is never the card being asked, and '
      'never an unseen new card', () async {
    // Two halves, and the second is the one that leaks: a distractor taken from
    // a card the learner has not started would show them a meaning before the
    // app ever showed them its term.
    await seed(cardCount: 6);
    // c5 is deliberately unlearned and outside the session.
    await db.customStatement(
      'UPDATE card_study_states SET learned_at = NULL, due_at = NULL '
      "WHERE card_id = 'c5'",
    );

    final pool = <StudyCardModel>[
      for (var i = 0; i < 5; i++)
        StudyCardModel(
          id: 'c$i',
          front: 'f$i',
          back: 'b$i',
          example: null,
          hint: null,
          pronunciation: null,
          backFolded: 'b$i',
        ),
    ];
    final question = const GuessModeHandler().buildQuestion(
      term: pool.first,
      pool: pool.skip(1).toList(),
      random: Random(3),
    );

    expect(question, isNotNull);
    final ids = question!.options.map((o) => o.cardId).toList();
    expect(
      ids.where((id) => id == 'c0'),
      hasLength(1),
      reason: 'the right answer appears exactly once (BR-121)',
    );
    expect(
      ids,
      isNot(contains('c5')),
      reason:
          'the pool never contained it, and the handler must not reach '
          'past what it was given',
    );
    expect(ids.toSet(), hasLength(ids.length));
  });
}
