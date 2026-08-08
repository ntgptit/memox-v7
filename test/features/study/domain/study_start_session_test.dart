import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_refusal_failure.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/usecases/start_study_session_use_case.dart';

import 'support/fake_study_repository.dart';

/// Which stages a session gets, and which requests are refused (BR-97, BR-146).
///
/// **The queue is not re-tested here.** It runs against a real database in
/// `test/features/study/data/`; asserting it again through a double would only
/// prove the double behaves as written.
void main() {
  // 09:00 in Hanoi on the 7th.
  final now = DateTime.utc(2026, 8, 7, 2);

  group('opening a session', () {
    test('a learning session runs the whole stage sequence (BR-110)', () async {
      final repository = FakeStudyRepository();

      await StartStudySessionUseCase(repository).call(
        deckId: 'deck-1',
        kind: StudySessionKind.learning,
        now: now,
        utcOffset: Duration.zero,
      );

      expect(repository.opened.single.stages, <StudyMode>[
        StudyMode.browse,
        StudyMode.match,
        StudyMode.guess,
        StudyMode.recall,
        StudyMode.fill,
      ]);
    });

    test('sm2 runs two stages, not five', () async {
      // The stage list is the algorithm's, never the screen's (BR-97). A UI
      // holding its own would be wrong for every deck on the other algorithm.
      final repository = FakeStudyRepository(schedulerType: SchedulerType.sm2);

      await StartStudySessionUseCase(repository).call(
        deckId: 'deck-1',
        kind: StudySessionKind.learning,
        now: now,
        utcOffset: Duration.zero,
      );

      expect(repository.opened.single.stages, <StudyMode>[
        StudyMode.browse,
        StudyMode.selfAssess,
      ]);
    });

    test(
      'a review session runs exactly the one mode chosen (BR-109)',
      () async {
        final repository = FakeStudyRepository();

        await StartStudySessionUseCase(repository).call(
          deckId: 'deck-1',
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.recall,
          now: now,
          utcOffset: Duration.zero,
        );

        expect(repository.opened.single.stages, <StudyMode>[StudyMode.recall]);
      },
    );

    test('a mode the algorithm does not offer is refused (BR-146)', () async {
      // Refused rather than quietly substituted: a user who picked `fill` and
      // silently got `match` would have no way to tell it happened.
      final repository = FakeStudyRepository(schedulerType: SchedulerType.sm2);

      await expectLater(
        StartStudySessionUseCase(repository).call(
          deckId: 'deck-1',
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.fill,
          now: now,
          utcOffset: Duration.zero,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            StudyRefusalReason.modeNotSupportedByScheduler,
          ),
        ),
      );
      expect(repository.opened, isEmpty);
    });

    test('browse is never accepted as a review mode (BR-146)', () async {
      final repository = FakeStudyRepository();

      await expectLater(
        StartStudySessionUseCase(repository).call(
          deckId: 'deck-1',
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.browse,
          now: now,
          utcOffset: Duration.zero,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('a deck on an unknown algorithm cannot be studied', () async {
      // Readable, not studiable. Guessing the rules would write a schedule
      // under an algorithm this build does not have.
      final repository = FakeStudyRepository(
        schedulerType: SchedulerType.unknown,
      );

      await expectLater(
        StartStudySessionUseCase(repository).call(
          deckId: 'deck-1',
          kind: StudySessionKind.learning,
          now: now,
          utcOffset: Duration.zero,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test(
      'the card limit is read once and frozen onto the session (BR-139)',
      () async {
        final repository = FakeStudyRepository(cardLimit: 7);

        final session = await StartStudySessionUseCase(repository).call(
          deckId: 'deck-1',
          kind: StudySessionKind.learning,
          now: now,
          utcOffset: Duration.zero,
        );

        expect(repository.opened.single.limit, 7);
        expect(session.session.cardLimit, 7);
      },
    );

    test('a refusal from the repository reaches the caller intact', () async {
      // BR-145's "nothing due" has to arrive as a reason the screen can switch
      // on, not as a sentence it is forbidden to render.
      final repository = FakeStudyRepository(openSessionFails: true);

      await expectLater(
        StartStudySessionUseCase(repository).call(
          deckId: 'deck-1',
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.match,
          now: now,
          utcOffset: Duration.zero,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            StudyRefusalReason.nothingDueToReview,
          ),
        ),
      );
    });
  });
}
