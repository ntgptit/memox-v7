import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/entities/study_session_entity.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/usecases/resume_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/start_study_session_use_case.dart';

import 'support/fake_study_repository.dart';

/// The three paths offered when a session from today is still open (BR-103).
///
/// **The end reason is the whole point of these tests.** `abandoned`/`user_exit`
/// and `abandoned`/`interrupted` produce the same row to the eye and mean
/// opposite things: one is a person choosing to start something else, the other
/// is the app losing a session overnight. History written with the wrong label
/// cannot be recomputed later, so the label is asserted rather than the count.
void main() {
  final now = DateTime.utc(2026, 8, 7, 2);

  StudySessionEntity openSession() => StudySessionEntity(
    id: 'session-open',
    deckId: 'deck-1',
    rootDeckId: 'root',
    schedulerGeneration: 1,
    kind: StudySessionKind.learning,
    currentMode: StudyMode.recall,
    status: StudySessionStatus.inProgress,
    endReason: null,
    cursor: 3,
    cardLimit: 20,
    startedAt: now,
    endedAt: null,
  );

  group('starting something new', () {
    test(
      'ends the open session as user_exit, not interrupted (BR-103)',
      () async {
        final repository = FakeStudyRepository()..openSession_ = openSession();

        await StartStudySessionUseCase(repository).call(
          deckId: 'deck-1',
          kind: StudySessionKind.learning,
          now: now,
          utcOffset: Duration.zero,
        );

        expect(repository.ended.single.status, StudySessionStatus.abandoned);
        expect(repository.ended.single.reason, StudySessionEndReason.userExit);
      },
    );

    test('sweeps yesterday first, so it cannot label it user_exit', () async {
      // Ordering, not politeness. `abandonStaleSessions` closes an earlier
      // day's session as `interrupted`; run after, this use case would have
      // already stamped `user_exit` on it, and which label a row gets would
      // come down to which screen happened to run first (BR-76, BR-103).
      final repository = FakeStudyRepository();

      await StartStudySessionUseCase(repository).call(
        deckId: 'deck-1',
        kind: StudySessionKind.learning,
        now: now,
        utcOffset: const Duration(hours: 7),
      );

      expect(repository.abandonedBefore, isNotNull);
      expect(repository.abandonedBefore!.isBefore(now), isTrue);
    });

    test('with nothing open it ends nothing', () async {
      // The guard has to be a read, not a blind write: closing "the open
      // session" when there is none would write an ended row for a session id
      // nobody holds.
      final repository = FakeStudyRepository();

      await StartStudySessionUseCase(repository).call(
        deckId: 'deck-1',
        kind: StudySessionKind.learning,
        now: now,
        utcOffset: Duration.zero,
      );

      expect(repository.ended, isEmpty);
    });
  });

  group('continuing', () {
    test('returns the session untouched, and ends nothing (BR-133)', () async {
      final repository = FakeStudyRepository()..openSession_ = openSession();

      final resumed = await ResumeStudySessionUseCase(
        repository,
      ).call('deck-1');

      expect(resumed.session.id, 'session-open');
      expect(resumed.session.status, StudySessionStatus.inProgress);
      expect(resumed.session.cursor, 3);
      // Continuing must not write anything at all: the queue, the cursor and
      // any stored remaining time are exactly what the user left.
      expect(repository.ended, isEmpty);
      expect(repository.opened, isEmpty);
    });

    test('carries the algorithm actions, same as opening one', () async {
      final repository = FakeStudyRepository()..openSession_ = openSession();

      final resumed = await ResumeStudySessionUseCase(
        repository,
      ).call('deck-1');

      expect(resumed.actions, isNotEmpty);
      expect(resumed.schedulerType, repository.schedulerType);
    });

    test('with nothing open it refuses rather than opening one', () async {
      final repository = FakeStudyRepository();

      await expectLater(
        ResumeStudySessionUseCase(repository).call('deck-1'),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(repository.opened, isEmpty);
    });
  });

  /// Resuming a session that was **named**, which is what Study Home does.
  ///
  /// **"The open session of this deck" and "the session on the card that was
  /// tapped" are two different questions**, and they only ever gave the same
  /// answer by luck. Study Home lists a session it has already filtered by four
  /// conditions (BR-182) and then hands its id back; resolving by deck instead
  /// re-asks the looser question and can answer with a different row.
  group('resuming a named session', () {
    StudySessionEntity sessionOf({
      required String id,
      String deckId = 'deck-1',
      StudySessionStatus status = StudySessionStatus.inProgress,
    }) => StudySessionEntity(
      id: id,
      deckId: deckId,
      rootDeckId: 'root',
      schedulerGeneration: 1,
      kind: StudySessionKind.learning,
      currentMode: StudyMode.recall,
      status: status,
      endReason: null,
      cursor: 3,
      cardLimit: 20,
      startedAt: now,
      endedAt: null,
    );

    test('opens the session named, not the deck-s newest', () async {
      // The repro the deck-id path loses: Home filtered S2 out — its cards were
      // deleted, so its queue is empty — and offered S1. `openSessionFor` orders
      // by `started_at DESC`, so it answers S2, and the tap would have opened a
      // session with nothing to serve.
      final repository = FakeStudyRepository()
        ..openSession_ = sessionOf(id: 'session-newer')
        ..sessionsById['session-offered'] = sessionOf(id: 'session-offered');

      final resumed = await ResumeStudySessionUseCase(
        repository,
      ).call('deck-1', sessionId: 'session-offered');

      expect(resumed.session.id, 'session-offered');
      expect(repository.opened, isEmpty);
      expect(repository.ended, isEmpty);
    });

    test('refuses a session that ended between the read and the tap', () async {
      // A list is a snapshot. Re-checking here rather than trusting the read is
      // what stops the app opening a session that can no longer take an answer.
      final repository = FakeStudyRepository()
        ..sessionsById['session-1'] = sessionOf(
          id: 'session-1',
          status: StudySessionStatus.completed,
        );

      await expectLater(
        ResumeStudySessionUseCase(
          repository,
        ).call('deck-1', sessionId: 'session-1'),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(repository.opened, isEmpty);
    });

    test('refuses a session belonging to another deck', () async {
      final repository = FakeStudyRepository()
        ..sessionsById['session-1'] = sessionOf(
          id: 'session-1',
          deckId: 'deck-other',
        );

      await expectLater(
        ResumeStudySessionUseCase(
          repository,
        ).call('deck-1', sessionId: 'session-1'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('refuses a session an earlier study day left open', () async {
      // The last of BR-182's four conditions to be re-checked at the tap. Home
      // excludes yesterday's session from the list and re-reads at midnight, so
      // the card does go — but only once that read lands, and a tap inside the
      // gap resumed a session BR-103 calls `abandoned`/`interrupted`.
      final repository = FakeStudyRepository()
        ..sessionsById['session-1'] = sessionOf(id: 'session-1');

      await expectLater(
        ResumeStudySessionUseCase(repository).call(
          'deck-1',
          sessionId: 'session-1',
          // One local day after the session started.
          now: now.add(const Duration(days: 1)),
          utcOffset: Duration.zero,
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('accepts a session from earlier today', () async {
      // The boundary on the other side: same study day, so it resumes. Without
      // this the rule above could be satisfied by refusing everything.
      final repository = FakeStudyRepository()
        ..sessionsById['session-1'] = sessionOf(id: 'session-1');

      final resumed = await ResumeStudySessionUseCase(repository).call(
        'deck-1',
        sessionId: 'session-1',
        now: now.add(const Duration(hours: 6)),
        utcOffset: Duration.zero,
      );

      expect(resumed.session.id, 'session-1');
    });

    test('refuses an id that names nothing', () async {
      final repository = FakeStudyRepository()..openSession_ = openSession();

      // And specifically does **not** fall back to the deck's open session: a
      // fallback would resurrect exactly the behaviour the id exists to replace.
      await expectLater(
        ResumeStudySessionUseCase(
          repository,
        ).call('deck-1', sessionId: 'session-gone'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}
