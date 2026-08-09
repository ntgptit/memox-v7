import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/items/guess_option_item_widget.dart';

import '../../features/study/presentation/support/study_widget_harness.dart';

/// `HOST-WIDGET` for IT-MODE-013 step 2 — the graded options read as words.
///
/// **Steps 1, 3 and 4 are already proven and are not repeated here.**
/// `study_accessibility_test.dart` covers the session bar, its contrast and the
/// whole frame at 320×568 with double text; `recall_widget_test.dart` covers
/// "Answer hidden"; `match_board_widget_test.dart` and
/// `match_board_feedback_test.dart` cover the tile's spoken value. `Guess` was
/// the one surface with no assertion of its own, and it is the one with the
/// most to get wrong, because its verdict is carried by a fill colour and a
/// glyph — neither of which a screen reader reads.
///
/// The second half of the step is the letter. A–E is a handle for the eye and a
/// seat number that changes with the next shuffle (BR-127); announced, it turns
/// every row into "A, apple" and puts a throwaway token in front of the meaning
/// the learner is choosing between. `ExcludeSemantics` is what keeps it out, and
/// nothing else in the suite would notice it being removed.
void main() {
  Future<void> pumpOption(
    WidgetTester tester,
    GuessOptionState state, {
    double textScale = 1,
  }) => tester.pumpWidget(
    wrapForTest(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: GuessOptionItemWidget(
          text: 'to give up',
          state: state,
          onTap: state == GuessOptionState.open ? () {} : null,
        ),
      ),
    ),
  );

  testWidgets('IT-MODE-013 · a row announces the meaning and nothing else', (
    tester,
  ) async {
    // The A–E badge this once guarded is gone: it took 44pt off every row, and
    // the content this app is for runs to three lines. What the step still
    // needs is that the row reads as its meaning — so the assertion is that
    // there is one string on the row and it is the one being chosen between.
    await pumpOption(tester, GuessOptionState.open);

    expect(find.text('to give up'), findsOneWidget);
    for (final letter in <String>['A', 'B', 'C', 'D', 'E']) {
      expect(
        find.text(letter),
        findsNothing,
        reason: 'a seat letter is a fact about the row that BR-127 reshuffles',
      );
    }
  });

  testWidgets('IT-MODE-013 · a graded option says its verdict in words, not '
      'only in colour', (tester) async {
    for (final (state, spoken) in <(GuessOptionState, String)>[
      (GuessOptionState.correct, 'Correct answer'),
      (GuessOptionState.chosenWrong, 'Your answer, incorrect'),
    ]) {
      await pumpOption(tester, state);

      expect(
        tester.getSemantics(find.text('to give up')).value,
        spoken,
        reason:
            'the fill and the tick carry $state for people who can see them; '
            'this is the same fact for everyone else',
      );
    }
  });

  testWidgets('IT-MODE-013 · an option still awaiting an answer claims no '
      'verdict', (tester) async {
    // The negative case is the one that rots: a widget that announced a value
    // unconditionally would pass both assertions above and read every untouched
    // row as graded.
    for (final state in <GuessOptionState>[
      GuessOptionState.open,
      GuessOptionState.dimmed,
    ]) {
      await pumpOption(tester, state);

      expect(tester.getSemantics(find.text('to give up')).value, isEmpty);
    }
  });

  testWidgets('IT-MODE-013 · a graded option lays out at 200% text', (
    tester,
  ) async {
    // Step 4 for the row itself: the meaning is user content of unknown length,
    // so this is where doubling the text finds a fixed height first.
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpOption(tester, GuessOptionState.correct, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
