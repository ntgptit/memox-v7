import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_entry_summary_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';

/// What the two content-building modes refuse to build, and why.
void main() {
  StudyCardModel card(String id, {String? back, String? folded}) =>
      StudyCardModel(
        id: id,
        front: 'front-$id',
        back: back ?? 'back-$id',
        example: null,
        hint: null,
        pronunciation: null,
        frontFolded: 'front-$id',
        backFolded: folded ?? (back ?? 'back-$id'),
      );

  List<StudyCardModel> cards(int count) => <StudyCardModel>[
    for (var i = 0; i < count; i++) card('c$i'),
  ];

  StudyEntrySummaryModel summaryOf({
    int dueCount = 6,
    int fillableCount = 2,
    int distinctMeanings = 6,
  }) => StudyEntrySummaryModel(
    newCount: 0,
    dueCount: dueCount,
    fillableCount: fillableCount,
    distinctMeanings: distinctMeanings,
  );

  group('the resolver', () {
    test('every mode but unknown has a handler', () {
      // Missing a branch is a compile error, so what is worth asserting is that
      // `unknown` is the only value without behaviour: a mode this build does
      // not recognise must be readable and not runnable.
      for (final mode in StudyMode.values) {
        expect(
          studyModeHandler(mode),
          mode == StudyMode.unknown ? isNull : isNotNull,
          reason: '$mode',
        );
      }
    });

    test('each mode answers its own capacity question (BR-154)', () {
      final summary = summaryOf();

      // The whole reason BR-154 forbids one shared number: `fill` counts
      // something different from everyone else.
      expect(studyModeHandler(StudyMode.fill)!.capacityFrom(summary), 2);
      expect(studyModeHandler(StudyMode.recall)!.capacityFrom(summary), 6);
      expect(studyModeHandler(StudyMode.match)!.capacityFrom(summary), 6);
    });
  });

  group('match', () {
    const handler = MatchModeHandler();

    test('one pair is refused, two are laid out (BR-153)', () {
      // A single pair makes the answer the only thing left on the board.
      expect(handler.buildBoard(cards(1), Random(1)), isNull);
      expect(handler.buildBoard(cards(2), Random(1)), isNotNull);
      expect(handler.capacityFrom(summaryOf(dueCount: 1)), 0);
    });

    test('the two columns are shuffled independently (BR-127)', () {
      // If one order drove the other the board would read straight across, and
      // the answer would be the row number rather than the meaning.
      final board = handler.buildBoard(cards(8), Random(3))!;

      expect(
        board.terms.map((t) => t.cardId).toList(),
        isNot(board.meanings.map((m) => m.cardId).toList()),
      );
      expect(
        board.terms.map((t) => t.cardId).toSet(),
        board.meanings.map((m) => m.cardId).toSet(),
      );
    });

    test('a pair is decided by card id, not by the text shown (BR-125)', () {
      final board = handler.buildBoard(<StudyCardModel>[
        card('a', back: 'same'),
        card('b', back: 'same'),
      ], Random(1))!;

      final termA = board.terms.firstWhere((t) => t.cardId == 'a');
      final meaningB = board.meanings.firstWhere((m) => m.cardId == 'b');

      // Identical strings, different cards: comparing text would call this a
      // match and grade the wrong card.
      expect(termA.text == meaningB.text, isFalse);
      expect(board.isPair(termA, meaningB), isFalse);
    });

    test('the term keeps its own identity for the turn (BR-118)', () {
      // Picking the wrong meaning marks the term's card, never the card that
      // happens to own the meaning that was picked.
      final board = handler.buildBoard(cards(4), Random(2))!;

      expect(board.terms.every((t) => t.isTerm), isTrue);
      expect(board.meanings.every((m) => !m.isTerm), isTrue);
    });
  });

  group('guess', () {
    const handler = GuessModeHandler();

    test('a question has exactly five options, one of them right (BR-121)', () {
      final pool = cards(10);
      final question = handler.buildQuestion(
        term: pool.first,
        pool: pool,
        random: Random(4),
      )!;

      expect(question.options, hasLength(5));
      expect(
        question.options.where((o) => o.cardId == pool.first.id),
        hasLength(1),
      );
    });

    test('two cards with the same folded meaning never share a set (BR-123)', () {
      // Measured on `back_folded`, not on the displayed string: two cards that
      // merely look different are the same meaning, and a set holding both has
      // two right answers.
      final pool = <StudyCardModel>[
        card('term', back: 'a', folded: 'a'),
        card('dup', back: 'A', folded: 'a'),
        for (var i = 0; i < 8; i++) card('x$i', back: 'b$i', folded: 'b$i'),
      ];

      final question = handler.buildQuestion(
        term: pool.first,
        pool: pool,
        random: Random(5),
      )!;

      expect(question.options.where((o) => o.cardId == 'dup'), isEmpty);
      expect(
        question.options.map((o) => o.cardId).toSet(),
        hasLength(question.options.length),
      );
    });

    test('too few distinct meanings blocks the question (BR-124)', () {
      // The stage was allowed to run and this one question still cannot be
      // built. The caller must not render, not record, and not skip the card.
      final pool = <StudyCardModel>[
        card('term', back: 'a', folded: 'a'),
        card('b', back: 'b', folded: 'b'),
        card('c', back: 'c', folded: 'c'),
      ];

      expect(
        handler.buildQuestion(term: pool.first, pool: pool, random: Random(6)),
        isNull,
      );
    });

    test('the stage is skipped below five meanings (BR-99, BR-121)', () {
      expect(handler.capacityFrom(summaryOf(distinctMeanings: 4)), 0);
      expect(handler.capacityFrom(summaryOf(distinctMeanings: 5)), 6);
    });

    test('correctness is decided by identity (BR-125)', () {
      final pool = <StudyCardModel>[
        card('term', back: 'shared', folded: 'shared'),
        for (var i = 0; i < 8; i++) card('x$i', back: 'b$i', folded: 'b$i'),
      ];
      final question = handler.buildQuestion(
        term: pool.first,
        pool: pool,
        random: Random(7),
      )!;

      final wrong = question.options.firstWhere((o) => o.cardId != 'term');

      expect(
        question.isCorrect(
          question.options.firstWhere((o) => o.cardId == 'term'),
        ),
        isTrue,
      );
      expect(question.isCorrect(wrong), isFalse);
      // A hand-made option carrying the right *text* but the wrong card is not
      // the right answer.
      expect(
        question.isCorrect(
          const GuessOption(cardId: 'someone-else', text: 'shared'),
        ),
        isFalse,
      );
    });

    test('the option order does not follow the card order (BR-127)', () {
      final pool = cards(12);
      final question = handler.buildQuestion(
        term: pool.first,
        pool: pool,
        random: Random(8),
      )!;

      // The right answer is not always first, which is what an unshuffled build
      // would produce.
      expect(question.options.first.cardId, isNot('c0'));
    });
  });
}
