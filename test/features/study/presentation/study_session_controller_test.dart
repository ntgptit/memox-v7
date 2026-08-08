import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';

import '../domain/support/fake_study_repository.dart';

/// The controller's own job, which is smaller than it looks.
///
/// **Everything the queue decides is deliberately absent from these tests.**
/// Which card is next, whether a forgotten one comes back, when a round ends —
/// all of that runs inside a transaction and is covered against a real database.
/// What is left is the part nothing below the controller can see: that a person
/// can tap twice before the first write returns, and that a screen must not be
/// updated after it is gone.
void main() {
  final now = DateTime.utc(2026, 8, 7, 2);

  /// `match`, not `self_assess`: the fake deck is on `eight_box`, and that
  /// algorithm's review modes are the four graded ones (BR-146). Asking it for
  /// `self_assess` is refused, which is the rule working rather than a bug.
  StudyTurnModel turnOf(String cardId) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: StudyMode.match,
      round: 1,
      cardId: cardId,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
    ),
    progress: const StudyStageProgressModel(round: 1, done: 0, total: 1),
    card: StudyCardModel(
      id: cardId,
      front: 'front',
      back: 'back',
      example: null,
      hint: null,
      pronunciation: null,
      backFolded: 'back',
    ),
  );

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

  group('starting a session', () {
    test('initial → loading → loaded, with the algorithm-s actions', () async {
      final repository = FakeStudyRepository(stageExhausted: false)
        ..nextTurn_ = turnOf('card-1');
      final container = containerWith(repository);
      final controller = container.read(
        studySessionControllerProvider('deck-1').notifier,
      );

      expect(
        container.read(studySessionControllerProvider('deck-1')).isOpening,
        isFalse,
      );

      await controller.start(kind: StudySessionKind.learning);
      final state = container.read(studySessionControllerProvider('deck-1'));

      expect(state.isOpening, isFalse);
      expect(state.turn?.cardId, 'card-1');
      // Rendered from the scheduler, never from a list in a widget (BR-30).
      expect(state.actions, <StudyAction>[
        StudyAction.forgotten,
        StudyAction.remembered,
      ]);
    });

    test('a refusal lands on error, not on a half-open session', () async {
      final repository = FakeStudyRepository(openSessionFails: true);
      final container = containerWith(repository);

      await container
          .read(studySessionControllerProvider('deck-1').notifier)
          .start(kind: StudySessionKind.reviewing, reviewMode: StudyMode.match);

      final state = container.read(studySessionControllerProvider('deck-1'));
      expect(state.error, isNotNull);
      expect(state.session, isNull);
      expect(state.isOpening, isFalse);
    });
  });

  group('answering', () {
    test(
      'two taps in the same window write one answer (BR-25, BR-126)',
      () async {
        // The window is real: the write takes long enough for a second tap to
        // land inside it. Awaiting both calls in sequence would not reproduce it.
        final repository = FakeStudyRepository(stageExhausted: false)
          ..nextTurn_ = turnOf('card-1');
        final container = containerWith(repository);
        final controller = container.read(
          studySessionControllerProvider('deck-1').notifier,
        );
        await controller.start(
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.match,
        );

        final first = controller.answer(StudyAction.remembered);
        final second = controller.answer(StudyAction.remembered);
        await Future.wait(<Future<void>>[first, second]);

        expect(repository.answers, hasLength(1));
      },
    );

    test('the card stays on screen while the answer is written', () async {
      // `isSubmitting` and `isLoading` are separate for this: the content must
      // not disappear between the tap and the next card, and one shared boolean
      // cannot express "visible but locked".
      final repository = FakeStudyRepository(stageExhausted: false)
        ..nextTurn_ = turnOf('card-1');
      final container = containerWith(repository);
      final controller = container.read(
        studySessionControllerProvider('deck-1').notifier,
      );
      await controller.start(
        kind: StudySessionKind.reviewing,
        reviewMode: StudyMode.match,
      );

      final states = <bool>[];
      container.listen(
        studySessionControllerProvider('deck-1'),
        (_, next) => states.add(next.turn != null),
        fireImmediately: true,
      );

      await controller.answer(StudyAction.remembered);

      expect(states, isNot(contains(false)));
    });

    test('a failed write keeps the card, and does not move on', () async {
      final repository = _FailingRepository();
      final container = containerWith(repository);
      final controller = container.read(
        studySessionControllerProvider('deck-1').notifier,
      );
      repository.nextTurn_ = turnOf('card-1');
      await controller.start(
        kind: StudySessionKind.reviewing,
        reviewMode: StudyMode.match,
      );

      await controller.answer(StudyAction.remembered);
      final state = container.read(studySessionControllerProvider('deck-1'));

      expect(state.error, isNotNull);
      expect(state.isSubmitting, isFalse);
      // A failed write must not look like a card that was answered and passed.
      expect(state.turn?.cardId, 'card-1');
    });

    test('an answer with nothing on screen is ignored', () async {
      final repository = FakeStudyRepository();
      final container = containerWith(repository);

      await container
          .read(studySessionControllerProvider('deck-1').notifier)
          .answer(StudyAction.remembered);

      expect(repository.answers, isEmpty);
    });
  });

  group('finishing', () {
    test('an exhausted last stage finishes the session', () async {
      final repository = FakeStudyRepository(
        finishedCardIds: const <String>['card-1'],
      );
      final container = containerWith(repository);

      await container
          .read(studySessionControllerProvider('deck-1').notifier)
          .start(
            kind: StudySessionKind.reviewing,
            reviewMode: StudyMode.recall,
          );

      final state = container.read(studySessionControllerProvider('deck-1'));
      expect(state.isFinished, isTrue);
      expect(state.turn, isNull);
      expect(repository.ended.single.status, StudySessionStatus.completed);
    });

    test('leaving closes the session as user_exit (BR-82)', () async {
      final repository = FakeStudyRepository(stageExhausted: false)
        ..nextTurn_ = turnOf('card-1');
      final container = containerWith(repository);
      final controller = container.read(
        studySessionControllerProvider('deck-1').notifier,
      );
      await controller.start(kind: StudySessionKind.learning);

      await controller.leave();

      expect(repository.ended.single.status, StudySessionStatus.abandoned);
      // Never `interrupted`: the person pressed something (BR-103).
      expect(repository.ended.single.reason, StudySessionEndReason.userExit);
    });

    test('leaving twice closes once', () async {
      final repository = FakeStudyRepository(stageExhausted: false)
        ..nextTurn_ = turnOf('card-1');
      final container = containerWith(repository);
      final controller = container.read(
        studySessionControllerProvider('deck-1').notifier,
      );
      await controller.start(kind: StudySessionKind.learning);

      await controller.leave();
      await controller.leave();

      expect(repository.ended, hasLength(1));
    });
  });

  test('a write that lands after disposal does not throw', () async {
    // `ref.mounted` is what stops it. Without the guard the completion writes
    // into a disposed notifier and the failure surfaces as an unrelated crash
    // several frames later.
    final repository = _SlowRepository()..nextTurn_ = turnOf('card-1');
    final container = ProviderContainer(
      overrides: [
        studyRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
        utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
      ],
    );

    final controller = container.read(
      studySessionControllerProvider('deck-1').notifier,
    );
    final pending = controller.start(kind: StudySessionKind.learning);
    container.dispose();

    await expectLater(pending, completes);
  });

  group('the summary of a finished session', () {
    test('is read once, not once per number (AD-13)', () async {
      // Four counts and a status, from one instant. Read separately they would
      // each be right and describe five different moments — and the one that
      // matters most, `status`, is the one a later read can change.
      final repository = FakeStudyRepository(
        finishedCardIds: const <String>['card-1'],
      );
      final container = containerWith(repository);

      await container
          .read(studySessionControllerProvider('deck-1').notifier)
          .start(
            kind: StudySessionKind.reviewing,
            reviewMode: StudyMode.recall,
          );

      final state = container.read(studySessionControllerProvider('deck-1'));
      expect(state.isFinished, isTrue);
      expect(state.summary, isNotNull);
      expect(repository.summaryReads, 1);
    });

    test('takes eight_box-s own lapse action (BR-20)', () async {
      final repository = FakeStudyRepository(
        finishedCardIds: const <String>['card-1'],
      );
      final container = containerWith(repository);

      await container
          .read(studySessionControllerProvider('deck-1').notifier)
          .start(
            kind: StudySessionKind.reviewing,
            reviewMode: StudyMode.recall,
          );

      expect(repository.summaryWrongActions, <StudyAction>[
        StudyAction.forgotten,
      ]);
    });

    test('takes sm2-s own, which is a different value', () async {
      // The reason the actions are a parameter at all. A query naming
      // `forgotten` would report a spotless session on every sm2 deck, and the
      // number would look plausible.
      //
      // It is also why this is not `binaryAction`: sm2 returns null for that
      // one by design (BR-106), so asking it here would have counted nothing.
      final repository = FakeStudyRepository(
        schedulerType: SchedulerType.sm2,
        finishedCardIds: const <String>['card-1'],
      );
      final container = containerWith(repository);

      await container
          .read(studySessionControllerProvider('deck-1').notifier)
          .start(
            kind: StudySessionKind.reviewing,
            reviewMode: StudyMode.selfAssess,
          );

      expect(repository.summaryWrongActions, <StudyAction>[StudyAction.again]);
    });

    test(
      'leaving also produces one, so the screen can say it stopped',
      () async {
        final repository = FakeStudyRepository()..nextTurn_ = turnOf('c1');
        final container = containerWith(repository);
        final controller = container.read(
          studySessionControllerProvider('deck-1').notifier,
        );

        await controller.start(kind: StudySessionKind.learning);
        await controller.leave();

        expect(repository.summaryReads, 1);
      },
    );
  });
}

/// Fails every write, to prove the card survives a failed answer.
final class _FailingRepository extends FakeStudyRepository {
  _FailingRepository() : super(stageExhausted: false);

  @override
  Future<void> submitAnswer({
    required String sessionId,
    required String cardId,
    required StudyMode mode,
    required StudyAction action,
    required DateTime now,
    StudyOutcomeReason? outcomeReason,
    int? comparisonVersion,
    bool? usedHint,
    DateTime? nextDueAt,
    int? nextBox,
    double? nextEaseFactor,
    int? nextIntervalDays,
  }) async => throw StateError('write failed');
}

/// Defers its first read past a microtask, so a dispose can land inside it.
final class _SlowRepository extends FakeStudyRepository {
  _SlowRepository() : super(stageExhausted: false);

  @override
  Future<bool> isStageExhausted(String sessionId) async {
    await Future<void>.delayed(Duration.zero);

    return false;
  }
}
