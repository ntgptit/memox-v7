import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/sections/fill_answer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/fill_harness.dart';
import 'support/recall_turn_fixture.dart';
import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// The verdict pair under the study cards, at the sizes that used to break it.
///
/// **Here rather than in `mx_stress_specimens.dart`** (SC-C7-04). That file
/// says in its own first line that it holds "every shared component", and it
/// imports nothing from `lib/features/`; a mode body is not a shared component,
/// and putting one there would make the set's promise untrue in order to borrow
/// its runner. What the stress suite contributes is the *method* — the real
/// widget, a real theme, Vietnamese copy, a 320dp line and a doubled text
/// scale — and that transfers without the file.
///
/// **What it is protecting.** `StudyCtaRowWidget` was a hand-built `Row` that
/// re-implemented `MxButtonPair` and diverged from it twice: `AppSpacing.md`
/// between the halves where every other pair in the app uses `AppSpacing.sm`,
/// and no stacked fallback at all — so at `textScaler` 2.0 the two verdicts
/// stayed side by side at 138dp each and wrapped `Remembered` over three lines.
/// Both halves of that are now the shared widget's business, which is exactly
/// why this file exists: a future edit that reaches for a `Row` again would
/// look reasonable, and only a measurement says it is not.
void main() {
  /// The two cells that broke, plus the one that must not move: at 1.0 the
  /// pair still draws a row, and at 393dp it draws the row the goldens show.
  const cases = <({String name, double width, Locale? locale, double scale})>[
    (name: 'en 320dp x1.0', width: 320, locale: null, scale: 1),
    (name: 'en 320dp x1.3', width: 320, locale: null, scale: 1.3),
    (name: 'en 320dp x2.0', width: 320, locale: null, scale: 2),
    (name: 'vi 320dp x2.0', width: 320, locale: Locale('vi'), scale: 2),
    (name: 'vi 360dp x2.0', width: 360, locale: Locale('vi'), scale: 2),
    (name: 'vi 393dp x2.0', width: 393, locale: Locale('vi'), scale: 2),
  ];

  /// Pumps `recall`'s self-assessment face: the countdown, then the reveal that
  /// turns one action into the verdict pair.
  Future<void> pumpSelfAssessment(
    WidgetTester tester, {
    required Locale? locale,
    required double scale,
  }) async {
    await tester.pumpWidget(
      wrapForTest(
        RecallTimerSectionWidget(
          turn: recallTurn('c1'),
          onOutcome: (_) async => commitOf('c1'),
        ),
        isScrollable: false,
        locale: locale,
        textScaler: TextScaler.linear(scale),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(MxActionButton).first);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> pumpFill(
    WidgetTester tester, {
    required Locale? locale,
    required double scale,
  }) async {
    await tester.pumpWidget(
      wrapForTest(
        FillAnswerSectionWidget(
          turn: fillTurnOf('c1'),
          onGraded: (_) async => commitOf('c1'),
        ),
        isScrollable: false,
        locale: locale,
        textScaler: TextScaler.linear(scale),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('the verdict pair', () {
    for (final testCase in cases) {
      testWidgets('${testCase.name}: both halves are one size', (tester) async {
        tester.view.physicalSize = Size(testCase.width, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await pumpSelfAssessment(
          tester,
          locale: testCase.locale,
          scale: testCase.scale,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(MxButtonPair), findsOneWidget);

        final first = tester.getRect(find.byType(MxActionButton).at(0));
        final second = tester.getRect(find.byType(MxActionButton).at(1));

        // The pair's whole promise, and the one this screen used to keep only
        // by accident: two verdicts drawn at two sizes read as a
        // recommendation the app never meant to make.
        expect(second.width, first.width);
        expect(second.height, first.height);
      });
    }

    testWidgets('at 1.0 it is still a row, and still capped', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpSelfAssessment(tester, locale: null, scale: 1);

      final first = tester.getRect(find.byType(MxActionButton).at(0));
      final second = tester.getRect(find.byType(MxActionButton).at(1));

      // Side by side: same row, and the secondary on the left.
      expect(first.top, second.top);
      expect(first.right, lessThan(second.left));
      // `AppSpacing.sm`, which is `MxButtonPair`'s gap — not the `md` this row
      // used to write for itself.
      expect(second.left - first.right, 8);
      // Still capped rather than stretched: two halves of `ctaMaxWidth`.
      expect(second.right - first.left, lessThanOrEqualTo(328));
    });

    testWidgets('at 2.0 it stacks, with the primary on top', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpSelfAssessment(tester, locale: null, scale: 2);

      final secondary = tester.getRect(find.byType(MxActionButton).at(0));
      final primary = tester.getRect(find.byType(MxActionButton).at(1));

      // `Remembered` above `Forgotten`: the answer a learner gives when the
      // card worked should not sit where a mis-tap lands.
      expect(primary.bottom, lessThanOrEqualTo(secondary.top));
      expect(primary.left, secondary.left);

      // The cards give up the height the stack costs, and stay well above the
      // floor the mode declares.
      final card = tester.getRect(find.byType(MxCard).first);
      expect(card.height, greaterThan(160));
    });

    testWidgets('fill draws its action through the same row', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpFill(tester, locale: const Locale('vi'), scale: 2);

      // The shared row, whether it holds one action or two. `fill` used to
      // keep an identical private copy, which is why the row is shared at all.
      expect(find.byType(StudyCtaRowWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
