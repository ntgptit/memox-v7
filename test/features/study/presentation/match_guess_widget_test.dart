import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/guess_question_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';

import 'support/study_widget_harness.dart';

/// The two graded screens, and the four ways they must not grade.
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

  group('the match board', () {
    final board = const MatchModeHandler().buildBoard(<StudyCardModel>[
      card('a'),
      card('b'),
      card('c'),
    ], Random(1))!;

    testWidgets('a meaning tapped with no term chosen is not an answer', (
      tester,
    ) async {
      // Guessing which term it "probably" meant would record a turn the user
      // never gave.
      final attempts = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (term, {required isCorrect}) =>
                attempts.add(term.cardId),
          ),
        ),
      );

      await tester.tap(find.text('back-a'));
      await tester.pump();

      expect(attempts, isEmpty);
    });

    testWidgets('the turn belongs to the term, not the meaning (BR-118)', (
      tester,
    ) async {
      // Picking b's meaning after choosing a's term marks **a** failed. Card b
      // was never being asked about, and grading it would punish a card for
      // sitting on the board.
      final attempts = <({String cardId, bool isCorrect})>[];
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (term, {required isCorrect}) =>
                attempts.add((cardId: term.cardId, isCorrect: isCorrect)),
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-b'));
      await tester.pump();

      expect(attempts, <({String cardId, bool isCorrect})>[
        (cardId: 'a', isCorrect: false),
      ]);
    });

    testWidgets('a correct pair leaves the board', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) {},
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();

      expect(find.text('front-a'), findsNothing);
      expect(find.text('back-a'), findsNothing);
      expect(find.text('front-b'), findsOneWidget);
    });

    testWidgets('a locked board records nothing', (tester) async {
      final attempts = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            isLocked: true,
            onPairAttempt: (term, {required isCorrect}) =>
                attempts.add(term.cardId),
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();

      expect(attempts, isEmpty);
    });
  });

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
          GuessQuestionSectionWidget(question: question, onChosen: (_) {}),
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
            onChosen: (option) => chosen.add(option.cardId),
          ),
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
            onChosen: (option) => chosen.add(option.cardId),
          ),
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
            onChosen: (option) => chosen.add(option.cardId),
          ),
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
  });
}
