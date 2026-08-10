import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';

/// How a round is dealt into boards (BR-156).
void main() {
  const handler = MatchModeHandler();

  List<StudyCardModel> cards(int count) => <StudyCardModel>[
    for (var i = 0; i < count; i++)
      StudyCardModel(
        id: 'c$i',
        front: 'front-$i',
        back: 'back-$i',
        example: null,
        hint: null,
        pronunciation: null,
        frontFolded: 'front-$i',
        backFolded: 'back-$i',
      ),
  ];

  group('how many boards a round becomes', () {
    test('a round is dealt five pairs at a time', () {
      expect(handler.boardCount(5), 1);
      expect(handler.boardCount(10), 2);
      expect(handler.boardCount(20), 4);
    });

    test('the last board takes the remainder, even when it is one pair', () {
      // The project owner chose this over redistributing, knowing a one-pair
      // board is an obvious answer. BR-156 scopes `kMinMatchPairs` to the
      // stage for exactly that reason — an obvious tail after ten worked pairs
      // is not the same thing as a stage whose whole content is one pair.
      expect(handler.boardCount(11), 3);

      final tail = handler.buildBoard(cards(11), Random(1), boardIndex: 2);
      expect(tail!.terms, hasLength(1));
    });

    test('a round too small to play at all still has no board', () {
      expect(handler.buildBoard(cards(1), Random(1)), isNull);
    });
  });

  group('which board is current', () {
    test('the board advances once every pair on it has been taken', () {
      expect(handler.boardIndexFor(done: 0, cardCount: 10), 0);
      expect(handler.boardIndexFor(done: 4, cardCount: 10), 0);
      expect(handler.boardIndexFor(done: 5, cardCount: 10), 1);
    });

    test('the final answer of a round does not run off the end', () {
      // `done` reaches the round size for the frame between the last answer
      // and the stage advancing. Unclamped that indexes a board that is not
      // there, and the screen draws nothing on the way out.
      expect(handler.boardIndexFor(done: 10, cardCount: 10), 1);
    });
  });

  group('what a board holds', () {
    test('a pair stays on the board it was dealt to', () {
      // Chunked before the shuffle, so which cards share a board is fixed by
      // the round's own order (BR-117) and only the sides are shuffled. Two
      // different seeds must not move a card between boards.
      Set<String> idsOn(int seed, int index) => handler
          .buildBoard(cards(10), Random(seed), boardIndex: index)!
          .terms
          .map((tile) => tile.cardId)
          .toSet();

      expect(idsOn(1, 0), idsOn(99, 0));
      expect(idsOn(1, 1), idsOn(99, 1));
      expect(idsOn(1, 0).intersection(idsOn(1, 1)), isEmpty);
    });

    test('the two sides are shuffled apart from each other', () {
      // BR-127. If one order drove the other the answer would be the row
      // number, which is the board grading nothing.
      final board = handler.buildBoard(cards(5), Random(7));

      expect(
        board!.terms.map((tile) => tile.cardId).toList(),
        isNot(board.meanings.map((tile) => tile.cardId).toList()),
      );
    });

    test('a board past the end of the round is no board', () {
      expect(handler.buildBoard(cards(10), Random(1), boardIndex: 2), isNull);
    });
  });
}
