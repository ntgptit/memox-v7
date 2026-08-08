import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_summary_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_summary_section_widget.dart';

import 'support/study_widget_harness.dart';

/// The three ways a session ends, and the one that must not read as a reward.
void main() {
  StudySessionSummaryModel summaryOf({
    StudySessionKind kind = StudySessionKind.reviewing,
    StudySessionStatus status = StudySessionStatus.completed,
    StudySessionEndReason? endReason,
    int finishedCards = 4,
    int answeredCards = 6,
    int wrongTurns = 2,
    int totalTurns = 9,
  }) => StudySessionSummaryModel(
    kind: kind,
    status: status,
    endReason: endReason,
    finishedCards: finishedCards,
    answeredCards: answeredCards,
    wrongTurns: wrongTurns,
    totalTurns: totalTurns,
  );

  Future<void> pump(WidgetTester tester, StudySessionSummaryModel summary) =>
      tester.pumpWidget(
        wrapForTest(
          StudySummarySectionWidget(summary: summary, onBackToDeck: () {}),
        ),
      );

  testWidgets('a finished learning session counts the chain (BR-144)', (
    tester,
  ) async {
    await pump(tester, summaryOf(kind: StudySessionKind.learning));

    expect(find.text('Session finished'), findsOneWidget);
    expect(find.text('4 cards finished learning'), findsOneWidget);
    // The review number would be a different question answered by accident.
    expect(find.text('6 cards reviewed'), findsNothing);
  });

  testWidgets('a finished review session counts cards and mistakes', (
    tester,
  ) async {
    await pump(tester, summaryOf());

    expect(find.text('6 cards reviewed'), findsOneWidget);
    expect(find.text('2 wrong out of 9'), findsOneWidget);
  });

  testWidgets('leaving early is reported as stopped, not finished', (
    tester,
  ) async {
    await pump(
      tester,
      summaryOf(
        status: StudySessionStatus.abandoned,
        endReason: StudySessionEndReason.userExit,
      ),
    );

    expect(find.text('Session stopped'), findsOneWidget);
    expect(find.text('Session finished'), findsNothing);
    expect(
      find.textContaining('Everything answered so far is saved'),
      findsOneWidget,
    );
  });

  testWidgets('a failed write says so instead of celebrating (BR-85)', (
    tester,
  ) async {
    // The case the heading exists for. The counts are identical to a completed
    // session's, so a shared heading would turn "your last answer never made it
    // to storage" into a congratulation.
    await pump(
      tester,
      summaryOf(
        status: StudySessionStatus.failed,
        endReason: StudySessionEndReason.persistenceError,
      ),
    );

    expect(find.text('Session stopped'), findsOneWidget);
    expect(find.textContaining('could not be saved'), findsOneWidget);
  });

  testWidgets('one card reads as one card, not "1 cards"', (tester) async {
    // The count strings are ICU plurals like the rest of the app-s. A session
    // that got through exactly one card is the common case for a short review,
    // and the ungrammatical form is the one a user sees most.
    await pump(
      tester,
      summaryOf(answeredCards: 1, wrongTurns: 1, totalTurns: 1),
    );

    expect(find.text('1 card reviewed'), findsOneWidget);
    expect(find.text('1 wrong out of 1'), findsOneWidget);
  });

  testWidgets('a session with no graded turn shows no ratio', (tester) async {
    // A `browse` stage writes no answer row at all (BR-111), and "0 wrong out
    // of 0" is a statistic about nothing.
    await pump(tester, summaryOf(wrongTurns: 0, totalTurns: 0));

    expect(find.textContaining('wrong out of'), findsNothing);
  });
}
