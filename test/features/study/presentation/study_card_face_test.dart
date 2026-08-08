import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_card_face_section_widget.dart';

import 'support/study_widget_harness.dart';

/// `browse` and `self_assess`, which differ by exactly one thing (BR-112).
void main() {
  StudyTurnModel turnOf(String id) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 's1',
      mode: StudyMode.selfAssess,
      round: 1,
      cardId: id,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
    ),
    progress: const StudyStageProgressModel(done: 0, total: 1),
    card: StudyCardModel(
      id: id,
      front: 'front-$id',
      back: 'back-$id',
      example: null,
      hint: null,
      pronunciation: null,
      backFolded: 'back-$id',
    ),
  );

  const eightBox = <StudyAction>[StudyAction.forgotten, StudyAction.remembered];
  const sm2 = <StudyAction>[
    StudyAction.again,
    StudyAction.hard,
    StudyAction.good,
    StudyAction.easy,
  ];

  Future<void> pump(
    WidgetTester tester, {
    required List<StudyAction> actions,
    bool shouldShowBackImmediately = false,
    bool isLocked = false,
    void Function(StudyAction)? onAction,
    VoidCallback? onContinue,
    String cardId = 'c1',
  }) => tester.pumpWidget(
    wrapForTest(
      StudyCardFaceSectionWidget(
        turn: turnOf(cardId),
        actions: actions,
        onAction: onAction ?? (_) {},
        onContinue: onContinue ?? () {},
        shouldShowBackImmediately: shouldShowBackImmediately,
        isLocked: isLocked,
      ),
    ),
  );

  group('browse', () {
    testWidgets('shows both sides at once and offers no action (BR-111)', (
      tester,
    ) async {
      await pump(
        tester,
        actions: const <StudyAction>[],
        shouldShowBackImmediately: true,
      );

      expect(find.text('front-c1'), findsOneWidget);
      expect(find.text('back-c1'), findsOneWidget);
      // No flip, and nothing to grade: `browse` writes no history row at all.
      expect(find.text('Show answer'), findsNothing);
      expect(find.text('Remembered'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    });
  });

  group('self_assess', () {
    testWidgets('hides the back until it is revealed (BR-112)', (tester) async {
      await pump(tester, actions: eightBox);

      expect(find.text('front-c1'), findsOneWidget);
      expect(find.text('back-c1'), findsNothing);
      expect(find.text('Remembered'), findsNothing);

      await tester.tap(find.text('Show answer'));
      await tester.pump();

      expect(find.text('back-c1'), findsOneWidget);
      expect(find.text('Remembered'), findsOneWidget);
    });

    testWidgets('renders two buttons for eight_box and four for sm2 (BR-30)', (
      tester,
    ) async {
      await pump(tester, actions: eightBox, shouldShowBackImmediately: true);
      expect(find.text('Forgot'), findsOneWidget);
      expect(find.text('Remembered'), findsOneWidget);
      expect(find.text('Good'), findsNothing);

      await pump(tester, actions: sm2, shouldShowBackImmediately: true);
      for (final label in <String>['Again', 'Hard', 'Good', 'Easy']) {
        expect(find.text(label), findsOneWidget);
      }
      // A screen holding its own list would be wrong for one algorithm or the
      // other, always.
      expect(find.text('Remembered'), findsNothing);
    });

    testWidgets('the next card arrives face down', (tester) async {
      // Without resetting on a new card, every card after the first shows its
      // answer before the user has tried to remember it.
      await pump(tester, actions: eightBox);
      await tester.tap(find.text('Show answer'));
      await tester.pump();
      expect(find.text('back-c1'), findsOneWidget);

      await pump(tester, actions: eightBox, cardId: 'c2');

      expect(find.text('back-c2'), findsNothing);
      expect(find.text('Show answer'), findsOneWidget);
    });

    testWidgets('while writing, the card stays and the buttons lock', (
      tester,
    ) async {
      final tapped = <StudyAction>[];
      await pump(
        tester,
        actions: eightBox,
        shouldShowBackImmediately: true,
        isLocked: true,
        onAction: tapped.add,
      );

      // BR-25: the content must not vanish between the tap and the next card.
      expect(find.text('front-c1'), findsOneWidget);

      await tester.tap(find.text('Remembered'));
      await tester.pump();

      expect(tapped, isEmpty);
    });
  });

  testWidgets('renders in dark mode without overflowing a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      wrapForTest(
        StudyCardFaceSectionWidget(
          turn: turnOf('c1'),
          actions: sm2,
          onAction: (_) {},
          onContinue: () {},
          shouldShowBackImmediately: true,
        ),
        brightness: Brightness.dark,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
