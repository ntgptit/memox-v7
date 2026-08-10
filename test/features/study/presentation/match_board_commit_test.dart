import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_durations.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/items/match_tile_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';

import 'dart:math';

import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// **BR-157 on the board:** nothing is ticked, reddened or cleared before the
/// write holding it has committed.
///
/// Its own file because it asks a different question from
/// `match_board_feedback_test.dart`. That one asks what the board *says* once an
/// answer is in; this one asks what it says while the answer is still on its
/// way, and what it says when the answer never arrives. The second was
/// unaskable while the callback was a `Future<void>`: a future completing means
/// the call returned, not that a row was written, and the board read the two as
/// the same thing.
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

  group('the match board', () {
    testWidgets('a correct pair is not ticked while its write is open', (
      tester,
    ) async {
      // BR-157. The tick used to be drawn on the tap, so a refused write left a
      // slot emptied for an answer the session does not have.
      final write = PendingCommit();
      var completions = 0;
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) => write.future,
            onBoardComplete: () async => completions++,
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await _settleColour(tester);

      expect(find.byIcon(Icons.check), findsNothing);
      expect(_opacityOf(tester, 'front-a'), 1);
      expect(completions, 0);

      write.commit('a');
      await tester.pumpAndSettle();
    });

    testWidgets('a correct pair refused stays on the board', (tester) async {
      final write = PendingCommit();
      var completions = 0;
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) => write.future,
            onBoardComplete: () async => completions++,
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();
      write.refuse();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
      expect(_opacityOf(tester, 'front-a'), 1);
      expect(_stateOf(tester, 'front-a'), MatchTileState.idle);
      expect(completions, 0);
    });

    testWidgets('a wrong pair is not reddened while its write is open', (
      tester,
    ) async {
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) => write.future,
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-b'));
      await _settleColour(tester);

      expect(find.byIcon(Icons.close), findsNothing);
      expect(_stateOf(tester, 'front-a'), MatchTileState.idle);

      write.commit('a', status: StudyQueueItemStatus.pending);
      await tester.pumpAndSettle();
      await tester.pump(AppMatchTile.wrongHold);
    });

    testWidgets('a wrong pair reddens both tiles once its write is in', (
      tester,
    ) async {
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) => write.future,
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-b'));
      await tester.pump();
      // The row stays open — which is what a `match` lapse writes (BR-118) —
      // and the receipt is what says so.
      write.commit('a', status: StudyQueueItemStatus.pending);
      await _settleColour(tester);

      expect(find.byIcon(Icons.close), findsNWidgets(2));
      expect(_stateOf(tester, 'front-a'), MatchTileState.wrong);
      expect(_stateOf(tester, 'back-b'), MatchTileState.wrong);

      await tester.pump(AppMatchTile.wrongHold);
      await tester.pumpAndSettle();
    });

    testWidgets('a wrong pair refused is not reddened at all', (tester) async {
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) => write.future,
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-b'));
      await tester.pump();
      write.refuse();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
      expect(_stateOf(tester, 'front-a'), MatchTileState.idle);
      expect(_stateOf(tester, 'back-b'), MatchTileState.idle);
    });

    testWidgets('a second pair cannot start while the first is being written', (
      tester,
    ) async {
      // **Persistence is single-flight**, so the board has to be. The
      // controller refuses the second submission with a null receipt, which the
      // board used to read as a successful write and clear a pair on.
      final attempts = <String>[];
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (term, {required isCorrect}) {
              attempts.add(term.cardId);

              return write.future;
            },
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();

      await tester.tap(find.text('front-b'));
      await tester.pump();
      await tester.tap(find.text('back-b'));
      await tester.pump();

      expect(attempts, <String>[
        'a',
      ], reason: 'only the first pair was written');
      expect(_stateOf(tester, 'front-b'), MatchTileState.idle);

      write.commit('a');
      await tester.pumpAndSettle();

      // And the board is playable again the moment the write lands — the
      // 500ms the pair holds its colour is not a lock.
      await tester.tap(find.text('front-b'));
      await tester.pump();
      expect(_stateOf(tester, 'front-b'), MatchTileState.selected);

      await tester.pump(AppMatchTile.successFlash);
      await tester.pumpAndSettle();
    });
  });
}

/// Lets the tile's crossfade land, while its hold is still running.
Future<void> _settleColour(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(AppDurations.normal);
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
      find
          .ancestor(of: find.text(text), matching: find.byType(AnimatedOpacity))
          .first,
    )
    .opacity;
