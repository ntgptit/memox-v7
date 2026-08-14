import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../domain/support/fake_study_home_repository.dart';
import 'support/study_home_harness.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

/// Which of Study Home's seven states renders, and when (UC-12, BR-184, W3).
///
/// Three loaded states and two empty ones, because each has a different next
/// step: ready-made content, the library, or a session. Collapsing any pair
/// would send somebody who already has four decks to a catalog they do not need.
void main() {
  final english = AppLocalizationsEn();

  late StudyHomeHarness harness;

  setUp(() => harness = StudyHomeHarness());
  tearDown(() => harness.dispose());

  /// The Study verb *inside a row*, never the tab label or the app-bar title.
  ///
  /// All three read "Study", so an unscoped `find.text` matches the chrome and
  /// would keep passing after the rows stopped rendering at all.
  final studyButton = find.descendant(
    of: find.byType(StudyHomeDeckItemWidget),
    matching: find.text(AppLocalizationsEn().studyHomeStudyAction),
  );

  group('states', () {
    testWidgets('the first read shows a labelled spinner, not a blank tab', (
      tester,
    ) async {
      // A read that never lands: the loading state is the one state that
      // cannot be reached by settling.
      await harness.pump(tester, pending: true);

      expect(find.byType(MxLoadingState), findsOneWidget);
    });

    testWidgets('a resume and a mixed library render both bands', (
      tester,
    ) async {
      await harness.pump(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(resume: fakeStudyHomeResume()),
        ),
      );

      expect(find.byType(StudyHomeResumeSectionWidget), findsOneWidget);
      expect(find.byType(StudyHomeDeckItemWidget), findsNWidgets(2));
      expect(find.text(english.studyHomeNextTitle), findsOneWidget);
    });

    testWidgets('no open session means no resume card at all', (tester) async {
      await harness.pump(tester, hasResume: false);

      // Not an empty card and not a disabled button: with nothing to continue,
      // the band would be a heading over nothing.
      expect(find.byType(StudyHomeResumeSectionWidget), findsNothing);
      expect(find.text(english.studyHomeResumeTitle), findsNothing);
    });

    testWidgets('every count shows, zeroes included', (tester) async {
      await harness.pump(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(
            decks: <StudyHomeDeckModel>[
              fakeStudyHomeDeck(
                deckId: 'a',
                deckName: 'Quiet deck',
                totalCardCount: 30,
              ),
            ],
          ),
        ),
      );

      // An absent metric is ambiguous in exactly the way the line exists to
      // prevent — "no overdue count" could mean none, or could mean untracked.
      expect(find.text(english.studyHomeOverdueLabel(0)), findsOneWidget);
      expect(find.text(english.studyHomeDueTodayLabel(0)), findsOneWidget);
      expect(find.text(english.studyHomeNewLabel(0)), findsOneWidget);
      // And the row keeps its way in: BR-29 makes nothing due the schedule
      // working rather than a locked door. Scoped to the row, because the tab
      // label and the screen title are the same word — an unscoped finder would
      // pass on the chrome alone.
      expect(studyButton, findsOneWidget);
      expect(find.text(english.studyHomeNothingDueMessage), findsOneWidget);
    });

    testWidgets('the supporting line matches whether there is a resume', (
      tester,
    ) async {
      await harness.pump(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(resume: fakeStudyHomeResume()),
        ),
      );

      expect(find.text(english.studyHomeSupportingCopy), findsOneWidget);
      expect(find.text(english.studyHomeSupportingCopyNoResume), findsNothing);
    });

    testWidgets('with nothing open it stops promising somewhere to carry on', (
      tester,
    ) async {
      // BR-182 needs four conditions at once, so no open session is the
      // ordinary state — and the line above the list said "or carry on where
      // you stopped" over a screen with no Resume card on it.
      await harness.pump(tester, hasResume: false);

      expect(
        find.text(english.studyHomeSupportingCopyNoResume),
        findsOneWidget,
      );
      expect(find.text(english.studyHomeSupportingCopy), findsNothing);
    });

    testWidgets('the list heading is a heading to a screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await harness.pump(tester);

      // The `xl` above it builds the section break visually; without this the
      // break is invisible to TalkBack, which hears the resume card run
      // straight into the first deck and cannot jump by heading.
      expect(
        tester.getSemantics(find.text(english.studyHomeNextTitle)),
        matchesSemantics(label: english.studyHomeNextTitle, isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('an empty library offers the starter catalog', (tester) async {
      await harness.pump(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(decks: const <StudyHomeDeckModel>[]),
        ),
      );

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.text(english.studyHomeEmptyLibraryTitle), findsOneWidget);
      expect(find.text(english.studyHomeStarterAction), findsOneWidget);
    });

    testWidgets('decks with no cards is a different state from no decks', (
      tester,
    ) async {
      await harness.pump(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(
            decks: <StudyHomeDeckModel>[
              fakeStudyHomeDeck(deckId: 'a', deckName: 'A', totalCardCount: 0),
            ],
          ),
        ),
      );

      expect(find.text(english.studyHomeNoCardsTitle), findsOneWidget);
      // The library, not the catalog: the decks already exist.
      expect(find.text(english.studyHomeOpenLibraryAction), findsOneWidget);
      expect(find.text(english.studyHomeStarterAction), findsNothing);
      // And no invented workload for a deck that holds nothing.
      expect(find.byType(StudyHomeDeckItemWidget), findsNothing);
    });

    testWidgets('a failed read offers a retry that re-reads', (tester) async {
      final failing = FakeStudyHomeRepository(failure: StateError('nope'));
      addTearDown(failing.dispose);
      await harness.pump(tester, repository: failing);

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.studyHomeErrorTitle), findsOneWidget);

      final before = failing.subscriptions;
      await tester.tap(find.text(english.retryAction));
      await tester.pumpAndSettle();

      expect(failing.subscriptions, greaterThan(before));
    });
  });
}
