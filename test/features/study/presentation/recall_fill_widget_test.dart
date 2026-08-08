import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/fill_mode.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/fill_answer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';

import 'support/study_widget_harness.dart';

/// The clock and the text field, and the four ways they must not record.
void main() {
  StudyTurnModel turnOf(
    String id, {
    String back = 'công',
    String? hint,
    String? example,
  }) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 's1',
      mode: StudyMode.recall,
      round: 1,
      cardId: id,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
    ),
    progress: const StudyStageProgressModel(done: 0, total: 1),
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
      expect(find.text("Time's up"), findsOneWidget);
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
      expect(find.text("Time's up"), findsOneWidget);
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
  });

  group('fill', () {
    testWidgets('an empty answer records nothing (BR-137)', (tester) async {
      final graded = <FillOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(turn: turnOf('c1'), onGraded: graded.add),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded, isEmpty);
    });

    testWidgets('diacritics decide the outcome (BR-134)', (tester) async {
      final graded = <FillOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(turn: turnOf('c1'), onGraded: graded.add),
        ),
      );

      await tester.enterText(find.byType(TextField), 'cong');
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded.single.isCorrect, isFalse);
      expect(find.text('Not quite'), findsOneWidget);
    });

    testWidgets('a matching answer is correct despite case and spaces', (
      tester,
    ) async {
      final graded = <FillOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(turn: turnOf('c1'), onGraded: graded.add),
        ),
      );

      await tester.enterText(find.byType(TextField), '  CÔNG ');
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded.single.isCorrect, isTrue);
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('a second submit on the same card records nothing', (
      tester,
    ) async {
      final graded = <FillOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(turn: turnOf('c1'), onGraded: graded.add),
        ),
      );

      await tester.enterText(find.byType(TextField), 'công');
      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(graded, hasLength(1));
    });

    testWidgets('a hint is recorded and does not change the outcome (BR-136)', (
      tester,
    ) async {
      final graded = <FillOutcome>[];
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(
            turn: turnOf('c1', hint: 'starts with c'),
            onGraded: graded.add,
          ),
        ),
      );

      await tester.tap(find.text('Show hint'));
      await tester.pump();
      expect(find.text('starts with c'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'công');
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded.single.hasUsedHint, isTrue);
      // The hint is a note on the turn, not a penalty.
      expect(graded.single.isCorrect, isTrue);
    });

    testWidgets('a new card clears the field and the hint', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(
            turn: turnOf('c1', hint: 'h'),
            onGraded: (_) {},
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'công');
      await tester.tap(find.text('Show hint'));
      await tester.pump();

      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(
            turn: turnOf('c2', hint: 'h'),
            onGraded: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('công'), findsNothing);
      expect(find.text('Show hint'), findsOneWidget);
    });
  });
}
