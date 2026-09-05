// One gap for a stacked action group in Study (SC-C2-12).
//
// The two ways into a deck and the three ways out of an open session are the
// same widget with the same variants, and two of them are literally the same
// two ARB strings — `studyStartLearning` and `studyStartReview` — one dismiss
// apart on the same route. They were stacked 12dp apart on the screen and 8dp
// apart in the sheet. `app_spacing.dart` gives `md` to the inside of a compact
// control, so `sm` is the value both sites keep.
//
// **Measured at two text scales**, because the gap is a constant `SizedBox`
// between two controls that grow: a value that moved with the scale would mean
// the separation was coming from something else and the constant was decorative.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_resume_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import '../../../visual_audit/study_audit_harness.dart';
import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

void main() {
  /// Every vertical gap between consecutive `MxActionButton`s, top to bottom.
  ///
  /// Sorted by `top` rather than trusted in tree order: the entry screen builds
  /// its two buttons in two separate `if` branches, so a later edit could
  /// reorder them in the tree without reordering them on screen.
  List<double> stackedGaps(WidgetTester tester) {
    final Finder buttons = find.byType(MxActionButton);
    final int count = buttons.evaluate().length;
    final List<Rect> rects = <Rect>[
      for (int i = 0; i < count; i++) tester.getRect(buttons.at(i)),
    ]..sort((Rect a, Rect b) => a.top.compareTo(b.top));
    return <double>[
      for (int i = 1; i < rects.length; i++) rects[i].top - rects[i - 1].bottom,
    ];
  }

  for (final double scale in <double>[1, 2]) {
    testWidgets('the entry screen stacks its two ways in at sm (×$scale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        studyScreenWith(
          FakeStudyRepository(),
          wrapForTest(
            const StudyEntryScreen(deckId: 'deck-1'),
            isScrollable: false,
            textScaler: TextScaler.linear(scale),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MxActionButton), findsNWidgets(2));
      expect(stackedGaps(tester), <double>[AppSpacing.sm]);
    });

    testWidgets('the resume sheet stacks its three ways forward at sm '
        '(×$scale)', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrapForTest(
          StudyResumeWidget(onChoice: (_) {}),
          textScaler: TextScaler.linear(scale),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MxActionButton), findsNWidgets(3));
      expect(stackedGaps(tester), <double>[AppSpacing.sm, AppSpacing.sm]);
    });
  }
}
