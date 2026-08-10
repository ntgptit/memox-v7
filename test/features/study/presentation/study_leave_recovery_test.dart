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

/// What is left of a session when **leaving it fails**.
///
/// **Two questions, and an epoch only answers one.** It says whether a result
/// may reach the screen; it says nothing about whether the operation has
/// finished. On a successful leave that gap is invisible, because the terminal
/// state clears every flag anyway. On a *failed* leave it is the whole problem:
/// the stale branch returns before clearing `isSubmitting`, so the session came
/// back with a busy flag stuck true and `canAnswer` false — a card on screen
/// that nothing could be done with.
///
/// Answering it by clearing the flags in the catch would be worse: the write may
/// still be open, and unlocking on top of it invites the same card to be
/// answered twice (BR-126). So recovery waits for what is in flight to settle
/// and then re-reads, because the answer may well have committed while
/// `EndSession` was failing.
///
/// **Both orders are tested, and they are different.** The operation can settle
/// before `EndSession` fails or after it, and only one of those is the order a
/// naive fix survives.
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
    container.listen(
      studySessionControllerProvider('deck-1'),
      (_, _) {},
      fireImmediately: true,
    );

    return (repository, controller);
  }

  /// What every one of these has to be true of afterwards: nothing stuck, and a
  /// session the user can act on again.
  void expectRecovered(
    FakeStudyRepository repository,
    StudySessionController controller, {
    required int answers,
  }) {
    final state = controller.state;

    expect(state.isLeaving, isFalse, reason: 'leaving was not released');
    expect(state.isSubmitting, isFalse, reason: 'a write flag is stuck');
    expect(state.isAdvancing, isFalse, reason: 'a read flag is stuck');
    expect(state.isFinished, isFalse, reason: 'the session is still running');
    expect(state.error, isNotNull, reason: 'the failure is not hidden');
    expect(repository.answers, hasLength(answers), reason: 'duplicate answer');

    // The turn is the repository's, not a leftover: recovery re-reads rather
    // than keeping whatever was on screen when ✕ was pressed.
    expect(state.turn?.cardId, repository.nextTurn_?.cardId);
    expect(state.canAnswer, isTrue, reason: 'the card cannot be answered');
  }

  group('a write was open when leaving failed', () {
    test('and it commits before the leave does', () async {
      final (repository, controller) = await openSession();
      repository
        ..submitGate = Completer<void>()
        ..endSessionGate = Completer<void>()
        ..endSessionFails = true;

      final answering = controller.submitAnswer(
        StudyAction.remembered,
        cardId: 'card-1',
      );
      await Future<void>.delayed(Duration.zero);
      final leaving = controller.leave();
      await Future<void>.delayed(Duration.zero);

      repository.submitGate!.complete();
      expect(await answering, isNull, reason: 'a stale write is not announced');

      repository.endSessionGate!.complete();
      await leaving;

      expectRecovered(repository, controller, answers: 1);
    });

    test('and it commits after the leave has already failed', () async {
      // The order a naive fix does not survive: the catch runs while the write
      // is still open, so clearing the flags there would unlock the board on top
      // of a transaction that has not returned.
      final (repository, controller) = await openSession();
      repository
        ..submitGate = Completer<void>()
        ..endSessionGate = Completer<void>()
        ..endSessionFails = true;

      final answering = controller.submitAnswer(
        StudyAction.remembered,
        cardId: 'card-1',
      );
      await Future<void>.delayed(Duration.zero);
      final leaving = controller.leave();
      await Future<void>.delayed(Duration.zero);

      repository.endSessionGate!.complete();
      await Future<void>.delayed(Duration.zero);

      // Still locked: the write has not come back, so nothing may be answered.
      expect(controller.state.canAnswer, isFalse);

      repository.submitGate!.complete();
      expect(await answering, isNull);
      await leaving;

      expectRecovered(repository, controller, answers: 1);
    });

    test('and answering again writes one row, not two', () async {
      // BR-126. The turn recovery puts back is the queue's, so answering it is
      // answering the card the session is actually serving.
      final (repository, controller) = await openSession();
      repository
        ..endSessionGate = Completer<void>()
        ..endSessionFails = true;

      final leaving = controller.leave();
      repository.endSessionGate!.complete();
      await leaving;

      await controller.submitAnswer(
        StudyAction.remembered,
        cardId: controller.state.turn!.cardId,
      );

      expect(repository.answers, hasLength(1));
    });
  });

  group('a read was open when leaving failed', () {
    test('and it returns before the leave does', () async {
      final (repository, controller) = await openSession();
      repository
        ..nextTurnGate = Completer<void>()
        ..endSessionGate = Completer<void>()
        ..endSessionFails = true;

      final advancing = controller.advance();
      await Future<void>.delayed(Duration.zero);
      final leaving = controller.leave();
      await Future<void>.delayed(Duration.zero);

      repository.nextTurnGate!.complete();
      await advancing;

      repository.endSessionGate!.complete();
      await leaving;

      expectRecovered(repository, controller, answers: 0);
    });

    test('and it returns after the leave has already failed', () async {
      final (repository, controller) = await openSession();
      repository
        ..nextTurnGate = Completer<void>()
        ..endSessionGate = Completer<void>()
        ..endSessionFails = true;

      final advancing = controller.advance();
      await Future<void>.delayed(Duration.zero);
      final leaving = controller.leave();
      await Future<void>.delayed(Duration.zero);

      repository.endSessionGate!.complete();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.canAnswer, isFalse);

      repository.nextTurnGate!.complete();
      await advancing;
      await leaving;

      expectRecovered(repository, controller, answers: 0);
    });
  });

  test('leaving can be tried again once the session has come back', () async {
    final (repository, controller) = await openSession();
    repository.endSessionFails = true;

    await controller.leave();
    expect(controller.state.isFinished, isFalse);

    repository.endSessionFails = false;
    await controller.leave();

    expect(controller.state.isFinished, isTrue);
    expect(controller.state.turn, isNull);
    expect(controller.state.isLeaving, isFalse);
  });
}
