import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/study/domain/models/study_entry_summary_model.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';

import '../../../visual_audit/study_audit_harness.dart';
import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// The two counts, at the sizes and in the language that broke them.
///
/// **Measured through the real screen, not the section**, for the reason
/// `study_entry_geometry_test.dart` records: the gutter that decides how much
/// line the row gets is applied above the section, so a section-level pump
/// answers a different question.
///
/// **Vietnamese only, and that is the finding corrected rather than widened**
/// (SC-C7-05). The registry claimed English overflows too; it does not, in any
/// cell measured — `Mới {count}` and `Đến hạn {count}` are simply longer than
/// `New` and `Due`. The cells below are the ones that painted overflow stripes
/// on the previous commit, with the pixel counts they painted:
///
/// | locale | width | counts | overflow |
/// |---|---|---|---|
/// | vi | 360 | three-digit | 7.9px |
/// | vi | 360 | four-digit | 51px |
/// | vi | 393 | four-digit | 18px |
/// | vi | 320 | four-digit | 91px |
///
/// English at 360dp with four-digit counts is kept as the control: it passed
/// before this change and must keep passing, because a fix that makes the
/// English row wrap has changed a layout nobody asked it to change.
void main() {
  Future<void> pumpEntry(
    WidgetTester tester, {
    required double width,
    required Locale? locale,
    required int newCount,
    required int dueCount,
  }) async {
    tester.view.physicalSize = Size(width, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      studyScreenWith(
        FakeStudyRepository()
          ..entrySummary_ = StudyEntrySummaryModel(
            newCount: newCount,
            dueCount: dueCount,
            fillableCount: 2,
            distinctMeanings: 6,
          ),
        wrapForTest(
          const StudyEntryScreen(
            deckId: 'deck-1',
            optionsRouteName: RouteNames.deckStudyOptions,
          ),
          isScrollable: false,
          locale: locale,
          textScaler: const TextScaler.linear(2),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const cells =
      <
        ({
          String name,
          double width,
          Locale? locale,
          int newCount,
          int dueCount,
        })
      >[
        (
          name: 'vi 360dp, three-digit counts',
          width: 360,
          locale: Locale('vi'),
          newCount: 128,
          dueCount: 342,
        ),
        (
          name: 'vi 360dp, four-digit counts',
          width: 360,
          locale: Locale('vi'),
          newCount: 1024,
          dueCount: 2048,
        ),
        (
          name: 'vi 393dp, four-digit counts',
          width: 393,
          locale: Locale('vi'),
          newCount: 1024,
          dueCount: 2048,
        ),
        (
          name: 'vi 320dp, four-digit counts',
          width: 320,
          locale: Locale('vi'),
          newCount: 1024,
          dueCount: 2048,
        ),
        (
          name: 'en 360dp, four-digit counts (control)',
          width: 360,
          locale: null,
          newCount: 1024,
          dueCount: 2048,
        ),
      ];

  group('the entry counts at textScaler 2.0', () {
    for (final cell in cells) {
      testWidgets('${cell.name}: no overflow', (tester) async {
        await pumpEntry(
          tester,
          width: cell.width,
          locale: cell.locale,
          newCount: cell.newCount,
          dueCount: cell.dueCount,
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('English at ordinary scale still draws one line', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        studyScreenWith(
          FakeStudyRepository(),
          wrapForTest(
            const StudyEntryScreen(
              deckId: 'deck-1',
              optionsRouteName: RouteNames.deckStudyOptions,
            ),
            isScrollable: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The `Wrap` must not move the reference render: at 393dp and scale 1.0
      // both counts still share one run, which is what the committed golden
      // and the screen gallery show.
      expect(
        tester.getRect(find.text('3 new', findRichText: true)).top,
        tester.getRect(find.text('4 due', findRichText: true)).top,
      );
    });
  });
}
