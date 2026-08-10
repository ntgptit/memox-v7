import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';

import '../domain/support/fake_study_repository.dart';

/// The shared lifecycle: write, let the answer be read, then move.
///
/// **Its own file because the thing under test is an absence.** Writing used to
/// end in a fetch, and `study_session_controller_test.dart` is about the shape
/// that flow has. What has to be asserted here is that `submitAnswer` reads
/// *nothing* — a count of reads is the only thing that can see it — and that
/// `advance` keeps the turn it is replacing on screen while it works.
void main() {
  final now = DateTime.utc(2026, 8, 7, 2);

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
    progress: const StudyStageProgressModel(
      round: 1,
      done: 0,
      total: 2,
      completedCardIds: <String>[],
    ),
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

  group('writing and advancing are two steps', () {
    Future<(FakeStudyRepository, StudySessionController)> openMatch() async {
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
      // Held across the awaits below: the controller is autoDispose, and a
      // container with nothing listening throws it away between statements.
      container.listen(
        studySessionControllerProvider('deck-1'),
        (_, _) {},
        fireImmediately: true,
      );

      return (repository, controller);
    }

    test('an attempt writes and does not fetch', () async {
      // **The reload was the stutter, not the write.** Each attempt used to end
      // in `_pullTurn`: advance the stage, re-read session, queue, card and
      // progress, and swap the body for a spinner — five times on a board of
      // five, with the board unmounted each time.
      final (repository, controller) = await openMatch();
      final reads = repository.nextTurnCalls;

      await controller.submitAnswer(StudyAction.remembered, cardId: 'card-1');

      expect(repository.answers, hasLength(1));
      expect(repository.nextTurnCalls, reads);
    });

    test('a correct pair moves the counter without a read', () async {
      final (repository, controller) = await openMatch();

      await controller.submitAnswer(StudyAction.remembered, cardId: 'card-1');

      final progress = controller.state.turn!.progress;
      expect(progress.done, 1);
      expect(progress.completedCardIds, <String>['card-1']);
      expect(repository.nextTurnCalls, 1, reason: 'only the opening read');
    });

    test('a wrong pair leaves the board exactly as it was', () async {
      // The card is still on screen and still has to be paired (BR-118), so
      // nothing local may move — least of all `completedCardIds`, which is what
      // empties a slot.
      final (repository, controller) = await openMatch();

      await controller.submitAnswer(StudyAction.forgotten, cardId: 'card-1');

      final progress = controller.state.turn!.progress;
      expect(progress.done, 0);
      expect(progress.completedCardIds, isEmpty);
      expect(repository.answers, hasLength(1));
    });

    test('the same pair counted twice does not overrun the round', () async {
      // A rebuild between the write and the local update can carry a progress
      // that already holds the card; counting it again puts `done` past `total`
      // and deals a board that does not exist.
      final (_, controller) = await openMatch();

      for (var i = 0; i < 2; i++) {
        await controller.submitAnswer(StudyAction.remembered, cardId: 'card-1');
      }

      expect(controller.state.turn!.progress.done, 1);
    });

    test('the receipt decides what moves, not the action', () async {
      // A `match` lapse comes back `pending`: the pair is still on the board and
      // still has to be answered (BR-118). A controller reading `isLapse`
      // instead would be right about `guess` and wrong about `match` while
      // looking identical in both.
      final (_, controller) = await openMatch();

      final commit = await controller.submitAnswer(
        StudyAction.forgotten,
        cardId: 'card-1',
      );

      expect(commit, isNotNull);
      expect(commit!.isCleared, isFalse);
      expect(controller.state.turn!.progress.completedCardIds, isEmpty);
    });

    test(
      'a failed write returns nothing, so nothing is held or advanced',
      () async {
        // BR-157: the screen shows a result only after the transaction holding it
        // has committed. A null receipt is what stops the caller going on to the
        // feedback and the fetch.
        final repository = _RefusingRepository()..nextTurn_ = turnOf('card-1');
        final container = containerWith(repository);
        final controller = container.read(
          studySessionControllerProvider('deck-1').notifier,
        );
        await controller.start(
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.match,
        );
        container.listen(
          studySessionControllerProvider('deck-1'),
          (_, _) {},
          fireImmediately: true,
        );

        final commit = await controller.submitAnswer(
          StudyAction.remembered,
          cardId: 'card-1',
        );

        expect(commit, isNull);
        expect(controller.state.error, isNotNull);
        expect(controller.state.turn?.cardId, 'card-1');
      },
    );

    test('advance holds the current turn until the read comes back', () async {
      // BR-158. The turn used to be cleared into a loading state, so every mode
      // flashed a spinner between two cards — and the answer the user had just
      // given was in the frame being thrown away.
      final (repository, controller) = await openMatch();
      final gate = Completer<void>();
      repository.nextTurnGate = gate;

      final advancing = controller.advance();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isAdvancing, isTrue);
      expect(controller.state.turn?.cardId, 'card-1');

      gate.complete();
      await advancing;
    });

    test('advancing the board is the one read', () async {
      final (repository, controller) = await openMatch();
      final reads = repository.nextTurnCalls;

      await controller.advance();

      expect(repository.nextTurnCalls, reads + 1);
    });
    test(
      'leaving mid-advance does not let the old read revive the turn',
      () async {
        // The scenario the epoch exists for: the read is in flight, the user
        // presses ✕, and the read comes back to a session that has ended. It used
        // to write a turn straight back over the summary.
        final (repository, controller) = await openMatch();
        final gate = Completer<void>();
        repository.nextTurnGate = gate;

        final advancing = controller.advance();
        await Future<void>.delayed(Duration.zero);

        await controller.leave();
        gate.complete();
        await advancing;

        expect(controller.state.isFinished, isTrue);
        expect(controller.state.turn, isNull);
        expect(controller.state.isAdvancing, isFalse);
        expect(controller.state.error, isNull);
      },
    );

    test(
      'leaving mid-write does not let the old answer revive the turn',
      () async {
        // The write still commits — BR-25 wants it to — but its result is not
        // allowed to reach a screen that has moved on.
        final (repository, controller) = await openMatch();
        final gate = Completer<void>();
        repository.submitGate = gate;

        final submitting = controller.submitAnswer(
          StudyAction.remembered,
          cardId: 'card-1',
        );
        await Future<void>.delayed(Duration.zero);

        await controller.leave();
        gate.complete();
        await submitting;

        expect(controller.state.isFinished, isTrue);
        expect(controller.state.turn, isNull);
        expect(controller.state.isSubmitting, isFalse);
        expect(
          repository.answers,
          hasLength(1),
          reason: 'the row was still written',
        );
      },
    );

    test(
      'a write that fails after leaving does not overwrite the summary',
      () async {
        // A stale failure is not this session's failure: an error banner over a
        // summary the user is already reading is worse than a silent one.
        final repository = _FailingAfterGate()..nextTurn_ = turnOf('card-1');
        final container = containerWith(repository);
        final controller = container.read(
          studySessionControllerProvider('deck-1').notifier,
        );
        await controller.start(
          kind: StudySessionKind.reviewing,
          reviewMode: StudyMode.match,
        );
        container.listen(
          studySessionControllerProvider('deck-1'),
          (_, _) {},
          fireImmediately: true,
        );

        final submitting = controller.submitAnswer(
          StudyAction.remembered,
          cardId: 'card-1',
        );
        await Future<void>.delayed(Duration.zero);

        await controller.leave();
        repository.gate.complete();
        await submitting;

        expect(controller.state.isFinished, isTrue);
        expect(controller.state.error, isNull);
      },
    );
  });
}

/// Refuses every write, so a failed commit can be told from a slow one.
final class _RefusingRepository extends FakeStudyRepository {
  _RefusingRepository() : super(stageExhausted: false);

  @override
  Future<StudyAnswerCommitModel> submitAnswer({
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
  }) async => throw const ConflictFailure(message: 'refused');
}

/// Holds every write open, then throws — a failure that lands after the user
/// has left.
final class _FailingAfterGate extends FakeStudyRepository {
  _FailingAfterGate() : super(stageExhausted: false);

  final Completer<void> gate = Completer<void>();

  @override
  Future<StudyAnswerCommitModel> submitAnswer({
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
  }) async {
    await gate.future;

    throw StateError('the write failed after the session ended');
  }
}
