import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_stroke.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/items/guess_option_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/guess_question_section_widget.dart';

import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// What the question looks like once it has been answered, and what it refuses
/// to do afterwards.
///
/// **Split from `guess_question_widget_test.dart` at the seam the states make.**
/// That file asks whether the question can be answered — five options, one turn,
/// a reset when the turn changes. This one asks what the answer then *looks*
/// like: which row is marked, in what, and whether the four the learner was
/// comparing are still readable. The two halves shared a `main` until the skin
/// tests pushed them past the 400-line guard, and the guard picked the right
/// place to cut.
void main() {
  StudyCardModel card(String id) => StudyCardModel(
    id: id,
    front: 'front-$id',
    back: 'back-$id',
    example: null,
    hint: null,
    pronunciation: null,
    frontFolded: 'front-$id',
    backFolded: 'back-$id',
  );

  StudyTurnModel turnOf(StudyCardModel subject) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: StudyMode.guess,
      round: 1,
      cardId: subject.id,
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
      total: 5,
      completedCardIds: <String>[],
    ),
    card: subject,
  );

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
            turn: turnOf(card('a')),
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
            turn: turnOf(card('a')),
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
            turn: turnOf(card('a')),
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
    testWidgets('a verdict is an edge and an ink, never a fill', (
      tester,
    ) async {
      // **The contract, stated as a relation.** Five rows of running text are a
      // page; colouring two of them end to end turns a screen the learner is
      // reading into one shouting at them. `match` reached the same answer, and
      // a row whose meaning runs to four lines has more area to shout with.
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: questionOf(),
            turn: turnOf(card('a')),
            onChosen: (_) async => commitOf('c'),
          ),
          isScrollable: false,
        ),
      );

      final open = _fillOf(tester, 'back-b');

      await tester.tap(find.text('back-b'));
      await tester.pumpAndSettle();

      for (final text in <String>['back-a', 'back-b', 'back-c']) {
        expect(
          _fillOf(tester, text),
          open,
          reason: '$text changed its surface',
        );
      }

      expect(_fillOf(tester, 'back-a'), isNot(successOf(tester)));
      expect(_fillOf(tester, 'back-b'), isNot(dangerOf(tester)));

      // The edge is what changed, and it stepped up in weight to say so.
      expect(_borderOf(tester, 'back-a').color, successOf(tester));
      expect(_borderOf(tester, 'back-b').color, dangerOf(tester));
      expect(_borderOf(tester, 'back-a').width, AppStroke.input);
      expect(_borderOf(tester, 'back-c').width, AppStroke.hairline);
    });

    testWidgets('the rows nobody picked stay readable', (tester) async {
      // They are still four of the five meanings the learner was choosing
      // between. 0.36 put them under the 4.5:1 body text needs — the rows being
      // *compared* were the ones that disappeared.
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: questionOf(),
            turn: turnOf(card('a')),
            onChosen: (_) async => commitOf('c'),
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text('back-b'));
      await tester.pumpAndSettle();

      expect(AppGuessOption.dimmedOpacity, greaterThanOrEqualTo(0.6));
      expect(
        tester
            .widgetList<Opacity>(
              find.ancestor(
                of: find.text('back-c'),
                matching: find.byType(Opacity),
              ),
            )
            .map((widget) => widget.opacity),
        contains(AppGuessOption.dimmedOpacity),
      );
    });
  });
}

/// The surface the row showing [text] paints.
Color? _fillOf(WidgetTester tester, String text) =>
    (_rowOf(tester, text).decoration! as BoxDecoration).color;

/// The edge it draws.
BorderSide _borderOf(WidgetTester tester, String text) =>
    (_rowOf(tester, text).decoration! as BoxDecoration).border!.top;

AnimatedContainer _rowOf(WidgetTester tester, String text) =>
    tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
