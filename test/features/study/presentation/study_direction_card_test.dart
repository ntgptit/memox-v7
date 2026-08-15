import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_card_face_section_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/study_widget_harness.dart';

/// The card when the recall direction is reversed (BR-204).
///
/// The chooser is the other surface the direction touches and lives in
/// `study_direction_chooser_test.dart` — a different widget with a different
/// question, split when this file crossed the guard's 400 lines.
void main() {
  // **BR-08's ceilings, not a comfortable sample.** The front is capped at 60
  // characters and the back at 240, and the reversed card is precisely where the
  // 240 stops being a supporting line and becomes the prompt — at the prompt's
  // larger role. A 44-character fixture never exercised that.
  const korean = '학술적 어휘 평가 시험을 위한 고급 한국어 표현 목록 정리본 자료';
  const meaning =
      'nhà nghiên cứu chuyên sâu, người làm công tác nghiên cứu khoa học tại '
      'viện hàn lâm, chuyên gia phân tích dữ liệu học thuật và biên soạn tài '
      'liệu tham khảo cho chương trình đào tạo sau đại học của nhà trường';

  StudyTurnModel turnOf(StudyRecallDirection? direction) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 's1',
      mode: StudyMode.selfAssess,
      round: 1,
      cardId: 'c1',
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
      direction: direction,
    ),
    progress: const StudyStageProgressModel(
      round: 1,
      done: 0,
      total: 1,
      completedCardIds: <String>[],
    ),
    card: const StudyCardModel(
      id: 'c1',
      front: korean,
      back: meaning,
      example: null,
      hint: null,
      pronunciation: null,
      frontFolded: korean,
      backFolded: meaning,
    ),
  );

  const sm2 = <StudyAction>[
    StudyAction.again,
    StudyAction.hard,
    StudyAction.good,
    StudyAction.easy,
  ];

  Future<void> pumpCard(
    WidgetTester tester, {
    required StudyRecallDirection direction,
    bool isRevealed = false,
    Brightness brightness = Brightness.light,
    Locale? locale,
    TextScaler? textScaler,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapForTest(
        StudyCardFaceSectionWidget(
          turn: turnOf(direction),
          actions: sm2,
          onAction: (_) async => null,
          onContinue: () {},
          shouldShowBackImmediately: isRevealed,
          direction: direction,
        ),
        brightness: brightness,
        locale: locale,
        textScaler: textScaler,
        isScrollable: false,
      ),
    );
  }

  group('the card asks the way the row says (BR-204)', () {
    testWidgets('Korean→Meaning prompts with the Korean', (tester) async {
      await pumpCard(tester, direction: StudyRecallDirection.koreanToMeaning);

      expect(find.text(korean), findsOneWidget);
      expect(find.text(meaning), findsNothing);
      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('Meaning→Korean prompts with the meaning', (tester) async {
      await pumpCard(tester, direction: StudyRecallDirection.meaningToKorean);

      expect(find.text(meaning), findsOneWidget);
      expect(find.text(korean), findsNothing);
      // **The label follows its content.** That is what tells the two directions
      // apart for somebody who cannot see the difference between two blocks of
      // text they cannot read — and it is not a colour.
      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('the reveal is the other face, both ways round', (
      tester,
    ) async {
      await pumpCard(
        tester,
        direction: StudyRecallDirection.koreanToMeaning,
        isRevealed: true,
      );
      var prompt = tester.getRect(find.text(korean));
      var reveal = tester.getRect(find.text(meaning));
      expect(prompt.center.dy, lessThan(reveal.center.dy));

      await pumpCard(
        tester,
        direction: StudyRecallDirection.meaningToKorean,
        isRevealed: true,
      );
      prompt = tester.getRect(find.text(meaning));
      reveal = tester.getRect(find.text(korean));
      expect(
        prompt.center.dy,
        lessThan(reveal.center.dy),
        reason: 'the prompt is always the upper half',
      );
    });

    testWidgets('a row with no direction draws what it always drew', (
      tester,
    ) async {
      // Every session outside BR-203 — the learning chain, `browse`, every
      // `eight_box` deck — reaches the widget with a null row and must be
      // untouched by any of this.
      await tester.pumpWidget(
        wrapForTest(
          StudyCardFaceSectionWidget(
            turn: turnOf(null),
            actions: sm2,
            onAction: (_) async => null,
            onContinue: () {},
          ),
          isScrollable: false,
        ),
      );

      expect(find.text(korean), findsOneWidget);
      expect(find.text('FRONT'), findsOneWidget);
    });
  });

  group('geometry is the same in both directions', () {
    /// The measurements a direction must not move: the card's own rect, the
    /// fold, and the action row under it.
    Future<({Rect card, Rect divider, Rect firstAction})> measure(
      WidgetTester tester,
      StudyRecallDirection direction,
    ) async {
      await pumpCard(tester, direction: direction, isRevealed: true);

      return (
        card: tester.getRect(find.byType(MxCard)),
        divider: tester.getRect(find.byType(Divider)),
        firstAction: tester.getRect(find.byType(MxActionButton).first),
      );
    }

    testWidgets('the card, the fold and the actions do not move', (
      tester,
    ) async {
      // **Pinned rather than eyeballed.** Swapping two strings between two
      // halves is exactly the change that silently resizes one of them, and the
      // symptom — a fold that sits a few pixels off centre in one direction
      // only — is invisible in a screenshot taken one way round.
      final koreanFirst = await measure(
        tester,
        StudyRecallDirection.koreanToMeaning,
      );
      final meaningFirst = await measure(
        tester,
        StudyRecallDirection.meaningToKorean,
      );

      expect(meaningFirst.card, koreanFirst.card);
      expect(meaningFirst.divider, koreanFirst.divider);
      expect(meaningFirst.firstAction, koreanFirst.firstAction);
    });

    testWidgets('the fold stays centred and full width', (tester) async {
      final measured = await measure(
        tester,
        StudyRecallDirection.meaningToKorean,
      );

      // Both halves are `Expanded`, so the fold is the card's exact centre — a
      // 24dp tolerance would have accepted a card split two-thirds of the way
      // down.
      expect(measured.divider.center.dy, closeTo(measured.card.center.dy, 1));

      // **Exactly the inner width, not merely "no wider".** §8.1 settles that
      // the rule runs the full width between the card's side insets — that is
      // what makes it read as a fold rather than a separator dropped between two
      // blocks, and `lessThanOrEqualTo` would pass for a rule half that long.
      expect(
        measured.divider.width,
        closeTo(measured.card.width - AppSpacing.lg * 2, 1),
      );
    });

    testWidgets('the action row clears 48dp, both ways round', (tester) async {
      for (final direction in <StudyRecallDirection>[
        StudyRecallDirection.koreanToMeaning,
        StudyRecallDirection.meaningToKorean,
      ]) {
        await pumpCard(tester, direction: direction, isRevealed: true);

        for (final rect
            in tester
                .widgetList<MxActionButton>(find.byType(MxActionButton))
                .indexed
                .map(
                  (entry) =>
                      tester.getRect(find.byType(MxActionButton).at(entry.$1)),
                )) {
          expect(rect.height, greaterThanOrEqualTo(48));
        }
      }
    });

    testWidgets('BR-08 at its ceilings does not overflow, either way round', (
      tester,
    ) async {
      // Both hard cases, at both supported widths and at a large text scale: a
      // 240-character meaning as the prompt, and a 60-character Korean term as
      // the prompt. The card scrolls inside its half rather than overflowing.
      for (final direction in <StudyRecallDirection>[
        StudyRecallDirection.koreanToMeaning,
        StudyRecallDirection.meaningToKorean,
      ]) {
        for (final size in <Size>[
          const Size(320, 568),
          const Size(390, 844),
          const Size(412, 915),
        ]) {
          await pumpCard(
            tester,
            direction: direction,
            isRevealed: true,
            size: size,
          );
          expect(tester.takeException(), isNull, reason: '$direction at $size');

          await pumpCard(
            tester,
            direction: direction,
            isRevealed: true,
            size: size,
            textScaler: const TextScaler.linear(2),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$direction at $size, scale 2.0',
          );
        }
      }
    });

    testWidgets('dark mode and Vietnamese render without overflow', (
      tester,
    ) async {
      await pumpCard(
        tester,
        direction: StudyRecallDirection.meaningToKorean,
        isRevealed: true,
        brightness: Brightness.dark,
        locale: const Locale('vi'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('MẶT SAU'), findsOneWidget);
    });
  });
}
