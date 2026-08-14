// Which decks are asked for a direction on the way into a review (BR-182).
//
// **Driven through the real screen**, because the question is one of routing:
// an `sm2` deck offers a single review mode and therefore skips the *mode*
// chooser (BR-146) — so it lands directly on the direction question, and an
// `eight_box` deck must land on the mode chooser and never see one.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_direction_chooser_widget.dart';
import 'package:memox/features/study/domain/models/study_deck_context_model.dart';
import 'package:memox/features/study/domain/models/study_entry_summary_model.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_mode_chooser_widget.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';

import '../../../visual_audit/study_audit_harness.dart';
import 'support/study_widget_harness.dart';
import '../domain/support/fake_study_repository.dart';

/// A fake whose due count can be taken away **after** the screen has read it.
///
/// That is the only way to reach UC-12 E2 through the real screen: with nothing
/// due there is no Review entry at all (BR-145), so the last card has to go while
/// the sheet is already open.
final class _DrainableStudyRepository extends FakeStudyRepository {
  _DrainableStudyRepository({required super.schedulerType});

  int dueCount = 4;

  /// The algorithm as the *next* read will see it. A Reset or an unlocked
  /// scheduler change elsewhere is exactly this: the deck moves while a sheet
  /// that was opened for the old one is still up (BR-13, BR-83).
  ///
  /// Overriding `deckContext` rather than the field, because that is the read
  /// `GetReviewOptionsUseCase` actually makes — and the point of the test is
  /// that the *re-read* sees the change.
  SchedulerType? nextSchedulerType;

  @override
  Future<StudyDeckContextModel> deckContext(String deckId) async =>
      StudyDeckContextModel(
        deckId: deckId,
        deckName: 'Korean',
        rootDeckId: 'root',
        schedulerType: nextSchedulerType ?? schedulerType,
        schedulerGeneration: 1,
      );

  @override
  Stream<StudyEntrySummaryModel> watchStudyEntry(
    String deckId, {
    required DateTime now,
  }) => Stream<StudyEntrySummaryModel>.value(
    StudyEntrySummaryModel(
      newCount: 3,
      dueCount: dueCount,
      fillableCount: dueCount,
      distinctMeanings: dueCount,
    ),
  );
}

void main() {
  Future<void> pumpEntry(
    WidgetTester tester, {
    required SchedulerType scheduler,
    FakeStudyRepository? repository,
  }) async {
    // A real phone rather than the 800×600 default: a modal sheet is capped at a
    // fraction of the screen height, so the default viewport measures a sheet no
    // device ever shows.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // **The scope is outermost, and it has to be.** `showModalBottomSheet` pushes
    // on the `MaterialApp`'s navigator, so a scope *inside* the app leaves every
    // sheet outside it — and the first `ref` read from one throws "No
    // ProviderScope found" at the moment the sheet opens.
    await tester.pumpWidget(
      studyScreenWith(
        repository ?? FakeStudyRepository(schedulerType: scheduler),
        wrapForTest(
          const StudyEntryScreen(deckId: 'deck-1'),
          isScrollable: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an sm2 deck is asked which way to be reviewed', (tester) async {
    await pumpEntry(tester, scheduler: SchedulerType.sm2);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.byType(StudyDirectionChooserWidget), findsOneWidget);
    expect(find.text('Korean first'), findsOneWidget);
    expect(find.text('Meaning first'), findsOneWidget);
    expect(find.text('Mixed'), findsOneWidget);
  });

  testWidgets('an eight_box deck is never offered one (BR-182)', (
    tester,
  ) async {
    // The negative half. `eight_box` reviews in `match`/`guess`/`recall`/`fill`,
    // none of which has a prompt face to reverse — so the route it takes is the
    // mode chooser, and the direction sheet must be unreachable from it.
    await pumpEntry(tester, scheduler: SchedulerType.eightBox);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.byType(StudyModeChooserWidget), findsOneWidget);
    expect(find.byType(StudyDirectionChooserWidget), findsNothing);

    await tester.tap(find.text('Match'));
    await tester.pumpAndSettle();

    expect(find.byType(StudyDirectionChooserWidget), findsNothing);
  });

  testWidgets('dismissing the sheet starts nothing (BR-101)', (tester) async {
    // Exiting before the queue exists must leave no session behind, and the
    // cheapest way to be sure of that is for nothing to have been asked for yet.
    await pumpEntry(tester, scheduler: SchedulerType.sm2);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.byType(StudyDirectionChooserWidget), findsOneWidget);

    Navigator.of(
      tester.element(find.byType(StudyDirectionChooserWidget)),
    ).pop();
    await tester.pumpAndSettle();

    expect(find.byType(StudyDirectionChooserWidget), findsNothing);
    expect(find.byType(StudyEntryScreen), findsOneWidget);
  });

  testWidgets('the last card going while the sheet is open is said in it', (
    tester,
  ) async {
    // UC-12 E2. Before this, the sheet popped first and BR-145's refusal
    // surfaced as a full-screen error on the session screen — with the choice
    // lost and no way back to it.
    final repository = _DrainableStudyRepository(
      schedulerType: SchedulerType.sm2,
    );
    await pumpEntry(
      tester,
      scheduler: SchedulerType.sm2,
      repository: repository,
    );

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.byType(StudyDirectionChooserWidget), findsOneWidget);

    repository.dueCount = 0;

    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // The sheet is still up, saying so, with the choice intact — and the line
    // does not tell the user to retry something that cannot succeed: cards come
    // due with time, not with another tap.
    expect(find.byType(StudyDirectionChooserWidget), findsOneWidget);
    expect(find.text('Nothing is due to review any more.'), findsOneWidget);
    expect(find.text('Could not start the review. Try again.'), findsNothing);
    expect(
      tester
          .widget<MxListTile>(
            find.ancestor(
              of: find.text('Mixed'),
              matching: find.byType(MxListTile),
            ),
          )
          .isSelected,
      isFalse,
      reason: 'the default is still selected, and nothing moved it',
    );
  });

  testWidgets('the deck changing algorithm under the sheet is said in it', (
    tester,
  ) async {
    // UC-12 E1, through the real screen. The unit tests prove the use case
    // refuses; this is the half that proves the *user* is told, in the sheet
    // they are looking at, instead of on a screen they did not ask for.
    final repository = _DrainableStudyRepository(
      schedulerType: SchedulerType.sm2,
    );
    await pumpEntry(
      tester,
      scheduler: SchedulerType.sm2,
      repository: repository,
    );

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.byType(StudyDirectionChooserWidget), findsOneWidget);

    repository.nextSchedulerType = SchedulerType.eightBox;

    await tester.tap(find.text('Start review'));
    await tester.pumpAndSettle();

    // This one *is* worth retrying — leaving and coming back lands on a screen
    // that makes sense — so it keeps the generic line.
    expect(find.byType(StudyDirectionChooserWidget), findsOneWidget);
    expect(find.text('Could not start the review. Try again.'), findsOneWidget);
  });
}
