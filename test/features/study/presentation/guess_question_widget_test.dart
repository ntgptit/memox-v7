import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
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
    frontFolded: 'front-$id',
    backFolded: back ?? 'back-$id',
  );

  /// The turn a question belongs to. **Round is part of it**: a card answered
  /// wrongly comes back next round with the same id, and a widget that resets on
  /// the id alone carries the previous visit's verdict into a question nobody
  /// has answered yet.
  StudyTurnModel turnOf(StudyCardModel subject, {int round = 1}) =>
      StudyTurnModel(
        item: StudyQueueItemEntity(
          sessionId: 'session-1',
          mode: StudyMode.guess,
          round: round,
          cardId: subject.id,
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
          total: 5,
          completedCardIds: const <String>[],
        ),
        card: subject,
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
            turn: turnOf(pool.first),
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
            turn: turnOf(pool.first),
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
            turn: turnOf(pool.first),
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
      // Without resetting the guard on a new turn, every question after the
      // first is unanswerable.
      final chosen = <String>[];

      Future<void> pump(GuessQuestion q, StudyTurnModel t) => tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: q,
            turn: t,
            onChosen: (option) async {
              chosen.add(option.cardId);

              return commitOf('c');
            },
          ),
          isScrollable: false,
        ),
      );

      await pump(question, turnOf(pool.first));
      await tester.tap(find.text(question.options.first.text));
      await tester.pump();

      final second = const GuessModeHandler().buildQuestion(
        term: pool[1],
        pool: pool,
        random: Random(3),
      )!;
      await pump(second, turnOf(pool[1]));
      await tester.tap(find.text(second.options.first.text));
      await tester.pump();

      expect(chosen, hasLength(2));
    });

    testWidgets('the same card next round is a new question (BR-116)', (
      tester,
    ) async {
      // **The bug this replaces a card-id comparison for.** A card answered
      // wrongly comes back in the next round with the same id, so resetting on
      // `question.term.id` did not reset at all: the previous visit's verdict
      // stayed on the row and the guard stayed closed, leaving a question that
      // could not be answered.
      final chosen = <String>[];

      Future<void> pump(StudyTurnModel t) => tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: question,
            turn: t,
            onChosen: (option) async {
              chosen.add(option.cardId);

              return commitOf('c');
            },
          ),
          isScrollable: false,
        ),
      );

      await pump(turnOf(pool.first));
      await tester.tap(find.text(question.options.first.text));
      await tester.pumpAndSettle();

      await pump(turnOf(pool.first, round: 2));
      await tester.pumpAndSettle();

      // Open again: no verdict left over from the round before.
      expect(
        _statesOf(tester).where((state) => state != GuessOptionState.open),
        isEmpty,
      );

      await tester.tap(find.text(question.options.first.text));
      await tester.pumpAndSettle();

      expect(chosen, hasLength(2), reason: 'the second round was answerable');
    });

    testWidgets('a rebuild inside one turn keeps the answer given', (
      tester,
    ) async {
      // The other half of the rule: a parent rebuilding — which it does on every
      // state change — must not wipe the verdict the user is reading.
      final chosen = <String>[];

      Future<void> pump() => tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: question,
            turn: turnOf(pool.first),
            onChosen: (option) async {
              chosen.add(option.cardId);

              return commitOf('c');
            },
          ),
          isScrollable: false,
        ),
      );

      await pump();
      await tester.tap(find.text(question.options.first.text));
      await tester.pumpAndSettle();

      await pump();
      await tester.pumpAndSettle();

      expect(
        _statesOf(tester).where((state) => state == GuessOptionState.open),
        isEmpty,
        reason: 'the question re-opened on a rebuild',
      );
      expect(chosen, hasLength(1));
    });
  });
}

/// Every option's state, in the order they are drawn.
Iterable<GuessOptionState> _statesOf(WidgetTester tester) => tester
    .widgetList<GuessOptionItemWidget>(find.byType(GuessOptionItemWidget))
    .map((widget) => widget.state);
