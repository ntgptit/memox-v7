import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/presentation/states/study_session_state.dart';
import 'package:memox/features/study/presentation/widgets/support/study_mode_view_widget.dart';

import 'support/recall_turn_fixture.dart';
import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// What `recall` actually sends to the session, taken from the wiring rather
/// than from the widget.
///
/// **This is where BR-131 lands, and the widget cannot see it.** The mode deals
/// in three outcomes; what reaches `study_answers` is a canonical action plus a
/// reason, and the mapping between them lives in `studyModeView`. A test at the
/// widget level would have proved that *Remembered* was pressed — not that the
/// scheduler was told the card was known, which is the thing 8-box acts on.
void main() {
  /// One press, and everything the session was told about it.
  Future<({List<StudyAction> actions, List<StudyOutcomeReason?> reasons})>
  press(WidgetTester tester, String? label) async {
    final actions = <StudyAction>[];
    final reasons = <StudyOutcomeReason?>[];

    final view = studyModeView(
      mode: StudyMode.recall,
      state: StudySessionState(
        turn: recallTurn('c1'),
        sessionCards: <StudyCardModel>[recallTurn('c1').card],
        schedulerType: SchedulerType.eightBox,
        actions: const <StudyAction>[
          StudyAction.forgotten,
          StudyAction.remembered,
        ],
      ),
      onAnswer:
          (
            action, {
            cardId,
            outcomeReason,
            comparisonVersion,
            hasUsedHint,
          }) async {
            actions.add(action);
            reasons.add(outcomeReason);

            return commitOf('c1');
          },
      onContinue: () {},
      onLookBack: () {},
    );

    await tester.pumpWidget(wrapForTest(view!, isScrollable: false));

    if (label == null) {
      // Nobody pressed anything: the clock is the one answering.
      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();

      return (actions: actions, reasons: reasons);
    }

    await tester.tap(find.text('Show answer'));
    await tester.pump();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();

    return (actions: actions, reasons: reasons);
  }

  testWidgets('Remembered is the algorithm’s correct action, with no reason', (
    tester,
  ) async {
    // **The regression this file exists for.** *Show answer* used to arrive here
    // as `RecallOutcome.revealed` and map straight onto this action, so a
    // learner who gave up early promoted the card a box. Nothing but the
    // learner saying so produces it now (BR-159).
    final sent = await press(tester, 'Remembered');

    expect(sent.actions, <StudyAction>[StudyAction.remembered]);
    expect(sent.reasons, <StudyOutcomeReason?>[null]);
  });

  testWidgets('Forgot is the wrong action, and carries no reason either', (
    tester,
  ) async {
    final sent = await press(tester, 'Forgot');

    expect(sent.actions, <StudyAction>[StudyAction.forgotten]);
    // Owning up to a blank is not running out of time, and the difference is
    // exactly what the reason column exists to keep (BR-131).
    expect(sent.reasons, <StudyOutcomeReason?>[null]);
  });

  testWidgets('a timeout is the same wrong action and says why (BR-131)', (
    tester,
  ) async {
    final sent = await press(tester, null);

    expect(sent.actions, <StudyAction>[StudyAction.forgotten]);
    expect(sent.reasons, <StudyOutcomeReason?>[StudyOutcomeReason.timeout]);
  });

  testWidgets('a reveal sends nothing at all', (tester) async {
    final actions = <StudyAction>[];

    final view = studyModeView(
      mode: StudyMode.recall,
      state: StudySessionState(
        turn: recallTurn('c1'),
        sessionCards: <StudyCardModel>[recallTurn('c1').card],
        schedulerType: SchedulerType.eightBox,
      ),
      onAnswer:
          (
            action, {
            cardId,
            outcomeReason,
            comparisonVersion,
            hasUsedHint,
          }) async {
            actions.add(action);

            return commitOf('c1');
          },
      onContinue: () {},
      onLookBack: () {},
    );

    await tester.pumpWidget(wrapForTest(view!, isScrollable: false));
    await tester.tap(find.text('Show answer'));
    await tester.pump();

    expect(actions, isEmpty);
    expect(find.text('Remembered'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
