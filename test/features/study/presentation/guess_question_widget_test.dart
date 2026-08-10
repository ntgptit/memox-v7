import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/items/guess_option_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/guess_question_section_widget.dart';

import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// One term, five meanings, and what the screen looks like once one is picked.
///
/// **Its own file rather than another group beside the match board.** They were
/// together while both were a list of taps; the after-answer states pushed the
/// pair past the 400-line guard, and the seam was already there — two screens,
/// two sets of rules.
void main() {
  StudyCardModel card(String id, {String? back}) => StudyCardModel(
    id: id,
    front: 'front-$id',
    back: back ?? 'back-$id',
    example: null,
    hint: null,
    pronunciation: null,
    backFolded: back ?? 'back-$id',
  );

  group('the guess question', () {
    final pool = <StudyCardModel>[for (var i = 0; i < 10; i++) card('c$i')];
    final question = const GuessModeHandler().buildQuestion(
      term: pool.first,
      pool: pool,
      random: Random(2),
    )!;

    testWidgets('renders exactly five options (BR-121)', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: question,
            onChosen: (_) async => commitOf('c'),
          ),
          isScrollable: false,
        ),
      );

      for (final option in question.options) {
        expect(find.text(option.text), findsOneWidget);
      }
      expect(question.options, hasLength(5));
    });

    testWidgets('reports the option by identity, not by its text (BR-125)', (
      tester,
    ) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: question,
            onChosen: (option) async {
              chosen.add(option.cardId);

              return commitOf('c');
            },
          ),
          isScrollable: false,
        ),
      );

      final target = question.options.last;
      await tester.tap(find.text(target.text));
      await tester.pump();

      expect(chosen, <String>[target.cardId]);
    });

    testWidgets('a second tap on the same question records nothing (BR-126)', (
      tester,
    ) async {
      // The window is real: the write takes long enough for a second tap, and a
      // second turn would grade the same card twice in one round.
      final chosen = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: question,
            onChosen: (option) async {
              chosen.add(option.cardId);

              return commitOf('c');
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text(question.options.first.text));
      await tester.pump();
      await tester.tap(find.text(question.options[1].text));
      await tester.pump();

      expect(chosen, hasLength(1));
    });

    testWidgets('the next question can be answered again', (tester) async {
      // Without resetting the guard on a new term, every question after the
      // first is unanswerable.
      final chosen = <String>[];

      Future<void> pump(GuessQuestion q) => tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: q,
            onChosen: (option) async {
              chosen.add(option.cardId);

              return commitOf('c');
            },
          ),
          isScrollable: false,
        ),
      );

      await pump(question);
      await tester.tap(find.text(question.options.first.text));
      await tester.pump();

      final second = const GuessModeHandler().buildQuestion(
        term: pool[1],
        pool: pool,
        random: Random(3),
      )!;
      await pump(second);
      await tester.tap(find.text(second.options.first.text));
      await tester.pump();

      expect(chosen, hasLength(2));
    });
    testWidgets('it reports once when the question stops asking', (
      tester,
    ) async {
      // The frame owns the hint line and only this widget knows the answer is
      // in (§8.11). Reported from the tap handler, never from build: a parent
      // setState during a build is the one way this plumbing goes wrong.
      var resolved = 0;
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: question,
            onChosen: (_) async => commitOf('c'),
            onResolved: () => resolved++,
          ),
          isScrollable: false,
        ),
      );

      expect(resolved, 0);

      await tester.tap(find.text(question.options.first.text));
      await tester.pump();
      expect(resolved, 1);

      // BR-126 allows one turn, so it also allows one report.
      await tester.tap(
        find.text(question.options.last.text),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(resolved, 1);
    });
  });

  group('the guess question after an answer', () {
    // The three states the design has an image for, plus the rule the image
    // cannot show: no further turn is taken (BR-126).
    GuessQuestion questionOf() => GuessQuestion(
      term: card('a'),
      options: <GuessOption>[
        const GuessOption(cardId: 'a', text: 'back-a'),
        const GuessOption(cardId: 'b', text: 'back-b'),
        const GuessOption(cardId: 'c', text: 'back-c'),
        const GuessOption(cardId: 'd', text: 'back-d'),
        const GuessOption(cardId: 'e', text: 'back-e'),
      ],
    );

    Color successOf(WidgetTester tester) => Theme.of(
      tester.element(find.byType(GuessQuestionSectionWidget)),
    ).extension<AppSemanticColors>()!.success;

    Color dangerOf(WidgetTester tester) => Theme.of(
      tester.element(find.byType(GuessQuestionSectionWidget)),
    ).extension<AppSemanticColors>()!.danger;

    testWidgets('marks the right answer even when it was not chosen', (
      tester,
    ) async {
      // A screen that only marks your choice leaves you knowing you were wrong
      // and not what was right.
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: questionOf(),
            onChosen: (_) async => commitOf('c'),
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('back-c'));
      await tester.pump();

      expect(
        tester.widget<Text>(find.text('back-a')).style?.color,
        successOf(tester),
      );
      expect(
        tester.widget<Text>(find.text('back-c')).style?.color,
        dangerOf(tester),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('and takes no second turn (BR-126)', (tester) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: questionOf(),
            onChosen: (option) async {
              chosen.add(option.cardId);

              return commitOf('c');
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('back-c'));
      await tester.pump();
      await tester.tap(find.text('back-a'), warnIfMissed: false);
      await tester.pump();

      expect(chosen, <String>['c']);
    });

    testWidgets('a row carries the meaning and nothing that names a seat', (
      tester,
    ) async {
      // What used to stand here checked that the A–E badge was the row's
      // position rather than the card's name. The badge is gone — it cost 44pt
      // of every row on a 393pt screen, which is a line of meaning on content
      // that runs to three — so the guard moves to the shape underneath it:
      // a row renders exactly one string, the meaning, and BR-125 is carried by
      // `reports the option by identity` above.
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: questionOf(),
            onChosen: (_) async => commitOf('c'),
          ),
          isScrollable: false,
        ),
      );

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(GuessOptionItemWidget).first,
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();

      expect(texts, hasLength(1));
      expect(texts.single, startsWith('back-'));
      for (final letter in <String>['A', 'B', 'C', 'D', 'E']) {
        expect(find.text(letter), findsNothing);
      }
    });
  });
}
