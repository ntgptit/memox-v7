import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_durations.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_stroke.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/items/match_tile_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';

import 'support/study_commit_stub.dart';
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
    frontFolded: 'front-$id',
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
        onPairAttempt: (_, {required isCorrect}) async => commitOf('c'),
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
      await _settleColour(tester);

      expect(find.byIcon(Icons.check), findsNWidgets(2));

      // **Both tiles say it on their edge, and neither says it with a fill.**
      // Every answer touches two tiles, so a solid state doubles its own area
      // — and a six-line meaning under a solid green stops reading as a
      // sentence. The surface stays exactly what an idle tile has.
      for (final label in <String>['front-a', 'back-a']) {
        expect(_fill(tester, label), _idleFill(tester));
        expect(_edge(tester, label).color, _semantic(tester).success);
        expect(_edge(tester, label).width, AppStroke.input);
        expect(
          tester.widget<Text>(find.text(label)).style?.color,
          _semantic(tester).success,
        );
      }

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

      await _settleColour(tester);
      for (final label in <String>['front-a', 'back-b']) {
        expect(_fill(tester, label), _idleFill(tester));
        expect(_edge(tester, label).color, _semantic(tester).danger);
        expect(_edge(tester, label).width, AppStroke.input);
        expect(
          tester.widget<Text>(find.text(label)).style?.color,
          _semantic(tester).danger,
        );
      }

      await tester.pump(AppMatchTile.wrongHold);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);

      // Back to idle on the edge and the ink too, not just the mark.
      for (final label in <String>['front-a', 'back-b']) {
        expect(_edge(tester, label).color, _semantic(tester).borderControl);
        expect(_edge(tester, label).width, AppStroke.hairline);
      }
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
      await _settleColour(tester);

      expect(find.byIcon(Icons.close), findsNothing);

      // And the tap was a real selection, not just a dismissal.
      final ink = Theme.of(
        tester.element(find.text('front-b')),
      ).colorScheme.primary;
      expect(tester.widget<Text>(find.text('front-b')).style?.color, ink);
      expect(_edge(tester, 'front-b').color, ink);

      await tester.pump(AppMatchTile.wrongHold);
    });

    testWidgets('a mark is held long enough to be read, and no longer', (
      tester,
    ) async {
      // **A hold is how long a state is visible; a transition is how long it
      // takes to arrive.** They were the same 320ms token, which left 120ms of
      // the state actually standing still — and the board was unmounted for the
      // next fetch before even that had run. The numbers are asserted from both
      // sides so a future tidy-up cannot quietly shorten them again.
      await pumpBoard(tester);

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-b'));
      await _settleColour(tester);

      await tester.pump(AppMatchTile.wrongHold - AppDurations.normal * 2);
      expect(find.byIcon(Icons.close), findsNWidgets(2));

      await tester.pump(AppDurations.normal * 2);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsNothing);

      expect(
        AppMatchTile.wrongHold,
        greaterThan(AppMatchTile.successFlash),
        reason: 'a wrong pair is two glances, a correct one is a confirmation',
      );
      expect(
        AppMatchTile.successFlash,
        greaterThan(AppDurations.normal),
        reason: 'a hold shorter than its own transition is never seen at rest',
      );
    });

    testWidgets('a pair is cleared only once its write resolves', (
      tester,
    ) async {
      // The board used to tick on the tap. A refused write then left a slot
      // emptied for an answer the session does not have.
      final gate = Completer<void>();
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (term, {required isCorrect}) =>
                gate.future.then((_) => commitOf(term.cardId)),
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await _settleColour(tester);

      expect(find.byIcon(Icons.check), findsNothing);

      gate.complete();
      await tester.pump();
      expect(find.byIcon(Icons.check), findsNWidgets(2));

      await tester.pump(AppMatchTile.successFlash);
      await tester.pumpAndSettle();
    });

    testWidgets('the next board is asked for once, after the last pair', (
      tester,
    ) async {
      // **The whole point of the change.** Every attempt used to end in a
      // fetch, so a board of three cost three reloads and three unmounts of the
      // board being played. Now the board is what says it is finished.
      var fetches = 0;
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) async => commitOf('c'),
            onBoardComplete: () async => fetches++,
          ),
        ),
      );

      for (final id in <String>['a', 'b', 'c']) {
        await tester.tap(find.text('front-$id'));
        await tester.pump();
        await tester.tap(find.text('back-$id'));
        await tester.pump();
        expect(fetches, 0, reason: 'fetched in the middle of a board');
        await tester.pump(AppMatchTile.successFlash);
      }

      await tester.pumpAndSettle();
      expect(fetches, 1);
    });
  });
}

/// Lets the tile's crossfade land, while its hold is still running.
///
/// One pump starts the `AnimatedContainer`; the second carries it the whole
/// duration. Both fit inside `wrongHold` and `successFlash`, which are `slow`
/// against the transition's `normal` — a single pump would read the previous
/// state's colours and pass for the wrong reason.
Future<void> _settleColour(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(AppDurations.normal);
}

AppSemanticColors _semantic(WidgetTester tester) => Theme.of(
  tester.element(find.byType(MatchBoardSectionWidget)),
).extension<AppSemanticColors>()!;

/// What the tile showing [label] paints behind its text.
Color? _fill(WidgetTester tester, String label) =>
    (_tileOf(tester, label).decoration! as BoxDecoration).color;

/// What that tile draws its edge with.
BorderSide _edge(WidgetTester tester, String label) =>
    (_tileOf(tester, label).decoration! as BoxDecoration).border!.top;

/// The fill of a tile nobody has touched — read from the board rather than
/// named, so this stays a *relation* between states and not a second copy of
/// the token.
Color? _idleFill(WidgetTester tester) => _fill(tester, 'front-c');

AnimatedContainer _tileOf(WidgetTester tester, String label) =>
    tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

/// The fade a cleared slot takes its content out with.
Finder _fadeOver(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(AnimatedOpacity))
    .first;
