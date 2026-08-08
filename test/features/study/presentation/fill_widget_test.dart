import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/fill_mode.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/fill_answer_section_widget.dart';

import 'support/study_widget_harness.dart';

/// Typing the answer, and what happens to it afterwards — which is nothing
/// (BR-138).
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
    progress: const StudyStageProgressModel(
      round: 1,
      done: 0,
      total: 1,
      completedCardIds: <String>[],
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

  group('the second state the design has no image for', () {
    // Drawn from BR-134, BR-137 and BR-138 rather than guessed, and recorded as
    // an agent proposal in `docs/wireframes/m5-study-modes.md` §6.1.
    testWidgets('fill, once graded, shows the card-s own back, not the input', (
      tester,
    ) async {
      // BR-138: what the learner typed is never stored, and never echoed back
      // either. The card is what is shown.
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(turn: turnOf('c1'), onGraded: (_) {}),
        ),
      );

      await tester.enterText(find.byType(TextField), 'cong');
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.text('Not quite'), findsOneWidget);
      expect(find.text('The answer: công'), findsOneWidget);
      expect(find.text('Check'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('and a correct fill does not spell the answer back', (
      tester,
    ) async {
      // The counterpart: the line exists to tell somebody what they missed, and
      // showing it to somebody who got it right reads as a correction.
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(turn: turnOf('c1'), onGraded: (_) {}),
        ),
      );

      await tester.enterText(find.byType(TextField), 'công');
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.text('Correct'), findsOneWidget);
      expect(find.textContaining('The answer:'), findsNothing);
    });
  });
}
