import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../domain/support/fake_study_home_repository.dart';
import 'support/study_home_harness.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

/// The column Study Home lays out: its gutters, its rhythm and its clearances
/// (UC-12, wireframe `m5-study-home.md` G1…G5b, G11, G12).
///
/// **Measured on the production tree**, because half of what is asserted here is
/// a property of what the screen is mounted *in* — the gutter comes from the
/// shell, the clearance from the bar the shell owns. A bare pump would measure a
/// layout the app never renders.
///
/// Every number is read with `getRect` and compared to a token, never a literal.
/// A literal is how a spacing change passes review by editing the token and the
/// test in one commit.
void main() {
  final english = AppLocalizationsEn();

  late StudyHomeHarness harness;

  setUp(() => harness = StudyHomeHarness());
  tearDown(() => harness.dispose());

  group('gutters and shared edges', () {
    testWidgets('the resume card and every row share both edges', (
      tester,
    ) async {
      await harness.pump(tester);

      final resume = tester.getRect(find.byType(StudyHomeResumeSectionWidget));
      final rows = find.byType(StudyHomeDeckItemWidget);
      final first = tester.getRect(rows.first);
      final last = tester.getRect(rows.last);

      // One content column: a resume band inset differently from the rows under
      // it reads as two screens stacked, which is the exact failure a shared
      // gutter exists to prevent.
      expect(first.left, resume.left);
      expect(first.right, resume.right);
      expect(last.left, resume.left);
      expect(last.right, resume.right);
    });

    testWidgets('the column is inset by the screen gutter', (tester) async {
      await harness.pump(tester);

      final screen = tester.getRect(find.byType(MaterialApp));
      final row = tester.getRect(find.byType(StudyHomeDeckItemWidget).first);

      expect(row.left - screen.left, AppSpacing.lg);
      expect(screen.right - row.right, AppSpacing.lg);
    });

    testWidgets('at 320dp the gutter steps down with the breakpoint', (
      tester,
    ) async {
      await harness.pump(tester, surface: const Size(320, 568));

      final screen = tester.getRect(find.byType(MaterialApp));
      final row = tester.getRect(find.byType(StudyHomeDeckItemWidget).first);

      // `mxScreenGutter` drops below `AppBreakpoints.compact`, and the screen
      // takes it from there rather than re-deriving the rule — a second copy is
      // how the two drift apart below 360, where nobody looks.
      expect(row.left - screen.left, AppSpacing.md);
    });
  });

  group('rhythm', () {
    testWidgets('rows are separated by one step, not by a section break', (
      tester,
    ) async {
      await harness.pump(tester);

      final rows = find.byType(StudyHomeDeckItemWidget);
      final first = tester.getRect(rows.at(0));
      final second = tester.getRect(rows.at(1));

      expect(second.top - first.bottom, AppSpacing.md);
    });

    testWidgets('the list heading sits a section break below the resume', (
      tester,
    ) async {
      await harness.pump(tester);

      final resume = tester.getRect(find.byType(StudyHomeResumeSectionWidget));
      final heading = tester.getRect(find.text(english.studyHomeNextTitle));

      // `xl`, not `md`: the seam between "what you were doing" and "what you
      // could do next" is a section boundary, and a break the size of the gap
      // between two cards would make the heading read as another row.
      expect(heading.top - resume.bottom, AppSpacing.xl);
    });

    testWidgets('the first row sits one step below the list heading', (
      tester,
    ) async {
      // **Unmeasured until now, and it moved under a refactor.** The row gap
      // was trailing each row and became leading, so this distance stopped
      // coming from a standalone `SizedBox` and started coming from the loop's
      // first iteration. It survived by construction rather than by a gate,
      // which is the situation a gate exists for.
      await harness.pump(tester);

      final heading = tester.getRect(find.text(english.studyHomeNextTitle));
      final first = tester.getRect(find.byType(StudyHomeDeckItemWidget).first);

      expect(first.top - heading.bottom, AppSpacing.md);
    });
  });

  group('touch targets and clearance', () {
    testWidgets('every action clears the 48dp floor', (tester) async {
      await harness.pump(tester);

      for (final label in <String>[
        english.studyHomeResumeAction,
        english.studyHomeStudyAction,
      ]) {
        final buttons = find.widgetWithText(ButtonStyleButton, label);
        for (var i = 0; i < buttons.evaluate().length; i++) {
          expect(
            tester.getRect(buttons.at(i)).height,
            greaterThanOrEqualTo(AppSpacing.minimumTouchTarget),
            reason: '$label #$i is under the touch floor',
          );
        }
      }
    });

    testWidgets('the last row clears the bottom bar at the end of the scroll', (
      tester,
    ) async {
      // Enough rows that the list actually overscrolls: with two decks the
      // content is shorter than the viewport, the scroll never moves, and the
      // last row sits a hundred points clear of the bar for a reason that has
      // nothing to do with the padding under test.
      await harness.pump(
        tester,
        decks: <StudyHomeDeckModel>[
          for (var i = 0; i < 12; i++)
            fakeStudyHomeDeck(
              deckId: 'deck-$i',
              deckName: 'Deck number $i',
              newCount: 12 - i,
            ),
        ],
      );

      // **Jumped to the end, not flung at it.** A drag is clamped by the
      // physics and a fling settles wherever its simulation runs out, so both
      // measure a position nobody chose — the first attempt here stopped 177
      // points short and the assertion was about the gesture, not the padding.
      final controller = Scrollable.of(
        tester.element(find.byType(StudyHomeDeckItemWidget).first),
      ).position;
      //
      // Jumped until it settles, because the first jump changes the extent it
      // was aiming at: scrolling makes `MxContentShell` draw its hairline, and
      // the chrome that appears takes height out of the body the list lives in.
      for (var attempt = 0; attempt < 5; attempt++) {
        controller.jumpTo(controller.maxScrollExtent);
        await tester.pumpAndSettle();
      }

      final list = find.byType(ListView);
      final last = tester.getRect(find.byType(StudyHomeDeckItemWidget).last);
      final viewport = tester.getRect(list);
      final bar = tester.getRect(find.byType(MxNavigationBar));

      // **The scroll really reached its end**, so the clearance below is a fact
      // about the padding and not about where the finger stopped.
      expect(controller.pixels, controller.maxScrollExtent);

      // **The gap, not the inequality.** `last.bottom <= bar.top` was the first
      // version of this and it could not fail: the shell puts the bar on the
      // outer `Scaffold`, which takes its height out of the body's constraints,
      // so branch content is laid out entirely above it whatever padding the
      // list carries — deleting the padding left the assertion green. What is
      // actually promised is the list's own bottom gutter, measured against the
      // viewport that gutter lives in.
      expect(
        viewport.bottom - last.bottom,
        mxScreenGutter(
          tester.element(find.byType(StudyHomeDeckItemWidget).last),
        ),
      );
      // And the viewport itself never runs under the bar.
      expect(viewport.bottom, lessThanOrEqualTo(bar.top));
    });
  });
}
