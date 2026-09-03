import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/fill_harness.dart';

/// The lower card of `fill`: it **is** the input, it wears the verdict, and the
/// row under it does not move.
///
/// Split from `fill_widget_test.dart` at the guard's 400-line mark, the same
/// seam `guess` took at #269. The fixture is shared, so the two files are two
/// halves of one screen rather than two screens.
void main() {
  group('fill · the answer card is the input surface', () {
    testWidgets('there is no field with an outline of its own inside it', (
      tester,
    ) async {
      // **The shape this task removed.** An `MxTextField` in the middle of the
      // card drew a second rounded rectangle inside the first, and the target
      // was a fifth of the surface that looked like one.
      await pumpFill(tester, fillTurnOf('c1'));

      expect(find.byType(MxTextField), findsNothing);

      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      // Every state, not just the base one: the theme supplies the other five
      // independently, so clearing `border` alone leaves the outline to appear
      // the moment the field takes focus.
      expect(decoration.border, InputBorder.none);
      expect(decoration.enabledBorder, InputBorder.none);
      expect(decoration.focusedBorder, InputBorder.none);
      expect(decoration.disabledBorder, InputBorder.none);
      expect(decoration.errorBorder, InputBorder.none);
      expect(decoration.focusedErrorBorder, InputBorder.none);
    });

    testWidgets('the editable fills the card it sits in', (tester) async {
      await pumpFill(tester, fillTurnOf('c1'));

      final card = tester.getSize(fillAnswerCard());
      final field = tester.getSize(find.byType(TextField));

      // The card's own padding is all that separates them; anything more is a
      // box inside a box.
      expect(field.height, closeTo(card.height - AppSpacing.lg * 2, 1));
      expect(field.width, closeTo(card.width - AppSpacing.lg * 2, 1));
    });

    testWidgets('tapping the card away from the editable starts typing', (
      tester,
    ) async {
      await pumpFill(tester, fillTurnOf('c1'));
      expect(isFillFieldFocused(tester), isFalse);

      // Inside the card, inside its padding, outside the editable.
      final corner = tester.getRect(fillAnswerCard()).topLeft;
      await tester.tapAt(corner + const Offset(AppSpacing.sm, AppSpacing.sm));
      await tester.pump();

      expect(isFillFieldFocused(tester), isTrue);
    });

    testWidgets('the field is named for a screen reader without a label', (
      tester,
    ) async {
      // The concept draws no floating label — the card is the field — so the
      // name has to exist somewhere other than in a painted string. Once, not
      // twice: the placeholder says the same words and is excluded from
      // semantics so it does not announce the field's name a second time.
      await pumpFill(tester, fillTurnOf('c1'));
      expect(find.bySemanticsLabel('Type the answer'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '사');
      await tester.pump();

      expect(
        find.bySemanticsLabel('Type the answer'),
        findsOneWidget,
        reason: 'the name survives the placeholder leaving',
      );
    });
  });

  group('fill · the row of actions does not move', () {
    testWidgets('a hint is recorded and does not change the outcome (BR-136)', (
      tester,
    ) async {
      final graded = await pumpFill(
        tester,
        fillTurnOf('c1', hint: 'bắt đầu bằng 사'),
      );

      await tester.tap(find.text('Show hint'));
      await tester.pump();
      expect(find.text('bắt đầu bằng 사'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '사과');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(graded.single.hasUsedHint, isTrue);
      // The hint is a note on the turn, not a penalty.
      expect(graded.single.isCorrect, isTrue);
    });

    testWidgets('using the hint leaves Check exactly where it was', (
      tester,
    ) async {
      // The slot stays and goes quiet. Removing it re-centred the row and slid
      // the primary action under a finger already on its way down.
      await pumpFill(tester, fillTurnOf('c1', hint: 'bắt đầu bằng 사'));

      final before = tester.getRect(find.text('Check'));
      await tester.tap(find.text('Show hint'));
      await tester.pump();

      expect(find.text('Show hint'), findsOneWidget);
      expect(tester.getRect(find.text('Check')), before);
    });

    testWidgets('the hint sits in the prompt card, not between the two', (
      tester,
    ) async {
      await pumpFill(tester, fillTurnOf('c1', hint: 'bắt đầu bằng 사'));

      final answerTop = tester.getRect(fillAnswerCard()).top;
      await tester.tap(find.text('Show hint'));
      await tester.pump();

      expect(
        tester.getRect(fillAnswerCard()).top,
        answerTop,
        reason: 'a hint must not push the answer card down',
      );
      expect(
        tester.getRect(find.text('bắt đầu bằng 사')).bottom,
        lessThan(answerTop),
      );
    });
  });

  group('fill · the verdict is worn by the answer card', () {
    testWidgets('a wrong turn shows the card-s front, never the input', (
      tester,
    ) async {
      // BR-138: what the learner typed is never stored, and never echoed back
      // either. The Korean term is what is shown, because that is what was
      // missed.
      await pumpFill(tester, fillTurnOf('c1'));

      await tester.enterText(find.byType(TextField), '바다');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.text('Not quite'), findsOneWidget);
      expect(find.text('The answer'), findsOneWidget);
      expect(find.text('사과'), findsOneWidget);
      expect(find.text('바다'), findsNothing);
      // The field is gone rather than merely disabled: the lower card holds one
      // thing at a time, and once the turn is graded that thing is the verdict.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a wrong turn does not repeat the meaning', (tester) async {
      // It is on the card directly above, and saying it twice on one screen
      // buries the one string the learner did not have.
      await pumpFill(tester, fillTurnOf('c1'));

      await tester.enterText(find.byType(TextField), '바다');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.text('quả táo'), findsOneWidget);
    });

    testWidgets('a correct turn confirms without correcting', (tester) async {
      await pumpFill(tester, fillTurnOf('c1'));

      await tester.enterText(find.byType(TextField), '사과');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('The answer'), findsNothing);
      expect(find.text('사과'), findsOneWidget);
    });

    testWidgets('the verdict is the card-s own edge, not a panel inside it', (
      tester,
    ) async {
      await pumpFill(tester, fillTurnOf('c1'));
      final cards = tester.widgetList<MxCard>(find.byType(MxCard)).length;

      await tester.enterText(find.byType(TextField), '바다');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(
        tester.widgetList<MxCard>(find.byType(MxCard)),
        hasLength(cards),
        reason: 'a graded turn must not add a surface',
      );
      // The closed API spells the verdict as a recessed edge, so the claim is
      // that grading moved the card off its resting edge — the recipe's token
      // mapping itself is pinned in mx_card_test.
      final answerBorder = mxCardEdgeIn(tester, fillAnswerCard());
      final semantic = Theme.of(
        tester.element(fillAnswerCard()),
      ).extension<AppSemanticColors>()!;
      expect(
        answerBorder.color,
        anyOf(semantic.success, semantic.danger),
        reason: 'the graded card wears its verdict on its own edge',
      );
    });
  });
}

/// The topmost edge the `MxCard` found by [within] paints, resting or focus.
///
/// **Foreground layers since M100.33.** The card's fill sits behind its child
/// and every edge in front of it, so an edge-to-edge child can no longer cover a
/// selected or option border. Two consequences for a test: the first
/// `DecoratedBox` under an `MxCard` is now the fill, and "any foreground border
/// on screen" picks up whichever card happens to be focused. Hence the scope —
/// it has to be the card, not the tree.
BorderSide mxCardEdgeIn(WidgetTester tester, Finder within) {
  final borders = tester
      .widgetList<DecoratedBox>(
        find.descendant(of: within, matching: find.byType(DecoratedBox)),
      )
      .where(
        (DecoratedBox box) => box.position == DecorationPosition.foreground,
      )
      .map((DecoratedBox box) => (box.decoration as BoxDecoration).border)
      .whereType<Border>()
      .toList();

  return borders.first.top;
}
