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

/// `match`'s two commands, which are one write and one read.
///
/// **Its own file because the thing under test is an absence.** Every other
/// mode answers one card and fetches the next, and `study_session_controller
/// _test.dart` is about that shape. `match` answers five pairs on a board and
/// fetches once — so what has to be asserted is that four of those five taps
/// read *nothing*, and a count of reads is the only thing that can see it.
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

  group('`match` writes every pair and reads once a board', () {
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

      await controller.answer(
        StudyAction.remembered,
        cardId: 'card-1',
        shouldAdvance: false,
      );

      expect(repository.answers, hasLength(1));
      expect(repository.nextTurnCalls, reads);
    });

    test('a correct pair moves the counter without a read', () async {
      final (repository, controller) = await openMatch();

      await controller.answer(
        StudyAction.remembered,
        cardId: 'card-1',
        shouldAdvance: false,
      );

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

      await controller.answer(
        StudyAction.forgotten,
        cardId: 'card-1',
        shouldAdvance: false,
      );

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
        await controller.answer(
          StudyAction.remembered,
          cardId: 'card-1',
          shouldAdvance: false,
        );
      }

      expect(controller.state.turn!.progress.done, 1);
    });

    test('advancing the board is the one read', () async {
      final (repository, controller) = await openMatch();
      final reads = repository.nextTurnCalls;

      await controller.advanceMatchBoard();

      expect(repository.nextTurnCalls, reads + 1);
    });
  });
}
