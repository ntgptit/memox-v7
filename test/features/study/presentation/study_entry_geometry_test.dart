// The gutter the study entry screen actually paints at (SC-C1-13).
//
// **Measured through the real screen, not the section.** The defect was never
// in `StudyEntrySectionWidget` — it was a second `EdgeInsets.all(AppSpacing.lg)`
// wrapped around it inside a shell that had already applied the screen gutter,
// so the content sat at 32 instead of 16 and *widened* to 28 at 320dp where
// every other screen narrows to 12. A section-level test cannot see either
// number, because the padding it is asking about is above it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import '../../../visual_audit/study_audit_harness.dart';
import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

void main() {
  Future<void> pumpEntry(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      studyScreenWith(
        FakeStudyRepository(),
        wrapForTest(
          const StudyEntryScreen(deckId: 'deck-1'),
          isScrollable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The two widths the gutter rule is written against: `AppBreakpoints.compact`
  // is 360, so one case is on each side of it.
  for (final surface in <({Size size, double gutter})>[
    (size: const Size(393, 852), gutter: 16),
    (size: const Size(320, 640), gutter: 12),
  ]) {
    testWidgets(
      'the body sits at the screen gutter at ${surface.size.width.toInt()}dp',
      (tester) async {
        await pumpEntry(tester, surface.size);

        expect(tester.getRect(find.text('New 3')).left, surface.gutter);

        // The buttons stretch, so their width is the same statement made from
        // both edges at once — a gutter applied twice shows up here as 32dp of
        // lost width before it shows up as a left edge anybody notices.
        expect(
          tester.getRect(find.byType(MxActionButton).first).width,
          surface.size.width - 2 * surface.gutter,
        );
      },
    );
  }
}
