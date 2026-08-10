import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';

import 'support/recall_turn_fixture.dart';
import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// Twenty seconds, a look at the back, and **then** an answer.
///
/// **What this file is here to stop is the mode grading a glance.** *Show
/// answer* used to write the scheduler's correct action and pull the next card:
/// a learner who gave up at four seconds had the card promoted a box for giving
/// up, and was never asked anything. Every test below is some version of the
/// same question — how many answers did that produce, and who gave them.
///
/// The clock's other ending lives in `recall_timeout_widget_test.dart`; the two
/// were one file until the phases pushed them past the 400-line guard, and the
/// seam is real. This half is the learner's; that half is the clock's.
void main() {
  group('recall · before anything is written', () {
    testWidgets('opens on the front alone, with nothing recorded', (
      tester,
    ) async {
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

      expect(find.text('front-c1'), findsOneWidget);
      expect(find.text('công'), findsNothing);
      // A blurred bar rather than a sentence: a line of text where the answer
      // will appear is a line a learner reads instead of recalling.
      expect(find.bySemanticsLabel('Answer hidden'), findsOneWidget);
      expect(find.text('Show answer'), findsOneWidget);
      expect(outcomes, isEmpty);

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();
    });

    testWidgets('showing the answer stops the clock and writes nothing', (
      tester,
    ) async {
      // **The whole point of the change, in one test.** Looking at the back is
      // not evidence of recall, so the reveal produces a question rather than a
      // grade — and the clock has no business running under a card the learner
      // is already reading.
      final outcomes = <RecallOutcome>[];
      final reported = <Duration>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (outcome) async {
              outcomes.add(outcome);

              return commitOf('c1');
            },
            onRemainingChanged: reported.add,
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Show answer'));
      await tester.pump();

      expect(find.text('công'), findsOneWidget);
      expect(find.text('Forgot'), findsOneWidget);
      expect(find.text('Remembered'), findsOneWidget);
      expect(outcomes, isEmpty, reason: 'a reveal is not an answer');

      // The clock is stopped, not merely ignored: nothing new is reported and
      // no timeout lands where the mark would have been.
      final atReveal = reported.last;
      await tester.pump(kRecallTurnLimit * 2);
      await tester.pumpAndSettle();

      expect(reported.last, atReveal);
      expect(outcomes, isEmpty);
      expect(find.text('Remembered'), findsOneWidget);
    });
  });

  group('recall · the learner answers', () {
    /// Every assessment path is the same three questions, so they are asked
    /// once: how many writes, in which order against the advance, and what was
    /// written.
    Future<
      ({List<RecallOutcome> outcomes, List<String> order, List<bool> shown})
    >
    answer(WidgetTester tester, String label, {StudyTurnModel? turn}) async {
      final outcomes = <RecallOutcome>[];
      final order = <String>[];
      final shown = <bool>[];

      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turn ?? recallTurn('c1'),
            onOutcome: (outcome) async {
              outcomes.add(outcome);
              order.add('write');

              return commitOf('c1');
            },
            onFeedbackShown: ({required isCorrect}) async {
              order.add('advance');
              shown.add(isCorrect);
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      return (outcomes: outcomes, order: order, shown: shown);
    }

    testWidgets('Remembered writes one correct answer, then advances', (
      tester,
    ) async {
      final result = await answer(tester, 'Remembered');

      expect(result.outcomes, <RecallOutcome>[RecallOutcome.remembered]);
      expect(result.order, <String>['write', 'advance'], reason: 'BR-157');
      expect(result.shown, <bool>[true]);
    });

    testWidgets('Forgot writes one wrong answer, then advances', (
      tester,
    ) async {
      final result = await answer(tester, 'Forgot');

      expect(result.outcomes, <RecallOutcome>[RecallOutcome.forgotten]);
      expect(result.order, <String>['write', 'advance']);
      expect(result.shown, <bool>[false]);
    });

    testWidgets('nothing is held between the commit and the next card', (
      tester,
    ) async {
      // **`recall` no longer has a reading budget, and that is a decision.** The
      // learner reads the back *before* answering, so a hold afterwards pauses
      // them on something they are done with. Asserted by settling nothing: if
      // the mode still waited out 1800ms, this advance would not have arrived.
      final order = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) async => commitOf('c1'),
            onFeedbackShown: ({required isCorrect}) async =>
                order.add('advance'),
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text('Remembered'));
      await tester.pump();

      expect(order, <String>['advance']);
    });

    testWidgets('a second tap during the write is not a second answer', (
      tester,
    ) async {
      // The write takes long enough for a second tap to land inside it, and a
      // second turn would grade the same card twice in one round (BR-25,
      // BR-126).
      var writes = 0;
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) {
              writes += 1;

              return write.future;
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text('Remembered'));
      await tester.pump();
      await tester.tap(find.text('Remembered'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('Forgot'), warnIfMissed: false);
      await tester.pump();

      expect(writes, 1);

      write.commit('c1');
      await tester.pumpAndSettle();
    });

    testWidgets('a refused write leaves the choice open to try again', (
      tester,
    ) async {
      // Not advancing is half of it. The other half is that the learner keeps
      // the answer they were giving: a screen that swallowed the tap and left
      // two live buttons would be indistinguishable from one that recorded it.
      final write = PendingCommit();
      PendingCommit? write2;
      var writes = 0;
      final shown = <bool>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) {
              writes += 1;

              return (write2 ?? write).future;
            },
            onFeedbackShown: ({required isCorrect}) async =>
                shown.add(isCorrect),
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text('Forgot'));
      await tester.pump();
      write.refuse();
      await tester.pumpAndSettle();

      expect(shown, isEmpty, reason: 'nothing was recorded, so nothing moves');
      expect(find.text('công'), findsOneWidget, reason: 'the back stays up');
      expect(find.text('Forgot'), findsOneWidget);
      expect(find.text('Remembered'), findsOneWidget);

      // Live, not merely drawn: the retry is the reason the buttons came back.
      final second = PendingCommit();
      write2 = second;
      await tester.tap(find.text('Forgot'));
      await tester.pump();

      expect(writes, 2);
      second.commit('c1');
      await tester.pumpAndSettle();
    });
  });

  group('recall · what the app being taken away writes down (BR-133)', () {
    testWidgets('an open turn reports what is left, once', (tester) async {
      // BR-128 stops the clock when the app leaves the foreground. Without this
      // report the seconds it stopped at are lost, and the turn starts over at
      // twenty the next time it is served — which is the whole reason
      // `remaining_ms` is a column.
      final suspended = <({Duration remaining, bool isRevealed})>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) async => commitOf('c1'),
            onSuspended: ({required remaining, required isRevealed}) =>
                suspended.add((remaining: remaining, isRevealed: isRevealed)),
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(const Duration(seconds: 6));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(suspended, hasLength(1));
      expect(suspended.single.remaining.inSeconds, 14);
      expect(suspended.single.isRevealed, isFalse);

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();
    });

    testWidgets('a revealed turn reports the reveal, not just the clock', (
      tester,
    ) async {
      // **`isRevealed: true` was unreachable and is now the ordinary case.** A
      // learner interrupted between the reveal and the verdict has to come back
      // to the back of the card — resuming them into a running clock over a
      // covered answer would ask them to un-know it.
      final suspended = <({Duration remaining, bool isRevealed})>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) async => commitOf('c1'),
            onSuspended: ({required remaining, required isRevealed}) =>
                suspended.add((remaining: remaining, isRevealed: isRevealed)),
          ),
          isScrollable: false,
        ),
      );

      await tester.pump(const Duration(seconds: 8));
      await tester.tap(find.text('Show answer'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(suspended, hasLength(1));
      expect(suspended.single.isRevealed, isTrue);
      expect(suspended.single.remaining.inSeconds, 12);
    });

    testWidgets('a turn already being written reports nothing', (tester) async {
      // The row it would be saved against is no longer pending. The repository
      // refuses it anyway; not asking is the half that does not depend on
      // anyone remembering to.
      final suspended = <Duration>[];
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: recallTurn('c1'),
            onOutcome: (_) => write.future,
            onSuspended: ({required remaining, required isRevealed}) =>
                suspended.add(remaining),
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text('Remembered'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(suspended, isEmpty);

      write.commit('c1');
      await tester.pumpAndSettle();
    });
  });
}
