import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';

import 'support/recall_turn_fixture.dart';
import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// Coming back to a `recall` turn, and what the session being busy does to it.
///
/// **A turn now has three places to come back to, and it used to have one.**
/// Revealing was the answer, so `is_revealed` was written and never read: every
/// resume was either a running clock or a turn that no longer existed. The
/// reveal is a live state now, which makes the column load-bearing — and makes
/// resuming into the wrong one of the three a way to record the same turn twice.
///
/// Split from `recall_timeout_widget_test.dart` at the 400-line guard.
void main() {
  group('recall · coming back to a turn (BR-133)', () {
    testWidgets('an unrevealed turn resumes its clock where it stopped', (
      tester,
    ) async {
      final reported = <Duration>[];
      final outcomes = <RecallOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            initialRemaining: const Duration(seconds: 4),
            onOutcome: (outcome) async {
              outcomes.add(outcome);

              return commitOf('c1');
            },
            onRemainingChanged: reported.add,
          ),
          isScrollable: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(reported.last.inSeconds, 3);
      expect(reported.any((left) => left.inSeconds >= 19), isFalse);
      expect(find.text('Show answer'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(outcomes, <RecallOutcome>[RecallOutcome.timedOut]);
    });

    testWidgets('a turn revealed before the interruption comes back revealed', (
      tester,
    ) async {
      // **The state that used to be impossible.** Revealing was the answer, so
      // `isRevealed` was written and never read. Now it is the difference
      // between resuming a question and asking the learner to un-know the back
      // of the card.
      final outcomes = <RecallOutcome>[];
      final reported = <Duration>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1', isRevealed: true),
            initialRemaining: const Duration(seconds: 9),
            onOutcome: (outcome) async {
              outcomes.add(outcome);

              return commitOf('c1');
            },
            onRemainingChanged: reported.add,
          ),
          isScrollable: false,
        ),
      );

      expect(find.text('công'), findsOneWidget);
      expect(find.text('Forgot'), findsOneWidget);
      expect(find.text('Remembered'), findsOneWidget);
      expect(find.text('Show answer'), findsNothing);
      expect(outcomes, isEmpty);

      // The clock stays stopped: it was stopped when the reveal happened, and
      // resuming is not a reason to start charging for the answer again.
      await tester.pump(kRecallTurnLimit * 2);
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
      expect(outcomes, isEmpty);
      expect(find.text('Remembered'), findsOneWidget);
    });

    testWidgets('a timeout already recorded comes back to Next, not a write', (
      tester,
    ) async {
      // The answer is in the database; the learner was reading it when the app
      // was taken away. Submitting again here would be the same turn recorded
      // twice (BR-129).
      final outcomes = <RecallOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1', isRevealed: true),
            initialRemaining: Duration.zero,
            onOutcome: (outcome) async {
              outcomes.add(outcome);

              return commitOf('c1');
            },
          ),
          isScrollable: false,
        ),
      );
      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();

      expect(find.text('công'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Remembered'), findsNothing);
      expect(outcomes, isEmpty);
    });

    testWidgets('the same card in a later round is a new turn (BR-116)', (
      tester,
    ) async {
      // **The bug this is here for shipped, and only a slow device found it.** A
      // recall turn that runs out of time is enrolled into the next round, and
      // that round serves the **same** `cardId`. The widget compared ids alone,
      // read the new turn as the old one, kept its phase claimed — and drew a
      // settled turn over a live question with nothing to press.
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) async => commitOf('c1'),
          ),
          isScrollable: false,
        ),
      );
      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget, reason: 'timed out');

      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1', round: 2),
            onOutcome: (_) async => commitOf('c1'),
          ),
          isScrollable: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // A full twenty seconds, a covered answer, and a question again.
      expect(find.text('Show answer'), findsOneWidget);
      expect(find.text('công'), findsNothing);
      expect(find.textContaining("Time's up"), findsNothing);

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();
    });
  });

  group('recall · while the session is busy', () {
    testWidgets('a locked turn offers nothing to press', (tester) async {
      // The card stays on screen while the session fetches the next one
      // (BR-158); what it must not do is take another answer for a turn that is
      // already leaving.
      final outcomes = <RecallOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            isLocked: true,
            onOutcome: (outcome) async {
              outcomes.add(outcome);

              return commitOf('c1');
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('Show answer'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Show answer'), findsOneWidget);
      expect(find.text('Remembered'), findsNothing);
      expect(outcomes, isEmpty);

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();
    });
  });
}
