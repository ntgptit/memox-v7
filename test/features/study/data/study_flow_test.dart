import 'dart:math';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/usecases/advance_study_stage_use_case.dart';
import 'package:memox/features/study/domain/usecases/start_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/submit_study_answer_use_case.dart';

import '../../../database/support/test_database.dart';

/// UC-05 end to end: learn a card, come back for it, and never study ahead.
///
/// **Driven through the use cases against a real SQLite database.** The layer
/// above — screens and routing — is covered by widget tests per mode, and there
/// is no assembled session screen to drive yet, so an on-device test would prove
/// nothing this does not. What it does prove is the part every unit test can
/// miss: that the pieces agree with each other over a whole session.
void main() {
  final now = DateTime.utc(2026, 8, 7, 2); // 09:00 in Hanoi.
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
      random: Random(11),
    );
  });

  tearDown(() => db.close());

  Future<List<QueryRow>> rows(String sql) => db.customSelect(sql).get();

  /// A root deck on `eight_box`, and [cardCount] cards. Only the cards named in
  /// [withExample] carry one.
  Future<void> seed({
    required int cardCount,
    Set<String> withExample = const <String>{},
  }) async {
    await db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('d1', 'Korean', 'd1', 'card', 'eight_box', 1, 1, 0, 0)",
    );

    for (var i = 0; i < cardCount; i++) {
      final id = 'c$i';
      final example = withExample.contains(id) ? "'ex-$id'" : 'NULL';
      await db.customStatement(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, example, created_at, updated_at) '
        "VALUES ('$id', 'd1', 'f$i', 'b$i', 'f$i', 'b$i', $example, $i, $i)",
      );
      await db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        "current_box) VALUES ('$id', 'eight_box', 1, 1, 0, 0, 1)",
      );
    }
  }

  /// Answers every card of every stage correctly, until the session ends.
  Future<void> playThrough(String sessionId) async {
    for (var guard = 0; guard < 200; guard++) {
      final session = await repository.openSessionFor('d1');
      if (session == null) return;

      final mode = await AdvanceStudyStageUseCase(
        repository,
      ).call(session: session, now: now, utcOffset: vietnam);
      if (mode == null) return;

      final turn = await repository.nextTurn(sessionId);
      if (turn == null) return;

      // `browse` grades nothing (BR-111), so it is moved past rather than
      // answered — the database will not even hold `browse` as an answer mode.
      if (mode == StudyMode.browse) {
        await repository.markBrowsed(sessionId: sessionId, cardId: turn.cardId);

        continue;
      }

      await SubmitStudyAnswerUseCase(repository).call(
        session: session.copyWith(currentMode: mode),
        cardId: turn.cardId,
        mode: mode,
        action: StudyAction.remembered,
        now: now,
        utcOffset: vietnam,
      );
    }

    fail('the session never ended');
  }

  group('the learning chain', () {
    test('a card with no example still finishes it (BR-114, BR-144)', () async {
      // **The case an earlier reading of BR-144 would have frozen forever.**
      // `example` is optional and `fill` is the last stage; "reached the last
      // stage in the sequence" would have stranded every card without one —
      // which is most of them.
      await seed(cardCount: 3, withExample: const <String>{'c0'});

      final session = await StartStudySessionUseCase(
        repository,
      ).call(deckId: 'd1', kind: StudySessionKind.learning, now: now);

      // The two cards without an example have no `fill` row to be stuck in.
      final fillCards = await rows(
        "SELECT card_id FROM study_queue_items WHERE mode = 'fill'",
      );
      expect(fillCards.map((r) => r.read<String>('card_id')), <String>['c0']);

      await playThrough(session.id);

      final learned = await rows(
        'SELECT card_id, learned_at, due_at, current_box FROM '
        'card_study_states WHERE learned_at IS NOT NULL ORDER BY card_id',
      );

      expect(learned.map((r) => r.read<String>('card_id')), <String>[
        'c0',
        'c1',
        'c2',
      ]);
      // BR-144: the lowest rung, due at the start of the next study day.
      for (final row in learned) {
        expect(row.read<int>('current_box'), 1);
        expect(
          row.read<int>('due_at'),
          DateTime.utc(2026, 8, 7, 17).millisecondsSinceEpoch ~/ 1000,
        );
      }
    });

    test('the chain writes no scheduled turn at all (BR-141)', () async {
      await seed(cardCount: 2, withExample: const <String>{'c0', 'c1'});

      final session = await StartStudySessionUseCase(
        repository,
      ).call(deckId: 'd1', kind: StudySessionKind.learning, now: now);
      await playThrough(session.id);

      final kinds = await rows('SELECT DISTINCT kind FROM study_answers');

      // Completion is an event, not an answer. A `scheduled` row here would
      // make a card look reviewed before it had ever been reviewed.
      expect(kinds.map((r) => r.read<String>('kind')), <String>['learning']);
      expect(
        (await rows(
          'SELECT status, end_reason FROM study_sessions',
        )).single.read<String>('status'),
        'completed',
      );
    });

    test('invariants 24 and 28 hold after the whole flow', () async {
      await seed(cardCount: 3, withExample: const <String>{'c0'});
      final session = await StartStudySessionUseCase(
        repository,
      ).call(deckId: 'd1', kind: StudySessionKind.learning, now: now);
      await playThrough(session.id);

      expect(
        await rows(
          'SELECT card_id FROM card_study_states '
          'WHERE learned_at IS NOT NULL AND due_at IS NULL',
        ),
        isEmpty,
      );
      expect(
        await rows(
          'SELECT card_id FROM card_study_states '
          'WHERE learned_at IS NULL AND due_at IS NOT NULL',
        ),
        isEmpty,
      );
    });
  });

  group('what happens next', () {
    /// Learns everything, so the deck holds only due-or-not-yet-due cards.
    Future<void> learnEverything() async {
      final session = await StartStudySessionUseCase(
        repository,
      ).call(deckId: 'd1', kind: StudySessionKind.learning, now: now);
      await playThrough(session.id);
    }

    test('a card learned today cannot be reviewed today (BR-145)', () async {
      // Studying ahead is a rule, not a missing feature. The card is due
      // tomorrow, and until then there is no session to open at all.
      await seed(cardCount: 2, withExample: const <String>{'c0', 'c1'});
      await learnEverything();

      await expectLater(
        StartStudySessionUseCase(repository).call(
          deckId: 'd1',
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.match,
          now: now,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('tomorrow it is due, and reviewing moves the schedule', () async {
      await seed(cardCount: 2, withExample: const <String>{'c0', 'c1'});
      await learnEverything();

      final tomorrow = now.add(const Duration(days: 1));
      final session = await StartStudySessionUseCase(repository).call(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        reviewMode: StudyMode.match,
        now: tomorrow,
      );
      final card = (await repository.nextTurn(session.id))!.cardId;

      await SubmitStudyAnswerUseCase(repository).call(
        session: session,
        cardId: card,
        mode: StudyMode.match,
        action: StudyAction.remembered,
        now: tomorrow,
        utcOffset: vietnam,
      );

      final state = (await rows(
        'SELECT current_box, answer_count, due_at FROM card_study_states '
        "WHERE card_id = '$card'",
      )).single;

      // Box 1 remembered goes to box 2, which BR-16 puts two days out.
      expect(state.read<int>('current_box'), 2);
      expect(state.read<int>('answer_count'), 1);
      expect(
        state.read<int>('due_at'),
        DateTime.utc(2026, 8, 9, 17).millisecondsSinceEpoch ~/ 1000,
      );

      final answer = (await rows(
        "SELECT kind, mode FROM study_answers WHERE card_id = '$card' "
        "AND kind = 'scheduled'",
      )).single;
      expect(answer.read<String>('mode'), 'match');
    });

    test('the two card sets never overlap (BR-142, BR-151)', () async {
      await seed(cardCount: 4, withExample: const <String>{'c0'});
      final session = await StartStudySessionUseCase(
        repository,
      ).call(deckId: 'd1', kind: StudySessionKind.learning, now: now);
      await playThrough(session.id);

      final summary = await repository.watchStudyEntry('d1', now: now).first;

      // Everything is learned, and nothing is due yet — which is a real state,
      // not an empty screen waiting to be filled.
      expect(summary.newCount, 0);
      expect(summary.dueCount, 0);

      final tomorrow = await repository
          .watchStudyEntry('d1', now: now.add(const Duration(days: 1)))
          .first;
      expect(tomorrow.newCount, 0);
      expect(tomorrow.dueCount, 4);
      // `fill` still only takes the one card that has an example.
      expect(tomorrow.fillableCount, 1);
    });
  });
}
