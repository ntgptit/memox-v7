import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/controllers/study_browse_trail_controller.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/states/study_session_state.dart';

import '../domain/support/fake_study_repository.dart';

/// Looking back through `browse`, which is looking and not answering (BR-155).
///
/// **Every claim here is about what was *not* written.** The feature is a card
/// put back on screen; the rule is that putting it there costs nothing — the
/// card stays `completed`, the cursor stays put, and coming forward again does
/// not mark it browsed a second time. A test that only checked which card is
/// drawn would pass on an implementation that re-answered every card the user
/// walked past.
void main() {
  final now = DateTime.utc(2026, 8, 8, 2);

  StudyCardModel cardOf(String id) => StudyCardModel(
    id: id,
    front: 'front-$id',
    back: 'back-$id',
    example: null,
    hint: null,
    pronunciation: null,
    frontFolded: 'front-$id',
    backFolded: 'back-$id',
  );

  /// A `browse` turn on [cardId], with [seen] already behind it in this round.
  StudyTurnModel browseTurn(String cardId, {List<String> seen = const []}) =>
      StudyTurnModel(
        item: StudyQueueItemEntity(
          sessionId: 'session-1',
          mode: StudyMode.browse,
          round: 1,
          cardId: cardId,
          position: seen.length,
          status: StudyQueueItemStatus.pending,
          availableAt: 0,
          answersInSession: 0,
          remainingMs: null,
          isRevealed: false,
        ),
        progress: StudyStageProgressModel(
          round: 1,
          done: seen.length,
          total: seen.length + 1,
          completedCardIds: seen,
        ),
        card: cardOf(cardId),
      );

  /// A controller on an open `learning` session, whose first stage is `browse`.
  Future<
    ({
      FakeStudyRepository repository,
      StudySessionController controller,
      StudyBrowseTrailController trail,
      ProviderContainer container,
    })
  >
  openBrowse({List<String> seen = const []}) async {
    final repository = FakeStudyRepository(stageExhausted: false)
      ..nextTurn_ = browseTurn('card-3', seen: seen)
      ..cards = <StudyCardModel>[
        for (final id in <String>['card-1', 'card-2', 'card-3']) cardOf(id),
      ];

    final container = ProviderContainer(
      overrides: [
        studyRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
        utcOffsetProvider.overrideWithValue(() => Duration.zero),
      ],
    );
    addTearDown(container.dispose);

    // **Held with a listener, not just read.** The controller is `autoDispose`;
    // a test that awaits between two calls without one lets it go, and the
    // failure then reads as "Ref used after dispose" and says nothing about
    // what was being tested.
    final sub = container.listen(
      studySessionControllerProvider('deck-1'),
      (_, _) {},
    );
    addTearDown(sub.close);
    final trailSub = container.listen(
      studyBrowseTrailControllerProvider('deck-1'),
      (_, _) {},
    );
    addTearDown(trailSub.close);

    final controller = container.read(
      studySessionControllerProvider('deck-1').notifier,
    );
    await controller.start(kind: StudySessionKind.learning);

    expect(
      container
          .read(studySessionControllerProvider('deck-1'))
          .session
          ?.currentMode,
      StudyMode.browse,
      reason:
          'a learning session opens on browse; the rest of this file '
          'assumes it',
    );

    return (
      repository: repository,
      controller: controller,
      // Held like the session's, and for the same reason: both are
      // `autoDispose`, and a test that awaits between two calls without a
      // listener lets them go — the failure then reads as "Ref used after
      // dispose" and says nothing about what was being tested.
      trail: container.read(
        studyBrowseTrailControllerProvider('deck-1').notifier,
      ),
      container: container,
    );
  }

  test('stepping back draws the previous card and writes nothing', () async {
    final open = await openBrowse(seen: <String>['card-1', 'card-2']);

    await open.trail.step(StudyBrowseStep.back);

    final state = open.controller.state;
    expect(
      state.viewedCardAt(open.trail.state)?.id,
      'card-2',
      reason: 'the one just before',
    );
    expect(state.isLookingBackAt(open.trail.state), isTrue);
    // The whole rule: looking is free.
    expect(open.repository.browsed, isEmpty);
    expect(open.repository.answers, isEmpty);
    // The live turn is untouched — the counter and the bar still describe it.
    expect(state.turn?.cardId, 'card-3');
  });

  test('two steps back reach the card before that', () async {
    final open = await openBrowse(seen: <String>['card-1', 'card-2']);

    await open.trail.step(StudyBrowseStep.back);
    await open.trail.step(StudyBrowseStep.back);

    expect(open.controller.state.viewedCardAt(open.trail.state)?.id, 'card-1');
    expect(open.repository.browsed, isEmpty);
  });

  test('a step back past the start of the trail is refused', () async {
    final open = await openBrowse(seen: <String>['card-1']);

    await open.trail.step(StudyBrowseStep.back);
    await open.trail.step(StudyBrowseStep.back);

    // Not clamped silently to some other card: the second step does nothing,
    // and the card on screen is the one the first step reached.
    expect(open.trail.state, 1);
    expect(open.controller.state.viewedCardAt(open.trail.state)?.id, 'card-1');
  });

  test(
    'coming forward from a looked-at card records nothing and does not advance',
    () async {
      // **The failure this rule exists to prevent.** If going back moved the
      // cursor, coming forward would run `markBrowsed` again: the card is
      // written twice and the counter jumps by two.
      final open = await openBrowse(seen: <String>['card-1', 'card-2']);

      await open.trail.step(StudyBrowseStep.back);
      await open.trail.step(StudyBrowseStep.forward);

      expect(open.controller.state.isLookingBackAt(open.trail.state), isFalse);
      expect(
        open.controller.state.viewedCardAt(open.trail.state)?.id,
        'card-3',
      );
      expect(open.repository.browsed, isEmpty);
    },
  );

  test('forward from the live turn is still a browsed card (BR-111)', () async {
    final open = await openBrowse(seen: <String>['card-1']);

    await open.trail.step(StudyBrowseStep.forward);

    expect(open.repository.browsed, <String>['card-3']);
    expect(open.repository.answers, isEmpty, reason: 'browse grades nothing');
  });

  test(
    'a second forward while the fetch is in flight writes nothing extra',
    () async {
      // **The guard used to sit under the forward branch, which is the one branch
      // that writes.** `answer()` clears `isSubmitting` before `_pullTurn` sets
      // `isAdvancing`, so a second swipe arriving in that window went straight
      // past both checks and marked the same card browsed twice — BR-155's "no
      // second turn and no second cursor step", broken by the ordering alone.
      final open = await openBrowse(seen: <String>['card-1']);
      final gate = Completer<void>();
      open.repository.nextTurnGate = gate;

      unawaited(open.trail.step(StudyBrowseStep.forward));
      await Future<void>.delayed(Duration.zero);

      // The fetch is held open here; this is the window.
      await open.trail.step(StudyBrowseStep.forward);

      expect(open.repository.browsed, <String>[
        'card-3',
      ], reason: 'one swipe, one card marked browsed');
      expect(open.repository.answers, isEmpty, reason: 'browse grades nothing');

      gate.complete();
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('looking back and stepping forward again writes nothing', () async {
    // BR-155: looking is not answering. Walking back along the trail and
    // returning to the live card must leave the queue and the cursor exactly
    // where the first forward step left them.
    final open = await openBrowse(seen: <String>['card-1', 'card-2']);

    await open.trail.step(StudyBrowseStep.back);
    await open.trail.step(StudyBrowseStep.forward);

    expect(open.repository.browsed, isEmpty);
    expect(open.repository.answers, isEmpty);
    expect(open.repository.advancedTo, isEmpty);
  });

  test('a new turn puts the trail back at its front', () async {
    // An offset outlives the card it was counted from unless something clears
    // it, and the next card would then arrive with a card the user has already
    // walked past drawn over it — with nothing on screen saying so.
    final open = await openBrowse(seen: <String>['card-1', 'card-2']);

    await open.trail.step(StudyBrowseStep.back);
    expect(open.controller.state.isLookingBackAt(open.trail.state), isTrue);

    open.repository.nextTurn_ = browseTurn(
      'card-4',
      seen: <String>['card-1', 'card-2', 'card-3'],
    );
    await open.trail.step(StudyBrowseStep.forward);
    await open.trail.step(StudyBrowseStep.forward);

    expect(open.controller.state.turn?.cardId, 'card-4');
    expect(open.trail.state, 0);
    expect(open.controller.state.viewedCardAt(open.trail.state)?.id, 'card-4');
  });

  test('a round with nothing behind it cannot be stepped back', () async {
    final open = await openBrowse();

    expect(open.controller.state.canLookBackFrom(open.trail.state), isFalse);

    await open.trail.step(StudyBrowseStep.back);

    expect(open.controller.state.isLookingBackAt(open.trail.state), isFalse);
    expect(open.controller.state.viewedCardAt(open.trail.state)?.id, 'card-3');
  });

  test('a graded stage cannot be stepped back at all', () async {
    // BR-155 names `browse` and only `browse`. Every other stage takes an
    // answer from the card on screen, so an already-answered card there is an
    // invitation to grade what the session has graded (BR-126).
    final repository = FakeStudyRepository(stageExhausted: false)
      ..nextTurn_ = browseTurn('card-3', seen: <String>['card-1', 'card-2'])
      ..cards = <StudyCardModel>[cardOf('card-1'), cardOf('card-3')];

    final container = ProviderContainer(
      overrides: [
        studyRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
        utcOffsetProvider.overrideWithValue(() => Duration.zero),
      ],
    );
    addTearDown(container.dispose);

    // **Held with a listener, not just read.** The controller is `autoDispose`;
    // a test that awaits between two calls without one lets it go, and the
    // failure then reads as "Ref used after dispose" and says nothing about
    // what was being tested.
    final sub = container.listen(
      studySessionControllerProvider('deck-1'),
      (_, _) {},
    );
    addTearDown(sub.close);

    final controller = container.read(
      studySessionControllerProvider('deck-1').notifier,
    );
    await controller.start(
      kind: StudySessionKind.reviewing,
      reviewMode: StudyMode.match,
    );

    final trail = container.read(
      studyBrowseTrailControllerProvider('deck-1').notifier,
    );
    await trail.step(StudyBrowseStep.back);

    expect(controller.state.isLookingBackAt(trail.state), isFalse);
  });
}
