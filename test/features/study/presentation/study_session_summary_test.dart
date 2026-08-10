import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/controllers/study_session_summary_controller.dart';

import 'package:memox/features/study/domain/models/study_session_summary_model.dart';

import '../domain/support/fake_study_repository.dart';

/// The session's epilogue, which is a **query** and no longer a field.
///
/// **It used to live in the controller, and that was the shape of two bugs
/// waiting.** The read had three call sites — end of stage, leave, and the
/// failure path — so the summary was only ever as correct as the last person to
/// remember all three; and the field it landed in outlived the session, so a
/// forgotten call showed the previous session's numbers under the new one's
/// title. A provider is asked when the screen needs it and cannot be forgotten.
///
/// What has not changed is the rule underneath: **one read, not one per
/// number** (AD-13). Four counts and a status taken separately would each be
/// right and describe five different moments — and `status`, the one that
/// matters most, is the one a later read can change.
void main() {
  final now = DateTime.utc(2026, 8, 7, 2);

  ProviderContainer containerWith(FakeStudyRepository repository) {
    final container = ProviderContainer(
      overrides: [
        studyRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
        utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  Future<void> openAndFinish(
    ProviderContainer container, {
    required StudyMode reviewMode,
  }) => container
      .read(studySessionControllerProvider('deck-1').notifier)
      .start(kind: StudySessionKind.reviewing, reviewMode: reviewMode);

  test('is read once, not once per number (AD-13)', () async {
    final repository = FakeStudyRepository(
      finishedCardIds: const <String>['card-1'],
    );
    final container = containerWith(repository);

    await openAndFinish(container, reviewMode: StudyMode.recall);
    await container.read(studySessionSummaryProvider('deck-1').future);

    expect(repository.summaryReads, 1);
  });

  test('is not read at all while the session is still running', () async {
    // The point of moving it out: the controller no longer pays for a read it
    // has no use for, and the screen asks only in the branch that shows it.
    final repository = FakeStudyRepository(stageExhausted: false)
      ..nextTurn_ = null;
    final container = containerWith(repository);

    await container
        .read(studySessionControllerProvider('deck-1').notifier)
        .start(kind: StudySessionKind.learning);

    expect(repository.summaryReads, 0);
  });

  test('takes eight_box-s own lapse action (BR-20)', () async {
    final repository = FakeStudyRepository(
      finishedCardIds: const <String>['card-1'],
    );
    final container = containerWith(repository);

    await openAndFinish(container, reviewMode: StudyMode.recall);
    await container.read(studySessionSummaryProvider('deck-1').future);

    expect(repository.summaryWrongActions, <StudyAction>[
      StudyAction.forgotten,
    ]);
  });

  test('takes sm2-s own, which is a different value', () async {
    // The reason the actions are a parameter at all. A query naming
    // `forgotten` would report a spotless session on every sm2 deck, and the
    // number would look plausible.
    //
    // It is also why this is not `binaryAction`: sm2 returns null for that one
    // by design (BR-106), so asking it here would have counted nothing.
    final repository = FakeStudyRepository(
      schedulerType: SchedulerType.sm2,
      finishedCardIds: const <String>['card-1'],
    );
    final container = containerWith(repository);

    await openAndFinish(container, reviewMode: StudyMode.selfAssess);
    await container.read(studySessionSummaryProvider('deck-1').future);

    expect(repository.summaryWrongActions, <StudyAction>[StudyAction.again]);
  });

  test(
    'a session left mid-way still has one, so the screen can say it stopped',
    () async {
      final repository = FakeStudyRepository()..nextTurn_ = null;
      final container = containerWith(repository);
      final controller = container.read(
        studySessionControllerProvider('deck-1').notifier,
      );

      await controller.start(kind: StudySessionKind.learning);
      await controller.leave();
      await container.read(studySessionSummaryProvider('deck-1').future);

      expect(repository.summaryReads, greaterThanOrEqualTo(1));
    },
  );

  test('a read that fails is a session without counts, not an error', () async {
    // The session has genuinely ended; refusing to say so because the epilogue
    // could not be read is the worse answer.
    final repository = _FailingSummary(
      finishedCardIds: const <String>['card-1'],
    );
    final container = containerWith(repository);

    await openAndFinish(container, reviewMode: StudyMode.recall);

    expect(
      await container.read(studySessionSummaryProvider('deck-1').future),
      isNull,
    );
  });
}

/// Refuses to summarise anything.
final class _FailingSummary extends FakeStudyRepository {
  _FailingSummary({required super.finishedCardIds});

  @override
  Future<StudySessionSummaryModel> sessionSummary({
    required String sessionId,
    required List<StudyAction> wrongActions,
  }) async => throw StateError('the summary could not be read');
}
