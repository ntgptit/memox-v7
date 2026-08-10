import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/items/match_tile_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';

import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// How the board is **laid out**, and what that layout must not change.
///
/// Its own file rather than more cases in `match_board_widget_test.dart`: that
/// file is already near the 400-line guard, and the two ask different questions
/// — that one asks what a tap records, this one asks where a tile is and how
/// tall it gets.
///
/// **The column order moved and the interaction did not, which is the whole
/// risk.** Meanings are on the left now because a six-line block is what the eye
/// reads first, but the Korean term is still what has to be picked first
/// (BR-118). Swapping two `Expanded`s is exactly the kind of change that takes
/// the handlers with it by accident, and nothing about the result looks wrong.
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

  /// Five pairs, which is the ceiling BR-156 puts on one board.
  final cards = <StudyCardModel>[
    for (final id in <String>['a', 'b', 'c', 'd', 'e']) card(id),
  ];
  final board = const MatchModeHandler().buildBoard(cards, Random(1))!;

  /// The board inside a region the size of the one the session frame gives it.
  ///
  /// Bounded, because the whole fill-or-scroll decision reads
  /// `constraints.maxHeight` — an unbounded height would make every case the
  /// scrolling one and none of these tests would be about the screen.
  Widget boardIn({
    required Size region,
    double textScale = 1,
    Set<String> pairedCardIds = const <String>{},
    Future<StudyAnswerCommitModel?> Function(
      MatchTile term, {
      required bool isCorrect,
    })?
    onPairAttempt,
  }) => MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Center(
      child: SizedBox(
        width: region.width,
        height: region.height,
        child: MatchBoardSectionWidget(
          board: board,
          pairedCardIds: pairedCardIds,
          onPairAttempt:
              onPairAttempt ?? (_, {required isCorrect}) async => commitOf('c'),
        ),
      ),
    ),
  );

  /// The board's own region on a 393×852 phone, measured from the review render:
  /// the frame's top bar, context line and hint line take the rest.
  const region = Size(361, 628);

  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(wrapForTest(child, isScrollable: false));

  testWidgets('the meaning is on the left and the term on the right', (
    tester,
  ) async {
    await pump(tester, boardIn(region: region));

    // Asserted against one card's two tiles, never against a row: the columns
    // are independent shuffles (BR-127), so the two tiles of a pair are almost
    // never side by side and "same row" would be testing the seed.
    expect(
      tester.getCenter(find.text('back-a')).dx,
      lessThan(tester.getCenter(find.text('front-a')).dx),
    );
  });

  testWidgets('either side may be picked first, and both record the term', (
    tester,
  ) async {
    // **The board used to refuse half the taps a person makes.** Only a term
    // could be held, so a meaning tapped first went nowhere at all — no
    // selection, no attempt, no sign that anything had happened. BR-118 fixes
    // which *card* answers for the pair, not which tile is touched first.
    // A different card each way round: the board keeps its state across a
    // rebuild of the same deal (BR-127), so re-running with card `a` would find
    // it already cleared by the first pass.
    for (final order in <List<String>>[
      <String>['front-a', 'back-a', 'a'],
      <String>['back-b', 'front-b', 'b'],
    ]) {
      final attempts = <(String, bool)>[];
      await pump(
        tester,
        boardIn(
          region: region,
          onPairAttempt: (term, {required isCorrect}) async {
            attempts.add((term.cardId, isCorrect));

            return commitOf(term.cardId);
          },
        ),
      );

      await tester.tap(find.text(order.first));
      await tester.pump();
      expect(
        _stateOf(tester, order.first),
        MatchTileState.selected,
        reason: '${order.first} did not take the selection',
      );

      await tester.tap(find.text(order[1]));
      await tester.pump();

      expect(attempts, <(String, bool)>[
        (order.last, true),
      ], reason: 'picking ${order.first} first changed who answered');

      await tester.pump(AppMatchTile.successFlash);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('tapping the held tile again puts it down', (tester) async {
    // Without this the only way out of a selection is to answer with it, so a
    // mis-tap becomes a recorded turn.
    final attempts = <String>[];
    await pump(
      tester,
      boardIn(
        region: region,
        onPairAttempt: (term, {required isCorrect}) async {
          attempts.add(term.cardId);

          return commitOf(term.cardId);
        },
      ),
    );

    await tester.tap(find.text('back-a'));
    await tester.pump();
    await tester.tap(find.text('back-a'));
    await tester.pump();

    expect(_stateOf(tester, 'back-a'), MatchTileState.idle);
    expect(attempts, isEmpty);
  });

  testWidgets('a second tile on the same side moves the selection', (
    tester,
  ) async {
    // Two tiles from one column are not a pair — this is the user changing
    // their mind, which must cost a card nothing.
    final attempts = <String>[];
    await pump(
      tester,
      boardIn(
        region: region,
        onPairAttempt: (term, {required isCorrect}) async {
          attempts.add(term.cardId);

          return commitOf(term.cardId);
        },
      ),
    );

    await tester.tap(find.text('front-a'));
    await tester.pump();
    await tester.tap(find.text('front-b'));
    await tester.pump();

    expect(_stateOf(tester, 'front-a'), MatchTileState.idle);
    expect(_stateOf(tester, 'front-b'), MatchTileState.selected);
    expect(attempts, isEmpty);
  });

  testWidgets('a wrong pair still belongs to the term (BR-118)', (
    tester,
  ) async {
    // The meaning's own card was never being asked about, and grading it would
    // punish a card for sitting on the board.
    final attempts = <(String, bool)>[];
    await pump(
      tester,
      boardIn(
        region: region,
        onPairAttempt: (term, {required isCorrect}) async {
          attempts.add((term.cardId, isCorrect));

          return commitOf(term.cardId);
        },
      ),
    );

    await tester.tap(find.text('front-a'));
    await tester.pump();
    await tester.tap(find.text('back-b'));
    await tester.pump();

    expect(attempts, <(String, bool)>[('a', false)]);
    expect(_stateOf(tester, 'front-a'), MatchTileState.wrong);
    expect(_stateOf(tester, 'back-b'), MatchTileState.wrong);

    await tester.pump(AppMatchTile.wrongHold);
  });

  testWidgets('a cleared pair empties its slots and moves nothing', (
    tester,
  ) async {
    await pump(tester, boardIn(region: region));

    final before = <String, Rect>{
      for (final text in <String>['front-c', 'back-d', 'front-e'])
        text: tester.getRect(find.text(text)),
    };
    final slotCount = find.byType(MatchTileWidget).evaluate().length;

    await tester.tap(find.text('front-a'));
    await tester.pump();
    await tester.tap(find.text('back-a'));
    await tester.pump(AppMatchTile.successFlash);
    await tester.pumpAndSettle();

    // The content goes; the slot stays. Removing it would move every tile under
    // it — including the one the user is already reaching for.
    expect(_opacityOf(tester, 'front-a'), 0);
    expect(_opacityOf(tester, 'back-a'), 0);
    expect(find.byType(MatchTileWidget), findsNWidgets(slotCount));
    expect(slotCount, cards.length * 2);

    for (final entry in before.entries) {
      expect(
        tester.getRect(find.text(entry.key)),
        entry.value,
        reason: '${entry.key} moved when another pair cleared',
      );
    }
  });

  testWidgets('five rows fill the board exactly on a phone', (tester) async {
    await pump(tester, boardIn(region: region));

    final rows = _rowRects(tester);
    expect(rows, hasLength(cards.length));

    // Equal heights, and the gap between them is the token — the board is one
    // grid, not five independently sized bands.
    for (final row in rows) {
      expect(row.height, moreOrLessEquals(rows.first.height, epsilon: 0.5));
      expect(row.height, greaterThanOrEqualTo(AppMatchTile.minRowHeight));
    }
    for (var i = 1; i < rows.length; i++) {
      expect(
        rows[i].top - rows[i - 1].bottom,
        moreOrLessEquals(AppSpacing.sm, epsilon: 0.5),
      );
    }

    expect(
      find.descendant(
        of: find.byType(MatchBoardSectionWidget),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a board that cannot meet its floor scrolls instead', (
    tester,
  ) async {
    // At 2.0 the floor is 224 a row, so five rows need more than twice the
    // region. Squeezing them in would clip the sixth line off every meaning and
    // hand a thumb a 112-pixel-tall target that says something different from
    // what it shows.
    await pump(tester, boardIn(region: region, textScale: 2));

    expect(
      find.descendant(
        of: find.byType(MatchBoardSectionWidget),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final rows = _rowRects(tester);
    for (final row in rows) {
      expect(row.height, greaterThanOrEqualTo(AppMatchTile.minRowHeight * 2));
    }
  });

  testWidgets('the two tiles of a row are the same height', (tester) async {
    // One wraps to six lines and the other is a single word; without the row
    // making them equal the shorter one floats and the board reads as ragged.
    await pump(tester, boardIn(region: region, textScale: 2));

    final tiles = find.byType(MatchTileWidget);
    for (var index = 0; index < cards.length; index++) {
      expect(
        tester.getRect(tiles.at(index * 2)).height,
        moreOrLessEquals(
          tester.getRect(tiles.at(index * 2 + 1)).height,
          epsilon: 0.5,
        ),
      );
    }
  });
}

/// The state the tile showing [text] is in.
MatchTileState _stateOf(WidgetTester tester, String text) => tester
    .widget<MatchTileWidget>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(MatchTileWidget),
      ),
    )
    .state;

/// What the tile showing [text] is fading its content to.
double _opacityOf(WidgetTester tester, String text) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

/// One rect per row, taken from the left-hand tile of each.
///
/// Tiles come out of the tree in layout order, two to a row, so the even ones
/// are the left column.
List<Rect> _rowRects(WidgetTester tester) {
  final tiles = find.byType(MatchTileWidget);
  final count = tiles.evaluate().length;

  return <Rect>[
    for (var index = 0; index < count; index += 2)
      tester.getRect(tiles.at(index)),
  ];
}
