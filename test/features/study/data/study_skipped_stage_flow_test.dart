import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/usecases/advance_study_stage_use_case.dart';
import 'package:memox/features/study/domain/usecases/start_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/submit_study_answer_use_case.dart';

import '../../../database/support/test_database.dart';

/// Stages a session-s card set cannot support, against a real database (BR-99).
///
/// **Its own file rather than another group in `study_flow_test.dart`.** That
/// file is one session running to completion with everything available; this one
/// is about what the session does when half its stages cannot run. Splitting at
/// the 400-line guard prompted it, but the seam was already there.
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

  group('stages that cannot run on this card set (BR-99)', () {
    test(
      'a one-card session skips match and guess and still finishes',
      () async {
        // The case that used to stop the session dead. `match` needs two pairs
        // and `guess` needs five distinct meanings; both were laid out anyway,
        // rendered nothing, and left the user on a blank screen.
        await seed(cardCount: 1, withExample: const <String>{'c0'});

        final session = await StartStudySessionUseCase(repository).call(
          deckId: 'd1',
          kind: StudySessionKind.learning,
          now: now,
          utcOffset: vietnam,
        );

        final laidOut = await rows(
          'SELECT DISTINCT mode AS m FROM study_queue_items ORDER BY mode',
        );
        expect(laidOut.map((r) => r.read<String>('m')), <String>[
          'browse',
          'fill',
          'recall',
        ]);

        await playThrough(session.session.id);

        final learned = await rows(
          'SELECT card_id FROM card_study_states WHERE learned_at IS NOT NULL',
        );
        expect(learned, hasLength(1));
      },
    );

    test('a skipped stage writes no answer row for it', () async {
      // "Skipped" and "answered" have to stay distinguishable in history: a
      // stage nobody saw must leave no trace of having been played.
      await seed(cardCount: 1, withExample: const <String>{'c0'});

      final session = await StartStudySessionUseCase(repository).call(
        deckId: 'd1',
        kind: StudySessionKind.learning,
        now: now,
        utcOffset: vietnam,
      );
      await playThrough(session.session.id);

      final modes = await rows('SELECT DISTINCT mode AS m FROM study_answers');
      expect(modes.map((r) => r.read<String>('m')), isNot(contains('match')));
      expect(modes.map((r) => r.read<String>('m')), isNot(contains('guess')));
    });
  });
}
