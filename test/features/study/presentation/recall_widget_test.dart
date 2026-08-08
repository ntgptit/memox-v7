import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';

import 'support/study_widget_harness.dart';

/// Twenty seconds, one outcome, and what is written down when the app is taken
/// away.
///
/// **Split from `fill` at the 400-line guard, and the seam is a real one.** The
/// two shared a file while both were "a card and one control"; the second states
/// and BR-133's suspend path pushed the pair past the limit, and they were never
/// one subject — one is a clock, the other is a text field.
void main() {
  StudyTurnModel turnOf(
    String id, {
    String back = 'công',
    String? hint,
    String? example,
    int round = 1,
  }) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 's1',
      mode: StudyMode.recall,
      round: round,
      cardId: id,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
    ),
    progress: StudyStageProgressModel(
      round: round,
      done: 0,
      total: 1,
      completedCardIds: const <String>[],
    ),
    card: StudyCardModel(
      id: id,
      front: 'front-$id',
      back: back,
      example: example,
      hint: hint,
      pronunciation: null,
      backFolded: back,
    ),
  );

  group('recall', () {
    testWidgets('a resumed turn starts at the time it was left (BR-133)', (
      tester,
    ) async {
      // The half of resuming a session that the user actually feels. Reading
      // the stored session back but restarting the clock at the full limit
      // would be a free extension of every paused turn, and the resume path
      // would look correct in every other respect.
      final outcomes = <RecallOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turnOf('c1'),
            initialRemaining: const Duration(seconds: 3),
            onOutcome: outcomes.add,
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(outcomes, <RecallOutcome>[RecallOutcome.timedOut]);
    });

    testWidgets('running out reveals the answer and locks it wrong', (
      tester,
    ) async {
      final outcomes = <RecallOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(turn: turnOf('c1'), onOutcome: outcomes.add),
        ),
      );

      expect(find.text('công'), findsNothing);

      await tester.pump(kRecallTurnLimit);
      await tester.pump();

      expect(outcomes, <RecallOutcome>[RecallOutcome.timedOut]);
      // The user still learns the card they just lost (BR-130).
      expect(find.text('công'), findsOneWidget);
      // One line, not two: the verdict and why there is no button left belong
      // together, so the sentence is matched rather than the phrase.
      expect(find.textContaining("Time's up"), findsOneWidget);
    });

    testWidgets('a reveal before the mark is the only outcome (BR-129)', (
      tester,
    ) async {
      // The race the rule is written for: one tap, then the clock runs past
      // zero. Exactly one outcome may reach the caller.
      final outcomes = <RecallOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(turn: turnOf('c1'), onOutcome: outcomes.add),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Show answer'));
      await tester.pump();

      await tester.pump(kRecallTurnLimit);
      await tester.pump();

      expect(outcomes, <RecallOutcome>[RecallOutcome.revealed]);
    });

    testWidgets('a resumed turn keeps what was left, not a fresh limit', (
      tester,
    ) async {
      // BR-133: Resume continues the turn. Restarting at twenty seconds hands
      // back time the user already spent.
      //
      // Read from what the widget *reports* rather than from what it draws: the
      // countdown itself now lives in the session frame's top bar (§7.3), and
      // this widget's job is to own the clock and say what is left.
      final reported = <Duration>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turnOf('c1'),
            initialRemaining: const Duration(seconds: 4),
            onOutcome: (_) {},
            onRemainingChanged: reported.add,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(reported.last.inSeconds, 3);
      expect(reported.any((left) => left.inSeconds >= 19), isFalse);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      // One line, not two: the verdict and why there is no button left belong
      // together, so the sentence is matched rather than the phrase.
      expect(find.textContaining("Time's up"), findsOneWidget);
    });

    testWidgets('a later round starts the full limit again (BR-133)', (
      tester,
    ) async {
      final reported = <Duration>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turnOf('c1'),
            onOutcome: (_) {},
            onRemainingChanged: reported.add,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 5));

      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turnOf('c2'),
            onOutcome: (_) {},
            onRemainingChanged: reported.add,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // A turn of a different card is a different turn.
      expect(reported.last.inSeconds, 19);

      await tester.pump(kRecallTurnLimit);
    });

    testWidgets('the same card in a later round is a new turn (BR-116)', (
      tester,
    ) async {
      // **The bug this is here for shipped, and only a slow device found it.**
      // A recall turn that runs out of time is enrolled into the next round,
      // and that round serves the **same** `cardId`. The widget compared ids
      // alone, read the new turn as the old one, kept its outcome claimed — and
      // drew "this turn is settled" over a live question with nothing to press.
      // The integration suite hit it the first time a turn actually timed out.
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(turn: turnOf('c1'), onOutcome: (_) {}),
        ),
      );
      await tester.pump(kRecallTurnLimit);
      expect(find.text('Show answer'), findsNothing, reason: 'timed out');

      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turnOf('c1', round: 2),
            onOutcome: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Answerable again, because it is a question the user has not answered.
      expect(find.text('Show answer'), findsOneWidget);

      await tester.pump(kRecallTurnLimit);
    });
  });

  group('the second state the design has no image for', () {
    // Drawn from BR-129, BR-130, BR-134 and BR-137 rather than guessed, and
    // recorded as an agent proposal in `docs/wireframes/m5-study-modes.md` §6.
    testWidgets('recall, once revealed, offers nothing further and says why', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(turn: turnOf('c1'), onOutcome: (_) {}),
        ),
      );

      expect(find.text('Answer hidden'), findsOneWidget);
      expect(find.text('công'), findsNothing);

      await tester.tap(find.text('Show answer'));
      await tester.pump();

      expect(find.text('công'), findsOneWidget);
      expect(find.text('Show answer'), findsNothing);
      // Without the sentence, an answer on screen and no control looks exactly
      // like a screen that stopped responding.
      expect(find.textContaining('This turn is settled'), findsOneWidget);

      await tester.pump(kRecallTurnLimit);
    });
  });

  group('what the clock writes down when the app is taken away (BR-133)', () {
    testWidgets('an open turn reports what is left, once', (tester) async {
      // BR-128 stops the clock when the app leaves the foreground. Without this
      // report the seconds it stopped at are lost, and the turn starts over at
      // twenty the next time it is served — which is the whole reason
      // `remaining_ms` is a column.
      final suspended = <({Duration remaining, bool isRevealed})>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turnOf('c1'),
            onOutcome: (_) {},
            onSuspended: ({required remaining, required isRevealed}) =>
                suspended.add((remaining: remaining, isRevealed: isRevealed)),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 6));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(suspended, hasLength(1));
      expect(suspended.single.remaining.inSeconds, 14);
      expect(suspended.single.isRevealed, isFalse);

      await tester.pump(kRecallTurnLimit);
    });

    testWidgets('a turn that already has an outcome reports nothing', (
      tester,
    ) async {
      // Revealing *is* the outcome (BR-129), so the row this would be written
      // against is no longer pending. The repository refuses it anyway; not
      // asking is the half that does not depend on remembering to.
      final suspended = <Duration>[];
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turnOf('c1'),
            onOutcome: (_) {},
            onSuspended: ({required remaining, required isRevealed}) =>
                suspended.add(remaining),
          ),
        ),
      );

      await tester.tap(find.text('Show answer'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(suspended, isEmpty);
    });
  });
}
