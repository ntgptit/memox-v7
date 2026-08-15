import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/study_home_harness.dart';
import 'package:memox/core/theme/app_icon_size.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_workload_item_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

/// The inside of one card, and the frame the stateless screens share
/// (UC-14, wireframe G6…G10, G14).
///
/// Split from the column measurements next door because the guard caps a source
/// file at 400 lines — and because these are a different question: not where the
/// column sits, but how a card spends the space inside it.
void main() {
  final english = AppLocalizationsEn();

  late StudyHomeHarness harness;

  setUp(() => harness = StudyHomeHarness());
  tearDown(() => harness.dispose());

  group('inside one deck row', () {
    /// Anything under the first row, found by type or by text.
    Finder inRow(Finder matching) => find.descendant(
      of: find.byType(StudyHomeDeckItemWidget).first,
      matching: matching,
    );

    testWidgets('the card pads its content by one step on every side', (
      tester,
    ) async {
      await harness.pump(tester);

      final card = tester.getRect(inRow(find.byType(MxCard)).first);
      final name = tester.getRect(inRow(find.text('Everyday Korean')).first);
      final action = tester.getRect(inRow(find.byType(MxActionButton)).first);

      expect(name.left - card.left, AppSpacing.lg);
      expect(name.top - card.top, AppSpacing.lg);
      expect(card.bottom - action.bottom, AppSpacing.lg);
      // The fourth side, which the first version of this test called "every
      // side" without measuring. `CrossAxisAlignment.stretch` makes the name's
      // right edge the content edge, so this is exact rather than incidental.
      expect(card.right - name.right, AppSpacing.lg);
    });

    testWidgets('the resume card pads its content the same way', (
      tester,
    ) async {
      // G6 says "Resume card *and* row", and the row-scoped finder above could
      // not see the resume card at all — so the half of the rule about the one
      // surface that steps away from `surface` was going unmeasured.
      await harness.pump(tester);

      final resume = find.byType(StudyHomeResumeSectionWidget);
      final card = tester.getRect(
        find.descendant(of: resume, matching: find.byType(MxCard)).first,
      );
      final heading = tester.getRect(
        find
            .descendant(
              of: resume,
              matching: find.text(english.studyHomeResumeTitle),
            )
            .first,
      );
      final action = tester.getRect(
        find
            .descendant(of: resume, matching: find.byType(MxActionButton))
            .first,
      );

      expect(heading.left - card.left, AppSpacing.lg);
      expect(heading.top - card.top, AppSpacing.lg);
      expect(card.right - heading.right, AppSpacing.lg);
      expect(card.bottom - action.bottom, AppSpacing.lg);
    });

    testWidgets('the identity block breaks at xs, then sm before the counts', (
      tester,
    ) async {
      await harness.pump(tester);

      final name = tester.getRect(inRow(find.text('Everyday Korean')).first);
      final scheduler = tester.getRect(
        inRow(find.text(english.schedulerEightBoxShortLabel)).first,
      );
      final workload = tester.getRect(
        inRow(find.byType(StudyHomeWorkloadItemWidget)).first,
      );

      // Line breaks inside one block, so the smallest step; then one more for
      // the seam between what the deck *is* and what is waiting in it.
      expect(scheduler.top - name.bottom, AppSpacing.xs);
      expect(workload.top - scheduler.bottom, AppSpacing.sm);
    });

    testWidgets('the verb sits a section step below the counts', (
      tester,
    ) async {
      await harness.pump(tester);

      final workload = tester.getRect(
        inRow(find.byType(StudyHomeWorkloadItemWidget)).first,
      );
      final action = tester.getRect(inRow(find.byType(MxActionButton)).first);

      // Information above, verb below: one step more than the line breaks
      // inside the block, and one step less than a break between two cards.
      expect(action.top - workload.bottom, AppSpacing.md);
    });

    testWidgets(
      'a workload glyph rides the body baseline, one xs from its word',
      (tester) async {
        await harness.pump(tester);

        final icon = tester.getRect(inRow(find.byIcon(Icons.event_busy)).first);
        final label = tester.getRect(
          inRow(find.text(english.studyHomeOverdueLabel(2))).first,
        );

        expect(icon.height, AppIconSize.sm);
        expect(icon.width, AppIconSize.sm);
        expect(label.left - icon.right, AppSpacing.xs);
        // Same band as the text it belongs to — a glyph on its own baseline reads
        // as a separate element rather than as part of the count.
        expect(icon.top, label.top);
        expect(icon.bottom, label.bottom);
      },
    );

    testWidgets('the three counts are one step apart', (tester) async {
      await harness.pump(tester);

      final overdue = tester.getRect(
        inRow(find.text(english.studyHomeOverdueLabel(2))).first,
      );
      final dueToday = tester.getRect(inRow(find.byIcon(Icons.event)).first);

      // Measured end-of-group to start-of-next-group, which is what `Wrap`'s
      // `spacing` actually controls — the icon leads each group.
      expect(dueToday.left - overdue.right, AppSpacing.md);
    });
  });

  group('the states share one frame', () {
    testWidgets('the error state is inset like the empty states, not more', (
      tester,
    ) async {
      // Both appear on this screen, and both centre themselves inside their own
      // padding. Adding the screen gutter to one of them made the error copy
      // narrower than the empty copy for no reason a reader could see.
      await harness.pump(tester, failing: true);

      final shell = tester.getRect(find.byType(MxContentShell));
      final error = tester.getRect(find.byType(MxErrorState));

      expect(error.left, shell.left);
      expect(error.width, shell.width);
    });

    testWidgets('an empty library is inset the same way', (tester) async {
      await harness.pump(tester, decks: const <StudyHomeDeckModel>[]);

      final shell = tester.getRect(find.byType(MxContentShell));
      final empty = tester.getRect(find.byType(MxEmptyState));

      expect(empty.left, shell.left);
      expect(empty.width, shell.width);
    });
  });
}
