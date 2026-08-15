import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/usecases/open_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/start_study_session_use_case.dart';

import 'support/fake_study_repository.dart';

/// Which sessions may carry a recall direction, and which are refused (BR-208).
///
/// **Both refusals are load-bearing, and the second one more than the first.**
/// A missing direction on an eligible session is an incomplete request and fails
/// loudly. A direction supplied on an *ineligible* one would never surface: the
/// column takes it, the queue stamps it, and only a reader months later finds a
/// `match` turn claiming to have been asked from the meaning.
void main() {
  // 09:00 in Hanoi on the 7th.
  final now = DateTime.utc(2026, 8, 7, 2);

  Future<void> start(
    FakeStudyRepository repository, {
    required StudySessionKind kind,
    StudyMode? reviewMode,
    StudySessionDirection? direction,
  }) => StartStudySessionUseCase(repository).call(
    deckId: 'deck-1',
    kind: kind,
    reviewMode: reviewMode,
    direction: direction,
    now: now,
    utcOffset: Duration.zero,
  );

  group('an sm2 self-assess review', () {
    test('carries the direction it was given', () async {
      final repository = FakeStudyRepository(schedulerType: SchedulerType.sm2);

      await start(
        repository,
        kind: StudySessionKind.reviewing,
        reviewMode: StudyMode.selfAssess,
        direction: StudySessionDirection.meaningToKorean,
      );

      expect(
        repository.opened.single.direction,
        StudySessionDirection.meaningToKorean,
      );
    });

    test('takes mixed as readily as either fixed choice', () async {
      final repository = FakeStudyRepository(schedulerType: SchedulerType.sm2);

      await start(
        repository,
        kind: StudySessionKind.reviewing,
        reviewMode: StudyMode.selfAssess,
        direction: StudySessionDirection.mixed,
      );

      expect(repository.opened.single.direction, StudySessionDirection.mixed);
    });

    test('is refused without one, and opens nothing', () async {
      final repository = FakeStudyRepository(schedulerType: SchedulerType.sm2);

      await expectLater(
        start(
          repository,
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.selfAssess,
        ),
        throwsA(isA<ValidationFailure>()),
      );

      // BR-101: a refused session leaves nothing behind.
      expect(repository.opened, isEmpty);
    });
  });

  group('everything else is refused a direction (BR-203)', () {
    test('an eight_box review cannot be given one', () async {
      final repository = FakeStudyRepository();

      await expectLater(
        start(
          repository,
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.match,
          direction: StudySessionDirection.mixed,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(repository.opened, isEmpty);
    });

    test('an sm2 learning chain cannot be given one', () async {
      // Its stages are not the user's to choose (BR-109), and `browse` shows
      // both faces at once (BR-112) — there is no direction to honour.
      final repository = FakeStudyRepository(schedulerType: SchedulerType.sm2);

      await expectLater(
        start(
          repository,
          kind: StudySessionKind.learning,
          direction: StudySessionDirection.koreanToMeaning,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(repository.opened, isEmpty);
    });

    test('an eight_box learning chain cannot be given one', () async {
      final repository = FakeStudyRepository();

      await expectLater(
        start(
          repository,
          kind: StudySessionKind.learning,
          direction: StudySessionDirection.koreanToMeaning,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(repository.opened, isEmpty);
    });

    test('every ineligible session still opens without one', () async {
      // The other side of the refusal: nothing about BR-203 makes an ordinary
      // session harder to start.
      for (final (SchedulerType scheduler, StudyMode? mode)
          in <(SchedulerType, StudyMode?)>[
            (SchedulerType.eightBox, StudyMode.match),
            (SchedulerType.eightBox, StudyMode.guess),
            (SchedulerType.eightBox, StudyMode.recall),
            (SchedulerType.eightBox, StudyMode.fill),
            (SchedulerType.eightBox, null),
            (SchedulerType.sm2, null),
          ]) {
        final repository = FakeStudyRepository(schedulerType: scheduler);

        await start(
          repository,
          kind: mode == null
              ? StudySessionKind.learning
              : StudySessionKind.reviewing,
          reviewMode: mode,
        );

        expect(repository.opened.single.direction, isNull);
      }
    });
  });

  test('resume asks nothing and is given nothing (BR-207)', () async {
    // The session already carries its direction on every row of its queue.
    // Passing one here must not open a second session, and must not reach the
    // repository as a fresh choice.
    final repository = FakeStudyRepository(schedulerType: SchedulerType.sm2)
      ..openSession_ = null;

    await expectLater(
      OpenStudySessionUseCase(repository).call(
        deckId: 'deck-1',
        kind: StudySessionKind.reviewing,
        reviewMode: StudyMode.selfAssess,
        direction: StudySessionDirection.mixed,
        shouldResume: true,
        now: now,
        utcOffset: Duration.zero,
      ),
      throwsA(isA<NotFoundFailure>()),
    );

    expect(repository.opened, isEmpty);
  });
}
