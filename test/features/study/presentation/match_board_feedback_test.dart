import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/items/match_tile_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';

import 'support/study_widget_harness.dart';

/// What the board says back when a pair lands, right or wrong (§8.8).
///
/// Split from `match_board_widget_test.dart` at the 400-line guard, and along
/// the seam that matters: that file is about what gets *recorded*, this one is
/// about what the user is *told*.
void main() {
  StudyCardModel card(String id) => StudyCardModel(
    id: id,
    front: 'front-$id',
    back: 'back-$id',
    example: null,
    hint: null,
    pronunciation: null,
    backFolded: 'back-$id',
  );

  final board = const MatchModeHandler().buildBoard(<StudyCardModel>[
    card('a'),
    card('b'),
    card('c'),
  ], Random(1))!;

  Future<void> pumpBoard(WidgetTester tester) => tester.pumpWidget(
    wrapForTest(
      MatchBoardSectionWidget(
        board: board,
        onPairAttempt: (_, {required isCorrect}) {},
      ),
    ),
  );

  group('the match board', () {
    testWidgets('a correct pair holds a beat, then empties its slot', (
      tester,
    ) async {
      // The beat is feedback, not decoration: a tile that merely vanished
      // would read the same as a missed tap to somebody who was guessing.
      await pumpBoard(tester);

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsNWidgets(2));

      await tester.pump(AppMatchTile.successFlash);
      await tester.pumpAndSettle();

      // Gone as content, still there as a slot — the row count is what stops
      // the board reflowing under the next tap.
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.text('front-a'), findsOneWidget);
      expect(tester.widget<AnimatedOpacity>(_fadeOver('front-a')).opacity, 0);
    });

    testWidgets('a wrong pair says so, and gives the colour back on its own', (
      tester,
    ) async {
      // It said nothing at all before this: the selection cleared and a wrong
      // answer looked exactly like a mis-tap.
      await pumpBoard(tester);

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-b'));
      await tester.pump();

      // Both tiles, because it is the *pairing* that was wrong. BR-118 still
      // grades the term alone; this is what the user is told, not what is
      // written down.
      expect(find.byIcon(Icons.close), findsNWidgets(2));
      expect(tester.getSemantics(find.text('front-a')).value, 'Not a pair');

      await tester.pump(AppMatchTile.wrongHold);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('reaching for the next term ends the red early', (
      tester,
    ) async {
      // The hold is on the colour, never on the input. Four wrong answers on a
      // five-pair board would otherwise be three seconds of refused taps.
      await pumpBoard(tester);

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-b'));
      await tester.pump();
      expect(find.byIcon(Icons.close), findsNWidgets(2));

      await tester.tap(find.text('front-b'));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNothing);

      // And the tap was a real selection, not just a dismissal.
      final label = tester.widget<Text>(find.text('front-b'));
      final scheme = Theme.of(tester.element(find.text('front-b'))).colorScheme;
      expect(label.style?.color, scheme.onPrimary);

      await tester.pump(AppMatchTile.wrongHold);
    });
  });
}

/// The fade a cleared slot takes its content out with.
Finder _fadeOver(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(AnimatedOpacity))
    .first;
