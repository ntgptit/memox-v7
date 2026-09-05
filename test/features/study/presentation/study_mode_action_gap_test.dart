import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/items/guess_option_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/fill_answer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/guess_question_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_card_face_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_swipe_deck_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'support/fill_harness.dart';
import 'support/recall_turn_fixture.dart';
import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// The one seam every study mode has: the content region, then the thing you
/// act on.
///
/// **One question asked of all five modes at once, deliberately** (SC-C2-10).
/// The screen used to answer it five different ways — `browse` 8, `guess` 12,
/// `recall` and `fill` 16, `self_assess` 24 — because each mode was built as
/// its own file and nothing put the five numbers side by side. Nothing about
/// the modes distinguishes them for this purpose: every one of them is "the
/// card or the board, then the control under it".
///
/// The answer is `AppSpacing.lg`, and it is not a fresh choice — it is what
/// `study_session_frame_section_widget.dart` already puts above and below this
/// whole band, so the mode bodies now agree with the frame that wraps them.
///
/// **Parameterised so a sixth mode cannot be added without answering it.**
/// Five separate tests would have let `match` arrive with a sixth number and no
/// test to fail; a table makes the omission the visible thing.
void main() {
  /// A mode body, the widget that ends its content region, and the first
  /// control under the seam.
  ///
  /// The finders are lazy, so they are declared with the case and resolved
  /// after its pump.
  ({
    String mode,
    Future<void> Function(WidgetTester tester) pump,
    Finder content,
    Finder control,
  })
  seam({
    required String mode,
    required Future<void> Function(WidgetTester tester) pump,
    required Finder content,
    required Finder control,
  }) => (mode: mode, pump: pump, content: content, control: control);

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

  StudyTurnModel turnOf(StudyCardModel subject, StudyMode mode) =>
      StudyTurnModel(
        item: StudyQueueItemEntity(
          sessionId: 's1',
          mode: mode,
          round: 1,
          cardId: subject.id,
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
          total: 5,
          completedCardIds: <String>[],
        ),
        card: subject,
      );

  final pool = <StudyCardModel>[for (var i = 0; i < 10; i++) cardOf('c$i')];
  final question = const GuessModeHandler().buildQuestion(
    term: pool.first,
    pool: pool,
    random: Random(2),
  )!;

  /// `browse` hands its card in from the frame, so the test supplies one that
  /// fills the deck's `Expanded` — otherwise the child's own intrinsic height
  /// is measured instead of the content region's bottom edge.
  const browseBody = ValueKey<String>('browse-body');

  final seams =
      <
        ({
          String mode,
          Future<void> Function(WidgetTester tester) pump,
          Finder content,
          Finder control,
        })
      >[
        seam(
          mode: 'browse',
          pump: (tester) => tester.pumpWidget(
            wrapForTest(
              StudySwipeDeckWidget(
                cardKey: 'c1',
                canGoBack: true,
                onForward: () {},
                onBack: () {},
                child: const SizedBox.expand(
                  key: browseBody,
                  child: Text('card'),
                ),
              ),
              isScrollable: false,
            ),
          ),
          content: find.byKey(browseBody),
          control: find.byType(MxIconButton).first,
        ),
        seam(
          mode: 'self_assess',
          pump: (tester) => tester.pumpWidget(
            wrapForTest(
              StudyCardFaceSectionWidget(
                turn: turnOf(pool.first, StudyMode.selfAssess),
                actions: const <StudyAction>[
                  StudyAction.forgotten,
                  StudyAction.remembered,
                ],
                onAction: (_) async => commitOf('c0'),
                onContinue: () {},
                shouldShowBackImmediately: true,
              ),
              isScrollable: false,
            ),
          ),
          content: find.byType(MxCard),
          control: find.byType(MxActionButton).first,
        ),
        seam(
          mode: 'recall',
          pump: (tester) => tester.pumpWidget(
            wrapForTest(
              RecallTimerSectionWidget(
                turn: recallTurn('c1'),
                onOutcome: (_) async => commitOf('c1'),
              ),
              isScrollable: false,
            ),
          ),
          // The prompt card, then the recessed answer area: the seam is under the
          // second of the two.
          content: find.byType(MxCard).last,
          control: find.byType(MxActionButton).first,
        ),
        seam(
          mode: 'fill',
          pump: (tester) => tester.pumpWidget(
            wrapForTest(
              FillAnswerSectionWidget(
                turn: fillTurnOf('c1'),
                onGraded: (_) async => commitOf('c1'),
              ),
              isScrollable: false,
            ),
          ),
          content: fillAnswerCard(),
          control: find.byType(StudyCtaRowWidget),
        ),
        seam(
          mode: 'guess',
          pump: (tester) => tester.pumpWidget(
            wrapForTest(
              GuessQuestionSectionWidget(
                question: question,
                turn: turnOf(pool.first, StudyMode.guess),
                onChosen: (_) async => commitOf('c0'),
              ),
              isScrollable: false,
            ),
          ),
          content: find.byType(MxCard),
          control: find.byType(GuessOptionItemWidget).first,
        ),
      ];

  group('content to action, across the five modes', () {
    for (final seam in seams) {
      testWidgets('${seam.mode} separates its two regions by lg', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await seam.pump(tester);

        final content = tester.getRect(seam.content);
        final control = tester.getRect(seam.control);

        expect(
          control.top - content.bottom,
          closeTo(AppSpacing.lg, 0.01),
          reason:
              '${seam.mode}: content ends at ${content.bottom}, the first '
              'control starts at ${control.top}. The five modes ask one '
              'question and must answer it with one number (SC-C2-10).',
        );
      });
    }
  });

  group('the guess clamp under the seam', () {
    testWidgets('320x568 at double text still floors the card, not the rows', (
      tester,
    ) async {
      // **Measured rather than reasoned about** (SC-C2-10's risk note). The
      // card's height is `maxHeight - gap - what the rows need`, clamped
      // between 180 and 320, so widening the gap takes its 4dp off the card —
      // invisible on a phone, where the clamp is already at its ceiling, and
      // decisive on the one viewport where the card is at its floor and the
      // rows are what give way.
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: question,
            turn: turnOf(pool.first, StudyMode.guess),
            onChosen: (_) async => commitOf('c0'),
          ),
          isScrollable: false,
          textScaler: const TextScaler.linear(2),
        ),
      );

      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byType(MxCard));
      expect(
        card.height,
        greaterThanOrEqualTo(AppGuessPrompt.cardMinHeight - 0.01),
        reason: 'the gap must not push the prompt below its own floor',
      );

      // And the seam itself holds at the width where the layout is tightest.
      final option = tester.getRect(find.byType(GuessOptionItemWidget).first);
      expect(option.top - card.bottom, closeTo(AppSpacing.lg, 0.01));
    });
  });
}
