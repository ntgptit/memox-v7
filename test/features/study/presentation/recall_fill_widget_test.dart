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
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(
            turn: turnOf('c1'),
            initialRemaining: const Duration(seconds: 4),
            onOutcome: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3s'), findsOneWidget);
      expect(find.text('19s'), findsNothing);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.text("Time's up"), findsOneWidget);
    });

    testWidgets('a later round starts the full limit again (BR-133)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(turn: turnOf('c1'), onOutcome: (_) {}),
        ),
      );
      await tester.pump(const Duration(seconds: 5));

      await tester.pumpWidget(
        wrapForTest(
          RecallTimerSectionWidget(turn: turnOf('c2'), onOutcome: (_) {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // A turn of a different card is a different turn.
      expect(find.text('19s'), findsOneWidget);

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
