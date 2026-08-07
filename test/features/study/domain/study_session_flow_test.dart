import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/entities/study_session_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_schedule_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/usecases/advance_study_stage_use_case.dart';
import 'package:memox/features/study/domain/usecases/end_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/resume_study_day_use_case.dart';
import 'package:memox/features/study/domain/usecases/submit_study_answer_use_case.dart';

import 'support/fake_study_repository.dart';

/// What a turn writes, and what happens when a stage runs out.
///
/// The two decisions that need a scheduler, and the one place BR-105's day
/// boundary turns an interval into a moment.
void main() {
  // 09:00 in Hanoi on the 7th.
  final now = DateTime.utc(2026, 8, 7, 2);
  const vietnam = Duration(hours: 7);

  StudySessionEntity sessionOf({
    required StudySessionKind kind,
    StudyMode mode = StudyMode.browse,
  }) => StudySessionEntity(
    id: 'session-1',
    deckId: 'deck-1',
    rootDeckId: 'root',
    schedulerGeneration: 1,
    kind: kind,
    currentMode: mode,
    status: StudySessionStatus.inProgress,
    endReason: null,
    cursor: 0,
    cardLimit: 20,
    startedAt: now,
    endedAt: null,
  );

  group('submitting an answer', () {
    test(
      'a learning turn consults no scheduler and carries no schedule',
      () async {
        // BR-141 and BR-144: the chain moves nothing. Computing an interval and
        // discarding it is how a number nobody wanted ends up stored.
        final repository = FakeStudyRepository();

        await SubmitStudyAnswerUseCase(repository).call(
          session: sessionOf(kind: StudySessionKind.learning),
          cardId: 'card-1',
          mode: StudyMode.match,
          action: StudyAction.remembered,
          now: now,
          utcOffset: vietnam,
        );

        final answer = repository.answers.single;
        expect(answer.nextDueAt, isNull);
        expect(answer.nextBox, isNull);
        expect(answer.nextIntervalDays, isNull);
      },
    );

    test('a review turn carries the schedule the algorithm produced', () async {
      final repository = FakeStudyRepository();

      await SubmitStudyAnswerUseCase(repository).call(
        session: sessionOf(kind: StudySessionKind.reviewing),
        cardId: 'card-1',
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        now: now,
        utcOffset: vietnam,
      );

      // Box 3 remembered goes to 4, which BR-16 puts eight days out.
      expect(repository.answers.single.nextBox, 4);
      expect(
        repository.answers.single.nextDueAt,
        DateTime.utc(2026, 8, 14, 17),
      );
    });

    test('the due moment is local midnight, not now plus N days', () async {
      // BR-105. The naive arithmetic would give 2026-08-08T02:00Z here, which
      // is 09:00 Hanoi — so a card answered in the morning is not due until the
      // morning after, and the hour drifts further every repetition.
      final repository = FakeStudyRepository(
        schedule: const StudyScheduleModel(box: 1),
      );

      await SubmitStudyAnswerUseCase(repository).call(
        session: sessionOf(kind: StudySessionKind.reviewing),
        cardId: 'card-1',
        mode: StudyMode.selfAssess,
        action: StudyAction.forgotten,
        now: now,
        utcOffset: vietnam,
      );

      expect(repository.answers.single.nextDueAt, DateTime.utc(2026, 8, 7, 17));
    });

    test('a box-8 card answered remembered still carries a schedule', () async {
      // The case that makes deriving `kind` wrong: nothing about the box
      // changes, so before-and-after look identical. The turn is still a
      // `scheduled` one, and it still moves the due date 128 days out (BR-76).
      final repository = FakeStudyRepository(
        schedule: const StudyScheduleModel(box: 8),
      );

      await SubmitStudyAnswerUseCase(repository).call(
        session: sessionOf(kind: StudySessionKind.reviewing),
        cardId: 'card-1',
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        now: now,
        utcOffset: vietnam,
      );

      expect(repository.answers.single.nextBox, 8);
      expect(
        repository.answers.single.nextDueAt,
        DateTime.utc(2026, 12, 12, 17),
      );
    });
  });

  group('advancing a stage', () {
    test('a stage with cards left stays put', () async {
      final repository = FakeStudyRepository(stageExhausted: false);

      final mode = await AdvanceStudyStageUseCase(repository).call(
        session: sessionOf(
          kind: StudySessionKind.learning,
          mode: StudyMode.match,
        ),
        now: now,
        utcOffset: vietnam,
      );

      expect(mode, StudyMode.match);
      expect(repository.advancedTo, isEmpty);
      expect(repository.ended, isEmpty);
    });

    test('an exhausted stage moves to the next one in the sequence', () async {
      final repository = FakeStudyRepository();

      final mode = await AdvanceStudyStageUseCase(repository).call(
        session: sessionOf(
          kind: StudySessionKind.learning,
          mode: StudyMode.match,
        ),
        now: now,
        utcOffset: vietnam,
      );

      expect(mode, StudyMode.guess);
      expect(repository.advancedTo, <StudyMode>[StudyMode.guess]);
    });

    test('the last stage finishes the cards and closes the session', () async {
      final repository = FakeStudyRepository(
        finishedCardIds: const <String>['card-1', 'card-2'],
      );

      final mode = await AdvanceStudyStageUseCase(repository).call(
        session: sessionOf(
          kind: StudySessionKind.learning,
          mode: StudyMode.fill,
        ),
        now: now,
        utcOffset: vietnam,
      );

      expect(mode, isNull);
      expect(repository.completed.map((c) => c.cardId), <String>[
        'card-1',
        'card-2',
      ]);
      // BR-144: the lowest rung, due at the start of the next study day.
      expect(repository.completed.first.box, 1);
      expect(repository.completed.first.dueAt, DateTime.utc(2026, 8, 7, 17));
      expect(repository.ended.single.status, StudySessionStatus.completed);
      expect(repository.ended.single.reason, isNull);
    });

    test('completion writes no answer at all (BR-144)', () async {
      // It is an event, not a turn. A `scheduled` row here would make the card
      // look reviewed once before it had ever been reviewed.
      final repository = FakeStudyRepository(
        finishedCardIds: const <String>['card-1'],
      );

      await AdvanceStudyStageUseCase(repository).call(
        session: sessionOf(
          kind: StudySessionKind.learning,
          mode: StudyMode.fill,
        ),
        now: now,
        utcOffset: vietnam,
      );

      expect(repository.answers, isEmpty);
    });

    test(
      'a review session ends after its single stage, learning nothing',
      () async {
        final repository = FakeStudyRepository(
          finishedCardIds: const <String>['card-1'],
        );

        final mode = await AdvanceStudyStageUseCase(repository).call(
          session: sessionOf(
            kind: StudySessionKind.reviewing,
            mode: StudyMode.recall,
          ),
          now: now,
          utcOffset: vietnam,
        );

        expect(mode, isNull);
        // The cards were already learned; completing them again would rewrite
        // `learned_at` and reset the schedule to box 1.
        expect(repository.completed, isEmpty);
        expect(repository.ended.single.status, StudySessionStatus.completed);
      },
    );

    test(
      'a stage the algorithm does not run is refused, not restarted',
      () async {
        // `indexOf` returns −1 for an unrecognised stage, and −1 + 1 is 0 — which
        // would silently restart the whole chain and double the session.
        final repository = FakeStudyRepository();

        await expectLater(
          AdvanceStudyStageUseCase(repository).call(
            session: sessionOf(
              kind: StudySessionKind.learning,
              mode: StudyMode.selfAssess,
            ),
            now: now,
            utcOffset: vietnam,
          ),
          throwsA(isA<ConflictFailure>()),
        );
      },
    );
  });

  group('ending and resuming', () {
    test('the caller supplies the reason, and the matrix is checked', () async {
      final repository = FakeStudyRepository();

      await EndStudySessionUseCase(repository).call(
        sessionId: 'session-1',
        status: StudySessionStatus.abandoned,
        reason: StudySessionEndReason.userExit,
        now: now,
      );

      expect(repository.ended.single.reason, StudySessionEndReason.userExit);
    });

    test('resuming closes yesterday first, then looks for today', () async {
      // Order matters: reversed, it would offer to resume a session it is about
      // to close. The day boundary is local midnight, not 24 hours ago.
      final repository = FakeStudyRepository();

      await ResumeStudyDayUseCase(
        repository,
      ).call(deckId: 'deck-1', now: now, utcOffset: vietnam);

      expect(repository.abandonedBefore, DateTime.utc(2026, 8, 6, 17));
    });
  });
}
