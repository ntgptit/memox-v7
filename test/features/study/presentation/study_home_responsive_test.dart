import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../domain/support/fake_study_home_repository.dart';
import 'support/study_home_harness.dart';
import 'package:flutter/rendering.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_workload_item_widget.dart';

/// Study Home at other widths, other locales and other text scales
/// (UC-14, wireframe R1…R3, G13).
///
/// **Vietnamese renders here and nowhere else.** `arb_parity_test.dart` checks
/// that the keys exist; it cannot see what the longer strings do to a layout
/// built for English, and until this file no test set the locale at all.
void main() {
  final english = AppLocalizationsEn();

  late StudyHomeHarness harness;

  setUp(() => harness = StudyHomeHarness());
  tearDown(() => harness.dispose());

  group('across widths and locales', () {
    testWidgets('412dp keeps the anatomy and only widens the column', (
      tester,
    ) async {
      await harness.pump(tester, surface: const Size(412, 892));

      final screen = tester.getRect(find.byType(MaterialApp));
      final row = tester.getRect(find.byType(StudyHomeDeckItemWidget).first);

      expect(row.left - screen.left, AppSpacing.lg);
      expect(screen.right - row.right, AppSpacing.lg);
      expect(find.byType(StudyHomeResumeSectionWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Vietnamese renders every band without overflowing', (
      tester,
    ) async {
      // The locale had never been rendered by any test — ARB parity checks the
      // keys, not what the longer strings do to a layout built for English.
      await harness.pump(tester, locale: const Locale('vi'));

      expect(find.byType(StudyHomeResumeSectionWidget), findsOneWidget);
      expect(find.byType(StudyHomeDeckItemWidget), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Vietnamese at 320dp and textScaler 2.0 still fits', (
      tester,
    ) async {
      // **The worst case, not the default one.** The three variables that make
      // this hard — the longer locale, four-digit counts and doubled text — had
      // never met: the VI test used the two-digit fixture and the big-number
      // fixture ran in English.
      await harness.pump(
        tester,
        surface: const Size(320, 568),
        textScale: 2,
        locale: const Locale('vi'),
        decks: <StudyHomeDeckModel>[
          fakeStudyHomeDeck(
            deckId: 'long',
            deckName: 'Từ vựng chuyên ngành công nghệ thông tin',
            overdueCount: 128,
            dueTodayCount: 64,
            newCount: 256,
          ),
        ],
      );

      expect(tester.takeException(), isNull);

      // **Overflow throws; ellipsis does not.** Every metric label is
      // `maxLines: 1, overflow: ellipsis`, so truncation is the widget's own
      // quiet default — a test that only watched for an exception would call a
      // cut-off count a pass. Asked directly instead.
      final truncated = tester
          .renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(StudyHomeWorkloadItemWidget),
              matching: find.byType(RichText),
            ),
          )
          .where((paragraph) => paragraph.didExceedMaxLines)
          .toList();
      expect(
        truncated,
        isEmpty,
        reason: 'a workload count was cut off rather than wrapped',
      );
    });

    testWidgets('the resume card is not clipped either', (tester) async {
      // **The same pump, a widget nobody asked.** The sweep above queries only
      // paragraphs inside the workload row, and the resume card's deck name and
      // its `maxLines: 2` subtitle render in the same 320dp / 2.0× / Vietnamese
      // frame. Ellipsis is silent, so a clipped "Đang ôn tập · Tự đánh giá"
      // would have passed.
      await harness.pump(
        tester,
        surface: const Size(320, 568),
        textScale: 2,
        locale: const Locale('vi'),
      );

      final clipped = tester
          .renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(StudyHomeResumeSectionWidget),
              matching: find.byType(RichText),
            ),
          )
          .where((paragraph) => paragraph.didExceedMaxLines)
          .toList();

      expect(
        clipped,
        isEmpty,
        reason: 'the resume card cut a line off rather than wrapping it',
      );
    });
  });

  group('long content', () {
    testWidgets('a long deck name wraps to two lines and stops', (
      tester,
    ) async {
      await harness.pump(
        tester,
        decks: <StudyHomeDeckModel>[
          fakeStudyHomeDeck(
            deckId: 'long',
            deckName:
                'Từ vựng chuyên ngành công nghệ thông tin và truyền thông '
                'dành cho kỳ thi cuối khoá',
            overdueCount: 128,
            dueTodayCount: 64,
            newCount: 256,
          ),
        ],
      );

      final name = tester.widget<Text>(
        find.descendant(
          of: find.byType(StudyHomeDeckItemWidget),
          matching: find.textContaining('Từ vựng chuyên ngành'),
        ),
      );

      expect(name.maxLines, 2);
      expect(name.overflow, TextOverflow.ellipsis);
      // And the row still holds its verb: a name long enough to push the action
      // out of the card is the failure this cap exists to prevent.
      expect(
        find.descendant(
          of: find.byType(StudyHomeDeckItemWidget),
          matching: find.text(english.studyHomeStudyAction),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no overflow at 320dp with textScaler 2.0', (tester) async {
      await harness.pump(
        tester,
        surface: const Size(320, 568),
        textScale: 2,
        decks: <StudyHomeDeckModel>[
          fakeStudyHomeDeck(
            deckId: 'long',
            deckName: 'Từ vựng chuyên ngành công nghệ thông tin',
            overdueCount: 128,
            dueTodayCount: 64,
            newCount: 256,
          ),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });
}
