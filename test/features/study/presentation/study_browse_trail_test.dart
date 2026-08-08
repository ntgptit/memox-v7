import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';

import 'package:memox/features/study/presentation/widgets/support/study_swipe_deck_widget.dart';

import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

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
  Future<({FakeStudyRepository repository, StudySessionController controller})>
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

    return (repository: repository, controller: controller);
  }

  test('stepping back draws the previous card and writes nothing', () async {
    final open = await openBrowse(seen: <String>['card-1', 'card-2']);

    await open.controller.browseStep(StudyBrowseStep.back);

    final state = open.controller.state;
    expect(state.viewedCard?.id, 'card-2', reason: 'the one just before');
    expect(state.isLookingBack, isTrue);
    // The whole rule: looking is free.
    expect(open.repository.browsed, isEmpty);
    expect(open.repository.answers, isEmpty);
    // The live turn is untouched — the counter and the bar still describe it.
    expect(state.turn?.cardId, 'card-3');
  });

  test('two steps back reach the card before that', () async {
    final open = await openBrowse(seen: <String>['card-1', 'card-2']);

    await open.controller.browseStep(StudyBrowseStep.back);
    await open.controller.browseStep(StudyBrowseStep.back);

    expect(open.controller.state.viewedCard?.id, 'card-1');
    expect(open.repository.browsed, isEmpty);
  });

  test('a step back past the start of the trail is refused', () async {
    final open = await openBrowse(seen: <String>['card-1']);

    await open.controller.browseStep(StudyBrowseStep.back);
    await open.controller.browseStep(StudyBrowseStep.back);

    // Not clamped silently to some other card: the second step does nothing,
    // and the card on screen is the one the first step reached.
    expect(open.controller.state.browseLookBack, 1);
    expect(open.controller.state.viewedCard?.id, 'card-1');
  });

  test(
    'coming forward from a looked-at card records nothing and does not advance',
    () async {
      // **The failure this rule exists to prevent.** If going back moved the
      // cursor, coming forward would run `markBrowsed` again: the card is
      // written twice and the counter jumps by two.
      final open = await openBrowse(seen: <String>['card-1', 'card-2']);

      await open.controller.browseStep(StudyBrowseStep.back);
      await open.controller.browseStep(StudyBrowseStep.forward);

      expect(open.controller.state.isLookingBack, isFalse);
      expect(open.controller.state.viewedCard?.id, 'card-3');
      expect(open.repository.browsed, isEmpty);
    },
  );

  test('forward from the live turn is still a browsed card (BR-111)', () async {
    final open = await openBrowse(seen: <String>['card-1']);

    await open.controller.browseStep(StudyBrowseStep.forward);

    expect(open.repository.browsed, <String>['card-3']);
    expect(open.repository.answers, isEmpty, reason: 'browse grades nothing');
  });

  test('a new turn puts the trail back at its front', () async {
    // An offset outlives the card it was counted from unless something clears
    // it, and the next card would then arrive with a card the user has already
    // walked past drawn over it — with nothing on screen saying so.
    final open = await openBrowse(seen: <String>['card-1', 'card-2']);

    await open.controller.browseStep(StudyBrowseStep.back);
    expect(open.controller.state.isLookingBack, isTrue);

    open.repository.nextTurn_ = browseTurn(
      'card-4',
      seen: <String>['card-1', 'card-2', 'card-3'],
    );
    await open.controller.browseStep(StudyBrowseStep.forward);
    await open.controller.browseStep(StudyBrowseStep.forward);

    expect(open.controller.state.turn?.cardId, 'card-4');
    expect(open.controller.state.browseLookBack, 0);
    expect(open.controller.state.viewedCard?.id, 'card-4');
  });

  test('a round with nothing behind it cannot be stepped back', () async {
    final open = await openBrowse();

    expect(open.controller.state.canLookBack, isFalse);

    await open.controller.browseStep(StudyBrowseStep.back);

    expect(open.controller.state.isLookingBack, isFalse);
    expect(open.controller.state.viewedCard?.id, 'card-3');
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

    final controller = container.read(
      studySessionControllerProvider('deck-1').notifier,
    );
    await controller.start(
      kind: StudySessionKind.reviewing,
      reviewMode: StudyMode.match,
    );

    await controller.browseStep(StudyBrowseStep.back);

    expect(controller.state.isLookingBack, isFalse);
  });

  group('the gesture', () {
    /// Drags the card [dx] pixels and lets go.
    Future<void> drag(WidgetTester tester, double dx) async {
      await tester.drag(find.text('card'), Offset(dx, 0));
      await tester.pumpAndSettle();
    }

    Future<({List<String> events})> pumpDeck(
      WidgetTester tester, {
      bool canGoBack = true,
      bool isLocked = false,
    }) async {
      final events = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          StudySwipeDeckWidget(
            cardKey: 'card-1',
            canGoBack: canGoBack,
            isLocked: isLocked,
            onForward: () => events.add('forward'),
            onBack: () => events.add('back'),
            child: const SizedBox(height: 300, child: Text('card')),
          ),
        ),
      );

      return (events: events);
    }

    testWidgets('a drag left past the threshold moves forward', (tester) async {
      final deck = await pumpDeck(tester);

      await drag(tester, -(kStudySwipeThreshold + 20));

      expect(deck.events, <String>['forward']);
    });

    testWidgets('a drag right past the threshold steps back', (tester) async {
      final deck = await pumpDeck(tester);

      await drag(tester, kStudySwipeThreshold + 20);

      expect(deck.events, <String>['back']);
    });

    testWidgets('a drag short of the threshold does neither', (tester) async {
      // The card scrolls its own halves at a large text scale, and a hair
      // trigger would turn a mis-aimed scroll into a card change.
      final deck = await pumpDeck(tester);

      await drag(tester, kStudySwipeThreshold - 10);
      await drag(tester, -(kStudySwipeThreshold - 10));

      expect(deck.events, isEmpty);
    });

    testWidgets('a drag back with nothing behind is refused, not silent', (
      tester,
    ) async {
      final deck = await pumpDeck(tester, canGoBack: false);

      await drag(tester, kStudySwipeThreshold + 20);

      expect(deck.events, isEmpty);
      // And the card is back where it started, which is what tells the user the
      // gesture was heard and declined.
      expect(tester.getRect(find.text('card')).left, closeTo(0, 1));
    });

    testWidgets('while a write is in flight the gesture commits nothing', (
      tester,
    ) async {
      // BR-25: the card stays put and the controls stop responding. It still
      // moves under the finger — refusing to move reads as a dropped gesture.
      final deck = await pumpDeck(tester, isLocked: true);

      await drag(tester, -(kStudySwipeThreshold + 40));

      expect(deck.events, isEmpty);
    });
  });

  group('the screen-reader path', () {
    /// The custom actions a `Semantics` node offers: label to action id.
    Map<String, int> actionsOf(WidgetTester tester) {
      final node = tester.getSemantics(find.byType(StudySwipeDeckWidget));
      final ids = node.getSemanticsData().customSemanticsActionIds ?? <int>[];

      return <String, int>{
        for (final id in ids)
          CustomSemanticsAction.getAction(id)!.label ?? '?': id,
      };
    }

    /// Fires one, the way a screen reader does.
    void invoke(WidgetTester tester, int id) {
      final node = tester.getSemantics(find.byType(StudySwipeDeckWidget));
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.customAction,
          nodeId: node.id,
          viewId: tester.view.viewId,
          arguments: id,
        ),
      );
    }

    Future<Map<String, int>> pumpAndRead(
      WidgetTester tester, {
      required bool canGoBack,
      required List<String> events,
    }) async {
      await tester.pumpWidget(
        wrapForTest(
          StudySwipeDeckWidget(
            cardKey: 'card-1',
            canGoBack: canGoBack,
            onForward: () => events.add('forward'),
            onBack: () => events.add('back'),
            child: const SizedBox(height: 300, child: Text('card')),
          ),
        ),
      );

      return actionsOf(tester);
    }

    testWidgets('both moves are offered when there is a trail', (tester) async {
      // **Removing the buttons made this the only way through** for anyone who
      // cannot make a 70dp horizontal drag. Nothing else in the suite would
      // notice it disappearing: the screen renders identically without it.
      final handle = tester.ensureSemantics();
      final events = <String>[];

      final actions = await pumpAndRead(
        tester,
        canGoBack: true,
        events: events,
      );

      expect(actions.keys.toSet(), <String>{'Next', 'Previous card'});

      // Labelled *and* wired. A label pointing at the wrong callback is the
      // failure a label-only assertion cannot see.
      invoke(tester, actions['Previous card']!);
      invoke(tester, actions['Next']!);
      expect(events, <String>['back', 'forward']);

      handle.dispose();
    });

    testWidgets('back is not offered when there is nothing behind', (
      tester,
    ) async {
      // Same reason a disabled button would have been wrong: an action that
      // does nothing is worse than an action that is not there.
      final handle = tester.ensureSemantics();
      final events = <String>[];

      final actions = await pumpAndRead(
        tester,
        canGoBack: false,
        events: events,
      );

      expect(actions.keys.toList(), <String>['Next']);
      handle.dispose();
    });
  });
}
