import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';

import 'support/recall_turn_fixture.dart';
import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// The ending nobody chose: the clock reaches zero and the card is lost.
///
/// **A timeout is a system verdict, so the screen owes the learner two things
/// the assessment path does not.** It has to say what was recorded — a card
/// that simply moved on leaves them guessing whether it counted — and it has to
/// wait. There is no reading budget anyone else can pick for a back they have
/// never seen, so the turn ends at a *Next* they press, and pressing it writes
/// nothing.
void main() {
  group('recall · the clock runs out', () {
    testWidgets('writes one wrong answer, and reveals only once it is in', (
      tester,
    ) async {
      final outcomes = <RecallOutcome>[];
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (outcome) {
              outcomes.add(outcome);

              return write.future;
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(kRecallTurnLimit);
      await tester.pump();

      // The write has started and nothing has been claimed on screen yet
      // (BR-157): a back uncovered over an open transaction is a verdict the
      // session has no record of.
      expect(outcomes, <RecallOutcome>[RecallOutcome.timedOut]);
      expect(find.text('công'), findsNothing);
      expect(find.textContaining("Time's up"), findsNothing);

      write.commit('c1');
      await tester.pumpAndSettle();

      expect(find.text('công'), findsOneWidget);
      expect(find.textContaining("Time's up"), findsOneWidget);
      expect(find.textContaining('counted as forgotten'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      // The two the learner never earned: the clock took the choice away
      // (BR-130).
      expect(find.text('Remembered'), findsNothing);
      expect(find.text('Forgot'), findsNothing);
    });

    testWidgets('does not move on by itself, however long it is left', (
      tester,
    ) async {
      // **The behaviour a fixed 2200ms budget got wrong.** The back is new text
      // on a card the learner just lost; how long that takes to read is theirs
      // to decide, and a screen that took it away after two seconds was timing
      // its own convenience.
      final shown = <bool>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) async => commitOf('c1'),
            onFeedbackShown: ({required isCorrect}) async =>
                shown.add(isCorrect),
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();

      expect(shown, isEmpty, reason: 'nothing advanced without a press');
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Next advances once and writes nothing', (tester) async {
      var writes = 0;
      final shown = <bool>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) async {
              writes += 1;

              return commitOf('c1');
            },
            onFeedbackShown: ({required isCorrect}) async =>
                shown.add(isCorrect),
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await tester.pump();

      expect(shown, hasLength(1), reason: 'one advance, not two');
      expect(
        writes,
        1,
        reason: 'the answer was written by the clock, not here',
      );
    });

    testWidgets('a refused timeout never offers Remembered again (BR-130)', (
      tester,
    ) async {
      // **The one a retry could get badly wrong.** The clock is spent whatever
      // the database did; a screen that fell back to the choice would turn a
      // missed card into a correct one because a write was busy. What it offers
      // is the same wrong answer, once more.
      final outcomes = <RecallOutcome>[];
      final write = PendingCommit();
      final second = PendingCommit();
      var writes = 0;
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (outcome) {
              outcomes.add(outcome);
              writes += 1;

              return writes == 1 ? write.future : second.future;
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(kRecallTurnLimit);
      await tester.pump();
      write.refuse();
      await tester.pumpAndSettle();

      expect(find.text('Remembered'), findsNothing);
      expect(find.text('Forgot'), findsNothing);
      expect(find.text('Show answer'), findsNothing);
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(writes, 1, reason: 'a refused write is not a written row');

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(outcomes, <RecallOutcome>[
        RecallOutcome.timedOut,
        RecallOutcome.timedOut,
      ]);

      second.commit('c1');
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
    });
  });

  group('recall · the race BR-129 is written for', () {
    testWidgets('a reveal at the mark loses to the timeout', (tester) async {
      // The mark is inclusive on the timeout side, so the tap that lands with
      // the clock at zero is a miss — reading it the other way makes the app
      // generous at random, in the one case a learner cannot tell apart from
      // having failed.
      final outcomes = <RecallOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            initialRemaining: Duration.zero,
            onOutcome: (outcome) async {
              outcomes.add(outcome);

              return commitOf('c1');
            },
          ),
          isScrollable: false,
        ),
      );

      // Tapped in the same frame the tick claims the turn.
      await tester.tap(find.text('Show answer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(outcomes, <RecallOutcome>[RecallOutcome.timedOut]);
      expect(find.text('Remembered'), findsNothing);
    });

    testWidgets('a reveal before the mark is the only thing that happens', (
      tester,
    ) async {
      // One tap, then the clock runs well past zero. Exactly one claim, and it
      // is not the clock's.
      final outcomes = <RecallOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (outcome) async {
              outcomes.add(outcome);

              return commitOf('c1');
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();

      expect(outcomes, isEmpty, reason: 'a reveal writes nothing at all');
      expect(find.text('Remembered'), findsOneWidget);
    });
  });
}
