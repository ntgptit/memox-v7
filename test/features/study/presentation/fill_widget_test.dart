import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fill_harness.dart';

/// Read the meaning, type the term — and what a submit costs.
///
/// The fixture and the finders live in `support/fill_harness.dart`; the card
/// that *is* the field is `fill_answer_surface_test.dart`.
void main() {
  group('fill · the question and the answer are the two sides of one card', () {
    testWidgets('the prompt is the meaning, which is the card-s back', (
      tester,
    ) async {
      await pumpFill(tester, fillTurnOf('c1'));

      expect(find.text('quả táo'), findsOneWidget);
    });

    testWidgets('the prompt is never the term the learner has to produce', (
      tester,
    ) async {
      // Both readings of the old prompt: the example sentence, which contains
      // the answer, and the front, which *is* the answer. Either one asks and
      // answers the same question.
      await pumpFill(tester, fillTurnOf('c1', example: '사과를 먹었어요.'));

      expect(find.text('사과'), findsNothing);
      expect(find.text('사과를 먹었어요.'), findsNothing);
    });

    testWidgets('typing the Korean term is correct (BR-134)', (tester) async {
      final graded = await pumpFill(tester, fillTurnOf('c1'));

      await tester.enterText(find.byType(TextField), '사과');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded.single.isCorrect, isTrue);
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('typing the meaning back is not an answer', (tester) async {
      // The regression the direction change exists for: graded against the back
      // this was the *right* answer.
      final graded = await pumpFill(tester, fillTurnOf('c1'));

      await tester.enterText(find.byType(TextField), 'quả táo');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded.single.isCorrect, isFalse);
    });

    testWidgets('case and surrounding space do not count', (tester) async {
      final graded = await pumpFill(tester, fillTurnOf('c1', front: 'Công'));

      await tester.enterText(find.byType(TextField), '  CÔNG ');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded.single.isCorrect, isTrue);
    });

    testWidgets('diacritics decide the outcome (BR-134)', (tester) async {
      final graded = await pumpFill(tester, fillTurnOf('c1', front: 'công'));

      await tester.enterText(find.byType(TextField), 'cong');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded.single.isCorrect, isFalse);
      expect(find.text('Not quite'), findsOneWidget);
    });
  });

  group('fill · what a submit costs', () {
    testWidgets('an empty answer records nothing (BR-137)', (tester) async {
      final graded = await pumpFill(tester, fillTurnOf('c1'));

      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded, isEmpty);
    });

    testWidgets('Check is disabled until there is something to check', (
      tester,
    ) async {
      await pumpFill(tester, fillTurnOf('c1'));

      expect(
        tester.widget<ButtonStyleButton>(fillCheckButton()).enabled,
        isFalse,
      );

      await tester.enterText(find.byType(TextField), '  ');
      await tester.pump();
      expect(
        tester.widget<ButtonStyleButton>(fillCheckButton()).enabled,
        isFalse,
        reason: 'whitespace is not an answer (BR-137)',
      );

      await tester.enterText(find.byType(TextField), '사과');
      await tester.pump();
      expect(
        tester.widget<ButtonStyleButton>(fillCheckButton()).enabled,
        isTrue,
      );
    });

    testWidgets('IME Done takes the same path as Check', (tester) async {
      final graded = await pumpFill(tester, fillTurnOf('c1'));

      await tester.enterText(find.byType(TextField), '사과');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(graded.single.isCorrect, isTrue);
    });

    testWidgets('Done on an empty field is not an answer either', (
      tester,
    ) async {
      final graded = await pumpFill(tester, fillTurnOf('c1'));

      await tester.showKeyboard(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(graded, isEmpty);
    });

    testWidgets('Check then Done is still one write', (tester) async {
      final graded = await pumpFill(tester, fillTurnOf('c1'));

      await tester.enterText(find.byType(TextField), '사과');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(graded, hasLength(1));
    });
  });

  group('fill · a new turn starts clean', () {
    testWidgets('a new card clears the field, the hint and the verdict', (
      tester,
    ) async {
      await pumpFill(tester, fillTurnOf('c1', hint: 'h'));
      await tester.enterText(find.byType(TextField), '바다');
      await tester.pump();
      await tester.tap(find.text('Show hint'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      expect(find.text('Not quite'), findsOneWidget);

      await pumpFill(tester, fillTurnOf('c2', hint: 'h'));
      await tester.pump();

      expect(find.text('바다'), findsNothing);
      expect(find.text('Not quite'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('the same card in a later round resets just as fully', (
      tester,
    ) async {
      // BR-116 sends a failed card round again with the same id, so comparing
      // ids alone leaves the previous attempt on screen over a live question.
      await pumpFill(tester, fillTurnOf('c1', hint: 'h'));
      await tester.enterText(find.byType(TextField), '바다');
      await tester.pump();
      await tester.tap(find.text('Show hint'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      await pumpFill(tester, fillTurnOf('c1', hint: 'h', round: 2));
      await tester.pump();

      expect(find.text('Not quite'), findsNothing);
      expect(find.text('h'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('the keyboard carries over to the next card', (tester) async {
      // `fill` is answered by typing, several cards in a row. Reaching for the
      // card again after every turn is the cost of losing this.
      await pumpFill(tester, fillTurnOf('c1'));
      await tester.showKeyboard(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '사과');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      await pumpFill(tester, fillTurnOf('c2'));
      await tester.pumpAndSettle();

      expect(isFillFieldFocused(tester), isTrue);
    });

    testWidgets('a card answered without the keyboard does not summon it', (
      tester,
    ) async {
      // Somebody who dismissed the keyboard before checking is not asking for
      // it back.
      await pumpFill(tester, fillTurnOf('c1'));
      await tester.enterText(find.byType(TextField), '사과');
      await tester.pump();
      tester.testTextInput.hide();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      await tester.tap(find.text('Check'));
      await tester.pump();

      await pumpFill(tester, fillTurnOf('c2'));
      await tester.pumpAndSettle();

      expect(isFillFieldFocused(tester), isFalse);
    });
  });
}
