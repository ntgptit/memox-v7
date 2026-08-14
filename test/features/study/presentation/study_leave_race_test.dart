import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';

import '../domain/support/fake_study_repository.dart';

/// Leaving is a **trip to the database**, and everything that can happen during
/// one, does.
///
/// **The order these tests run in is the whole point.** A test that awaits
/// `leave()` and only then releases the operation it raced skips the window
/// being tested: by then the session has ended and every guard is trivially
/// satisfied. Each test below holds `endSession` open, acts inside it, and
/// releases in the order a person produces — answer first, ✕ second, database
/// last.
///
/// What the epoch alone could not do is stop a *new* interaction: anything
/// starting after `leave()` captures the new epoch and passes the staleness
/// check. That is what `isLeaving` refuses.
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
      direction: null,
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
      frontFolded: 'front',
      backFolded: 'back',
    ),
  );

  Future<(FakeStudyRepository, StudySessionController)> openSession() async {
    final repository = FakeStudyRepository(stageExhausted: false)
      ..nextTurn_ = turnOf('card-1');
    final container = ProviderContainer(
      overrides: [
        studyRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
        utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
      ],
    );
    addTearDown(container.dispose);

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

  test('while leaving is pending the session takes no new answer', () async {
    final (repository, controller) = await openSession();
    repository.endSessionGate = Completer<void>();

    final leaving = controller.leave();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.isLeaving, isTrue);
    expect(controller.state.canAnswer, isFalse);

    final refused = await controller.submitAnswer(
      StudyAction.remembered,
      cardId: 'card-1',
    );

    expect(refused, isNull);
    expect(repository.answers, isEmpty, reason: 'no answer was written');

    repository.endSessionGate!.complete();
    await leaving;
  });

  test('two presses inside one write end the session once', () async {
    // The ✕ and the back gesture can be the same press (BR-82), and each used
    // to end the session again.
    final (repository, controller) = await openSession();
    repository.endSessionGate = Completer<void>();

    final first = controller.leave();
    await Future<void>.delayed(Duration.zero);
    final second = controller.leave();

    repository.endSessionGate!.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.ended, hasLength(1));
  });

  test('an answer that lands mid-leave is not acknowledged', () async {
    // **The row is written and stays written** (BR-25, BR-86). What the receipt
    // means to a caller is "carry on with the lifecycle", and a session the user
    // has left has none — so a null receipt is what stops the widget drawing a
    // verdict and calling `advance` over the top of it.
    final (repository, controller) = await openSession();
    repository.submitGate = Completer<void>();

    final answering = controller.submitAnswer(
      StudyAction.remembered,
      cardId: 'card-1',
    );
    await Future<void>.delayed(Duration.zero);

    repository.endSessionGate = Completer<void>();
    final leaving = controller.leave();
    await Future<void>.delayed(Duration.zero);

    // The answer resolves *before* the session has finished ending — the order
    // a person produces, and the one a test that awaits `leave()` first never
    // reaches.
    repository.submitGate!.complete();
    final receipt = await answering;

    expect(receipt, isNull);
    expect(repository.answers, hasLength(1), reason: 'the row was written');
    expect(controller.state.turn?.progress.done, 0, reason: 'nothing moved');

    repository.endSessionGate!.complete();
    await leaving;
  });

  test('a read that lands mid-leave does not put a turn back', () async {
    final (repository, controller) = await openSession();
    repository.nextTurnGate = Completer<void>();

    final advancing = controller.advance();
    await Future<void>.delayed(Duration.zero);

    repository.endSessionGate = Completer<void>();
    final leaving = controller.leave();
    await Future<void>.delayed(Duration.zero);

    repository.nextTurnGate!.complete();
    await advancing;

    repository.endSessionGate!.complete();
    await leaving;

    expect(controller.state.isFinished, isTrue);
    expect(controller.state.turn, isNull);
    expect(controller.state.isLeaving, isFalse);
    expect(controller.state.isAdvancing, isFalse);
    expect(controller.state.isSubmitting, isFalse);
    expect(controller.state.error, isNull);
  });

  test('advancing cannot be started while leaving', () async {
    final (repository, controller) = await openSession();
    repository.endSessionGate = Completer<void>();
    final reads = repository.nextTurnCalls;

    final leaving = controller.leave();
    await Future<void>.delayed(Duration.zero);

    await controller.advance();

    expect(repository.nextTurnCalls, reads, reason: 'no next turn was read');

    repository.endSessionGate!.complete();
    await leaving;
  });

  test('a session that could not be ended is still answerable', () async {
    // Leaving locked and never unlocking is worse than saying the ✕ did not
    // work: the user can try again, or answer the card still in front of them.
    final (repository, controller) = await openSession();
    repository.endSessionFails = true;

    await controller.leave();

    expect(controller.state.isLeaving, isFalse);
    expect(controller.state.isFinished, isFalse);
    expect(controller.state.error, isNotNull);
    expect(controller.state.canAnswer, isTrue);
  });
}
