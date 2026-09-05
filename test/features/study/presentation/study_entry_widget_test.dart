import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_entry_summary_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_mode_chooser_widget.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_resume_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_section_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';

import 'support/study_widget_harness.dart';

/// The way into a session, and the choice of how to review.
void main() {
  const eightBoxModes = <StudyMode>[
    StudyMode.match,
    StudyMode.guess,
    StudyMode.recall,
    StudyMode.fill,
  ];

  StudyEntrySummaryModel summaryOf({
    int newCount = 3,
    int dueCount = 6,
    int fillableCount = 2,
    int distinctMeanings = 6,
  }) => StudyEntrySummaryModel(
    newCount: newCount,
    dueCount: dueCount,
    fillableCount: fillableCount,
    distinctMeanings: distinctMeanings,
  );

  group('the entry section', () {
    testWidgets('shows two counts, not a combined total (BR-150)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyEntrySectionWidget(
            summary: summaryOf(),
            onLearn: () {},
            onReview: () {},
          ),
        ),
      );

      expect(find.text('New 3'), findsOneWidget);
      expect(find.text('Due 6'), findsOneWidget);
      // A combined 9 would tell the user nothing about what the next ten
      // minutes cost: five stages a card, or one turn a card.
      expect(find.text('New 9'), findsNothing);
    });

    testWidgets('with nothing due there is no way to review (BR-145)', (
      tester,
    ) async {
      var reviewed = false;
      await tester.pumpWidget(
        wrapForTest(
          StudyEntrySectionWidget(
            summary: summaryOf(dueCount: 0),
            onLearn: () {},
            onReview: () => reviewed = true,
          ),
        ),
      );

      // Absent with an explanation, not present and refusing: studying ahead is
      // a rule, and a button that says no is an invitation to keep pressing.
      expect(find.text('Review'), findsNothing);
      expect(find.textContaining('Nothing to review'), findsOneWidget);
      expect(reviewed, isFalse);
    });

    testWidgets('with nothing new the learn entry is gone too', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyEntrySectionWidget(
            summary: summaryOf(newCount: 0),
            onLearn: () {},
            onReview: () {},
          ),
        ),
      );

      expect(find.text('Learn new'), findsNothing);
      expect(find.textContaining('has been learned'), findsOneWidget);
    });

    testWidgets('nothing new and nothing due is an empty state, not zeroes', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyEntrySectionWidget(
            summary: summaryOf(newCount: 0, dueCount: 0),
            onLearn: () {},
            onReview: () {},
          ),
        ),
      );

      // Both entries are gone at (0, 0), so the readout row was the loudest
      // thing left on the screen and all it said was "New 0": the app's
      // largest type spent stating an absence twice.
      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.text('New 0'), findsNothing);
      expect(find.text('Due 0'), findsNothing);
      expect(find.text('All caught up'), findsOneWidget);
      // Action-free, like the app's other dead ends: the way out is the app
      // bar, and a button here would be a second one.
      expect(find.byType(MxActionButton), findsNothing);
    });
  });

  group('the mode chooser', () {
    testWidgets('eight_box offers exactly four modes, never browse', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyModeChooserWidget(
            modes: eightBoxModes,
            summary: summaryOf(),
            onModeSelected: (_) {},
          ),
        ),
      );

      for (final label in <String>['Match', 'Guess', 'Recall', 'Fill in']) {
        expect(find.text(label), findsOneWidget);
      }
      // `browse` grades nothing, so a review in it would record nothing and
      // never end (BR-111, BR-146).
      expect(find.text('Browse'), findsNothing);
    });

    testWidgets('each mode shows its own count, not one shared (BR-154)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyModeChooserWidget(
            modes: eightBoxModes,
            summary: summaryOf(),
            onModeSelected: (_) {},
          ),
        ),
      );

      // `fill` needs an example and the field is optional, which is exactly why
      // one number against four modes would be a lie about three of them.
      expect(find.text('6 cards'), findsNWidgets(3));
      expect(find.text('2 cards'), findsOneWidget);
    });

    testWidgets('a mode that cannot run is disabled with its reason (BR-99)', (
      tester,
    ) async {
      final chosen = <StudyMode>[];
      await tester.pumpWidget(
        wrapForTest(
          StudyModeChooserWidget(
            modes: eightBoxModes,
            summary: summaryOf(fillableCount: 0),
            onModeSelected: chosen.add,
          ),
        ),
      );

      // Disabled and explained, never hidden: a control that vanishes reads as
      // a bug, one that says what it needs is instructions.
      expect(find.text('Fill in'), findsOneWidget);
      expect(find.text('Needs cards with an example'), findsOneWidget);

      await tester.tap(find.text('Fill in'));
      await tester.pump();

      expect(chosen, isEmpty);
    });

    testWidgets('an unavailable mode is greyed, not merely untappable (BR-99)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyModeChooserWidget(
            modes: eightBoxModes,
            summary: summaryOf(fillableCount: 0),
            onModeSelected: (_) {},
          ),
        ),
      );

      // A null `onTap` alone leaves the row at full ink: before this was fixed
      // all four titles measured #ff223354 and all four subtitles #ff596680,
      // so the reason sentence was the only thing telling a sighted user the
      // row was dead. Read off the rendered paragraph rather than the tile's
      // flag, because the flag is what regressed into being decorative.
      Color inkOf(String label) {
        final rich = tester.widget<RichText>(
          find
              .descendant(of: find.text(label), matching: find.byType(RichText))
              .first,
        );
        return (rich.text as TextSpan).style!.color!;
      }

      final disabled = Theme.of(
        tester.element(find.byType(MxListTile).first),
      ).disabledColor;

      expect(inkOf('Fill in'), disabled);
      expect(inkOf('Needs cards with an example'), disabled);
      // The runnable neighbour keeps full ink, so the difference is the signal.
      expect(inkOf('Recall'), isNot(disabled));
    });

    testWidgets('guess needs five distinct meanings (BR-121, BR-124)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyModeChooserWidget(
            modes: eightBoxModes,
            summary: summaryOf(distinctMeanings: 4),
            onModeSelected: (_) {},
          ),
        ),
      );

      // Four meanings cannot build a single five-option question, however many
      // cards are due.
      expect(find.text('Needs five different meanings'), findsOneWidget);
    });

    testWidgets('match needs two pairs (BR-153)', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          StudyModeChooserWidget(
            modes: eightBoxModes,
            summary: summaryOf(dueCount: 1, distinctMeanings: 1),
            onModeSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Needs at least two pairs'), findsOneWidget);
    });

    testWidgets('an available mode reports the chosen value', (tester) async {
      final chosen = <StudyMode>[];
      await tester.pumpWidget(
        wrapForTest(
          StudyModeChooserWidget(
            modes: eightBoxModes,
            summary: summaryOf(),
            onModeSelected: chosen.add,
          ),
        ),
      );

      await tester.tap(find.text('Recall'));
      await tester.pump();

      expect(chosen, <StudyMode>[StudyMode.recall]);
    });
  });

  group('the three paths (BR-103)', () {
    /// All three, every time this sheet is shown.
    ///
    /// The sheet only exists when there is a session to continue, so a variant
    /// with two paths would be the entry screen behind it — see
    /// `study_entry_screen.dart`, which is where "show nothing" is decided.
    testWidgets('offers continue, learn and review', (tester) async {
      await tester.pumpWidget(wrapForTest(StudyResumeWidget(onChoice: (_) {})));

      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Learn new'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('says that starting new ends the open session', (tester) async {
      // Before the tap, not in a toast afterwards: a session ended by surprise
      // cannot be un-ended, because the row is already written.
      await tester.pumpWidget(wrapForTest(StudyResumeWidget(onChoice: (_) {})));

      expect(find.textContaining('ends the open session'), findsOneWidget);
    });

    for (final path in <({String label, StudyResumeChoice choice})>[
      (label: 'Continue', choice: StudyResumeChoice.resume),
      (label: 'Learn new', choice: StudyResumeChoice.learn),
      (label: 'Review', choice: StudyResumeChoice.review),
    ]) {
      testWidgets('${path.label} reports ${path.choice.name}', (tester) async {
        final chosen = <StudyResumeChoice>[];
        await tester.pumpWidget(
          wrapForTest(StudyResumeWidget(onChoice: chosen.add)),
        );

        await tester.tap(find.text(path.label));
        await tester.pump();

        expect(chosen, <StudyResumeChoice>[path.choice]);
      });
    }
  });
}
