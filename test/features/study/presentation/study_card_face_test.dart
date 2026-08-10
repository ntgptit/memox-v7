import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_card_face_section_widget.dart';

import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/study_commit_stub.dart';
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
    progress: const StudyStageProgressModel(
      round: 1,
      done: 0,
      total: 1,
      completedCardIds: <String>[],
    ),
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
    StudyFaceEmphasis emphasis = StudyFaceEmphasis.promptFirst,
    bool isLocked = false,
    Future<StudyAnswerCommitModel?> Function(StudyAction)? onAction,
    VoidCallback? onContinue,
    String cardId = 'c1',
  }) => tester.pumpWidget(
    wrapForTest(
      StudyCardFaceSectionWidget(
        turn: turnOf(cardId),
        actions: actions,
        onAction: onAction ?? (_) async => commitOf('c'),
        onContinue: onContinue ?? () {},
        shouldShowBackImmediately: shouldShowBackImmediately,
        emphasis: emphasis,
        isLocked: isLocked,
      ),
      // **Not scrollable, because that is the production condition.** The card
      // takes the whole height the frame gives it (§3), so an unbounded parent
      // is not a gentler test — it is a different widget.
      isScrollable: false,
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
      // No flip, nothing to grade, and no control either: `browse` writes no
      // history row at all, and moving on is the swipe (BR-155).
      expect(find.text('Show answer'), findsNothing);
      expect(find.text('Remembered'), findsNothing);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('the halves are labelled by column, not by content', (
      tester,
    ) async {
      // `front` is not guaranteed to be a term and `back` is not guaranteed to
      // be a meaning — a deck may hold the meaning on the front — so the old
      // Term/Meaning pair mislabelled both halves of such a card. The label
      // names the column it draws.
      await pump(
        tester,
        actions: const <StudyAction>[],
        shouldShowBackImmediately: true,
        emphasis: StudyFaceEmphasis.backSupportingFront,
      );

      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);
      for (final stale in <String>['TERM', 'MEANING', 'KOREAN']) {
        expect(find.text(stale), findsNothing);
      }
    });

    testWidgets('the front leads and the back explains (BR-08, BR-112)', (
      tester,
    ) async {
      // **BR-08 fixes the direction.** The front is capped at 60 characters
      // because it is the prompt; the back at 240 because a meaning carries two
      // languages. So the term takes the title role and the meaning a body one
      // — a role that holds 240 characters without shouting.
      await pump(
        tester,
        actions: const <StudyAction>[],
        shouldShowBackImmediately: true,
        emphasis: StudyFaceEmphasis.backSupportingFront,
      );

      final texts = Theme.of(
        tester.element(find.byType(MxCard).first),
      ).textTheme;
      final front = tester.widget<Text>(find.text('front-c1'));
      final back = tester.widget<Text>(find.text('back-c1'));

      expect(front.style?.fontSize, texts.titleLarge?.fontSize);
      expect(front.style?.fontWeight, FontWeight.w500);
      expect(back.style?.fontSize, texts.bodyLarge?.fontSize);
      expect(back.style?.fontWeight, FontWeight.w400);
      expect(
        front.style?.fontSize,
        greaterThan(back.style!.fontSize!),
        reason: 'the term is the focal face; the meaning explains it',
      );
    });

    testWidgets('promptFirst keeps the front larger than the back', (
      tester,
    ) async {
      // `self_assess`, unchanged by any of this: there the front *is* the
      // question until the flip, and it must not inherit `browse`'s hierarchy.
      // This is the assertion that makes the parameter worth its name.
      await pump(
        tester,
        actions: const <StudyAction>[StudyAction.remembered],
        shouldShowBackImmediately: true,
      );

      final front = tester.widget<Text>(find.text('front-c1'));
      final back = tester.widget<Text>(find.text('back-c1'));

      expect(front.style?.fontSize, greaterThan(back.style!.fontSize!));
    });

    testWidgets('browse draws no control at all (BR-111, BR-155)', (
      tester,
    ) async {
      // Moving between cards is the swipe, so a Next button beside it was a
      // second way to do the one thing the gesture already does — while taking
      // a band of screen from the card, which is the whole content of this
      // mode. The screen-reader path is a pair of custom semantics actions on
      // the swipe, asserted where the swipe is.
      await pump(
        tester,
        actions: const <StudyAction>[],
        shouldShowBackImmediately: true,
      );

      expect(find.text('Next'), findsNothing);
      expect(find.bySemanticsLabel('Previous card'), findsNothing);
      expect(find.byType(MxActionButton), findsNothing);
    });

    testWidgets('an earlier card is drawn in place of the turn-s (BR-155)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyCardFaceSectionWidget(
            turn: turnOf('c1'),
            viewedCard: const StudyCardModel(
              id: 'c0',
              front: 'front-c0',
              back: 'back-c0',
              example: null,
              hint: null,
              pronunciation: null,
              backFolded: 'back-c0',
            ),
            actions: const <StudyAction>[],
            onAction: (_) async => null,
            onContinue: () {},
            shouldShowBackImmediately: true,
          ),
          isScrollable: false,
        ),
      );

      expect(find.text('front-c0'), findsOneWidget);
      expect(find.text('front-c1'), findsNothing);
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
        onAction: (action) async {
          tapped.add(action);
          return commitOf('c');
        },
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
          onAction: (_) async => null,
          onContinue: () {},
          shouldShowBackImmediately: true,
        ),
        brightness: Brightness.dark,
        isScrollable: false,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('the card takes the height it is given, split down the middle', (
    tester,
  ) async {
    // **§3: one card filling the whole height, halved by a hairline.** It read
    // as a 188px card in an 852px frame with four hundred pixels of nothing
    // under the controls, because an earlier pass dropped the `Flexible` to get
    // a test to compile and wrote the loss down as "the card keeps its natural
    // height". Measured here so the next such trade fails instead of shipping.
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          height: 700,
          child: StudyCardFaceSectionWidget(
            turn: turnOf('c1'),
            actions: const <StudyAction>[],
            onAction: (_) async => null,
            onContinue: () {},
            shouldShowBackImmediately: true,
          ),
        ),
        isScrollable: false,
      ),
    );

    final card = tester.getRect(find.byType(MxCard));
    expect(
      card.height,
      greaterThan(700 * 0.7),
      reason: 'the card is hugging its content again; it was ${card.height}',
    );

    // The hairline is the middle, not a gap after the first block.
    final divider = tester.getRect(find.byType(Divider));
    expect(divider.center.dy, closeTo(card.center.dy, 24));

    // **And it reaches both sides of the card.** The halves own their top and
    // bottom insets so that the card only pads its sides — which is what lets
    // the rule run the full inner width and read as a fold. Under one uniform
    // inset the rule stopped short at both ends and the halves read as two
    // cards stacked. Measured, because nothing else here would notice.
    expect(divider.width, closeTo(card.width - AppSpacing.lg * 2, 1));

    // And each side is centred in its own half, which is what makes the two
    // read as sides of one card rather than a heading and a paragraph.
    final front = tester.getRect(find.text('front-c1'));
    expect(front.center.dy, closeTo((card.top + divider.center.dy) / 2, 40));
  });

  testWidgets('before the flip the single half is centred in the whole card', (
    tester,
  ) async {
    // The short inset exists to bring the term close to the rule. With no rule
    // on screen it only pushed the term off centre, which is the branch the
    // measured test above cannot see because it always reveals the back.
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          height: 700,
          child: StudyCardFaceSectionWidget(
            turn: turnOf('c1'),
            actions: eightBox,
            onAction: (_) async => null,
            onContinue: () {},
          ),
        ),
        isScrollable: false,
      ),
    );

    expect(find.byType(Divider), findsNothing);
    final card = tester.getRect(find.byType(MxCard));
    final front = tester.getRect(find.text('front-c1'));
    expect(front.center.dy, closeTo(card.center.dy, 8));
  });
}
