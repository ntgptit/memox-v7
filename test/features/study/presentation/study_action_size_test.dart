import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/presentation/widgets/sections/fill_answer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/fill_harness.dart';
import 'support/recall_turn_fixture.dart';
import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// Which `MxActionButtonSize` each study action wears.
///
/// The single verb a turn ends with is the handoff's "study action" pill; the
/// equal-weight `secondary` pairs stay `standard`, where 2 x 36 of padding
/// would eat a shared row at 320dp. The geometry itself is pinned in
/// `mx_action_button_study_test.dart`; this pins who uses it.
void main() {
  group('study actions', () {
    testWidgets('Show answer, Next and Retry are study pills', (tester) async {
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) => write.future,
          ),
          isScrollable: false,
        ),
      );

      expect(_buttonOf(tester, 'Show answer').size, MxActionButtonSize.study);

      // Clock runs out with the write still open: the disabled Continue.
      await tester.pump(kRecallTurnLimit);
      await tester.pump();
      final MxActionButton pending = _buttonOf(tester, 'Next');
      expect(pending.onPressed, isNull);
      expect(pending.size, MxActionButtonSize.study);

      write.refuse();
      await tester.pumpAndSettle();
      expect(_buttonOf(tester, 'Retry').size, MxActionButtonSize.study);
    });

    testWidgets('Next after a recorded timeout is a study pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) async => commitOf('c1'),
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();

      final MxActionButton next = _buttonOf(tester, 'Next');
      expect(next.onPressed, isNotNull);
      expect(next.size, MxActionButtonSize.study);
    });

    testWidgets('Forgot and Remembered stay standard', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) async => commitOf('c1'),
          ),
          isScrollable: false,
        ),
      );
      await tester.tap(find.text('Show answer'));
      await tester.pump(const Duration(milliseconds: 300));

      for (final String label in <String>['Forgot', 'Remembered']) {
        expect(
          _buttonOf(tester, label).size,
          MxActionButtonSize.standard,
          reason: label,
        );
      }
    });

    testWidgets('Check is a study pill; Show hint stays standard', (
      tester,
    ) async {
      await pumpFill(tester, fillTurnOf('c1', hint: 'gợi ý'));

      expect(_buttonOf(tester, 'Check').size, MxActionButtonSize.study);
      expect(_buttonOf(tester, 'Show hint').size, MxActionButtonSize.standard);
    });

    testWidgets('Check beside Show hint does not overflow at 320dp', (
      tester,
    ) async {
      // The 36-padded pill shares a row with the hint: it must reflow (the
      // pair stacks) rather than overflow, at the narrowest width the study
      // suite pumps and at a doubled text scale.
      for (final double scale in <double>[1, 2]) {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          wrapForTest(
            FillAnswerSectionWidget(
              turn: fillTurnOf('c1', hint: 'gợi ý'),
              onGraded: (_) async => commitOf('c1'),
            ),
            isScrollable: false,
            locale: const Locale('vi'),
            textScaler: TextScaler.linear(scale),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull, reason: 'scale $scale');
      }
    });
  });
}

MxActionButton _buttonOf(WidgetTester tester, String label) =>
    tester.widget<MxActionButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(MxActionButton),
      ),
    );
