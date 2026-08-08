import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_scheduler.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_card_face_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart';

import '../../../support/color_math.dart';
import 'support/study_widget_harness.dart';

/// What the Study screens owe somebody who is not looking at them, or not
/// looking closely (M5.16).
///
/// **Both brightnesses on every claim.** A contrast pair that passes in light
/// and fails in dark is the single most common way this project's UI has broken,
/// and it is invisible to a test that renders one of them.
void main() {
  StudyTurnModel turnOf({String back = 'apple'}) => StudyTurnModel(
    item: const StudyQueueItemEntity(
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
    ),
    card: StudyCardModel(
      id: 'c1',
      front: '사과',
      back: back,
      example: null,
      hint: null,
      pronunciation: null,
      backFolded: back,
    ),
    progress: const StudyStageProgressModel(round: 1, done: 2, total: 5),
  );

  /// The frame under the gutter its screen gives it.
  ///
  /// **The padding is not decoration here.** `MxContentShell` applies it in
  /// production, and without it the hint line sits flush against the bottom edge
  /// of the test surface — where the contrast guideline samples pixels that are
  /// half the line and half whatever is past it, and reports a ratio no user
  /// would ever see.
  Widget frame(StudyMode mode, Widget child) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: StudySessionFrameSectionWidget(
      mode: mode,
      kind: StudySessionKind.learning,
      deckName: 'Korean',
      progress: const StudyStageProgressModel(round: 1, done: 2, total: 5),
      onClose: () {},
      child: child,
    ),
  );

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('every colour the frame writes text in passes AA in $theme', (
      tester,
    ) async {
      // **Measured from the tokens, not from `textContrastGuideline`.** That
      // guideline samples the rendered pixels of a semantics node, and on a
      // 14px light-weight line most glyph pixels are partially covered: it
      // reported 1.92:1 in light on a pair that measures 6.3:1, and 3.90:1 in
      // dark on a pair that measures 7.3:1. A number nobody can see is not a
      // number to gate on — this repo's own audit rules say the same thing
      // where they send a caller to the raster instead.
      await tester.pumpWidget(
        wrapForTest(
          frame(StudyMode.match, const Text('body')),
          brightness: brightness,
          isScrollable: false,
        ),
      );

      final element = tester.element(
        find.byType(StudySessionFrameSectionWidget),
      );
      final scheme = Theme.of(element).colorScheme;
      final semantic = Theme.of(element).extension<AppSemanticColors>()!;

      // The context line and the hint line: the two the frame writes itself.
      expect(
        contrast(scheme.onSurfaceVariant, scheme.surface),
        greaterThanOrEqualTo(_kAaBodyText),
      );
      // The counter and the clock.
      expect(
        contrast(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(_kAaBodyText),
      );
      // The mode pill: `primaryAccent` on `surfaceMuted`, and §7.8's whole
      // argument is that this pair is the one the project already owns.
      expect(
        contrast(semantic.primaryAccent, semantic.surfaceMuted),
        greaterThanOrEqualTo(_kAaBodyText),
      );
    });

    testWidgets('the ✕ and the four sm2 actions are reachable in $theme', (
      tester,
    ) async {
      // BR-30's larger action set is the hard case: `sm2` renders four buttons
      // where `eight_box` renders two, and a column that shrank them to fit
      // would fail exactly here.
      final actions = schedulerFor(SchedulerType.sm2)!.supportedActions;
      expect(actions, hasLength(4));

      await tester.pumpWidget(
        wrapForTest(
          frame(
            StudyMode.selfAssess,
            SingleChildScrollView(
              child: StudyCardFaceSectionWidget(
                turn: turnOf(),
                actions: actions,
                onAction: (_) {},
                onContinue: () {},
                shouldShowBackImmediately: true,
              ),
            ),
          ),
          brightness: brightness,
          isScrollable: false,
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });
  }

  testWidgets('the recall clock is announced, not merely coloured', (
    tester,
  ) async {
    // BR-128's twenty seconds is the only thing on the top bar that changes
    // while a card is on screen. A figure a screen reader reads as "12" says
    // nothing about what it counts.
    final clock = ValueNotifier<Duration>(const Duration(seconds: 12));
    addTearDown(clock.dispose);

    await tester.pumpWidget(
      wrapForTest(
        StudySessionFrameSectionWidget(
          mode: StudyMode.recall,
          kind: StudySessionKind.learning,
          deckName: 'Korean',
          progress: const StudyStageProgressModel(round: 1, done: 2, total: 5),
          timeLeft: clock,
          onClose: () {},
          child: const Text('body'),
        ),
        isScrollable: false,
      ),
    );

    expect(find.text('12s left'), findsOneWidget);
  });

  testWidgets('the counter is announced with what it counts', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        frame(StudyMode.guess, const Text('body')),
        isScrollable: false,
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Round progress'));
    expect(node.value, '2 / 5');
  });

  testWidgets('the whole frame survives 320x568 at double text scale', (
    tester,
  ) async {
    // The four `sm2` buttons under a frame, on the smallest screen the project
    // supports, at the largest scale — the case that overflows if anything does.
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapForTest(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: frame(
            StudyMode.selfAssess,
            SingleChildScrollView(
              child: StudyCardFaceSectionWidget(
                turn: turnOf(back: 'quả táo đỏ trên bàn ăn sáng nay'),
                actions: schedulerFor(SchedulerType.sm2)!.supportedActions,
                onAction: (_) {},
                onContinue: () {},
                shouldShowBackImmediately: true,
              ),
            ),
          ),
        ),
        isScrollable: false,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

/// WCAG 2.1 AA for body text.
const double _kAaBodyText = 4.5;
