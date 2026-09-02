import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';

import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// The `success` token of the theme the harness builds, read from the tree so a
/// test cannot assert against a value copied out of the palette.
Color wrapForTestSuccess(WidgetTester tester) => Theme.of(
  tester.element(find.byType(MatchBoardSectionWidget)),
).extension<AppSemanticColors>()!.success;

/// The two graded screens, and the four ways they must not grade.
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
            onPairAttempt: (term, {required isCorrect}) async {
              attempts.add(term.cardId);

              return commitOf(term.cardId);
            },
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
            onPairAttempt: (term, {required isCorrect}) async {
              attempts.add((cardId: term.cardId, isCorrect: isCorrect));

              return commitOf(term.cardId);
            },
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

    testWidgets('a paired tile stays on the board, marked', (tester) async {
      // §4, and it reverses the first build. Removing a paired tile reflows
      // every row below it, so the tile the user was about to press moves the
      // instant they press something else — and the board whose shape they had
      // learned is gone.
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) async => commitOf('c'),
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();

      expect(find.text('front-a'), findsOneWidget);
      expect(find.text('back-a'), findsOneWidget);
      expect(find.text('front-b'), findsOneWidget);

      // Marked in `success`, which here means exactly what the token means: this
      // answer was right.
      final label = tester.widget<Text>(find.text('front-a'));
      expect(label.style?.color, wrapForTestSuccess(tester));
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('a paired tile cannot be tapped again', (tester) async {
      // BR-116 has already recorded it; a second tap could only record it twice.
      final attempts = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (term, {required isCorrect}) async {
              attempts.add(term.cardId);

              return commitOf(term.cardId);
            },
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();

      await tester.tap(find.text('front-a'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('back-b'), warnIfMissed: false);
      await tester.pump();

      // One attempt, not three: the paired term never became the selection, so
      // the meaning tapped after it had no term to belong to.
      expect(attempts, <String>['a']);
    });

    testWidgets('a selected term is outlined, and says so', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) async => commitOf('c'),
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      // Far enough for the tile's `AnimatedContainer` to reach its target: one
      // frame to start the transition, then its whole duration.
      await tester.pump();
      await tester.pump(AppDurations.normal);

      final theme = Theme.of(tester.element(find.text('front-a')));
      final accent = theme.colorScheme.primary;
      final label = tester.widget<Text>(find.text('front-a'));

      // `primary`, the canonical accent, as a label on a surface — readable
      // because the palette is tuned for it (M100.28), not via a second token.
      expect(label.style?.color, accent);

      // The surface is painted by the tile's own `AnimatedContainer`, not by
      // the `Material` — the `Material` is transparent and exists for the
      // ripple, so the state transition can be animated at all.
      final tile = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('front-a'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = tile.decoration! as BoxDecoration;

      // **The fill does not move, and that is the point.** A selected tile used
      // to be a solid block of `primary`; on a ten-slot board that is a fifth
      // of the screen changing at once, and the answer was never in the area.
      expect(decoration.color, theme.colorScheme.surfaceContainerLowest);
      expect(decoration.border!.top.color, accent);
      expect(decoration.border!.top.width, AppStroke.input);

      // Read from the widget rather than the compiled node: `matchesSemantics`
      // asserts the *whole* node, so it fails on every unrelated flag the tile
      // legitimately carries.
      // From the tile's own `Semantics`, picked by the property it sets:
      // `InkWell` and `Material` wrap the text in nodes of their own, and the
      // closest one is not the tile's.
      expect(
        tester
            .widgetList<Semantics>(
              find.ancestor(
                of: find.text('front-a'),
                matching: find.byType(Semantics),
              ),
            )
            .map((widget) => widget.properties.selected)
            .whereType<bool>(),
        <bool>[true],
      );
    });

    testWidgets('the ticks survive a rebuild of the same deal', (tester) async {
      // The caller re-lays the board on every build from a seeded shuffle
      // (BR-127), so the widget is handed a *new* `MatchBoard` object each time
      // — locking the buttons during a write is enough. Comparing by identity
      // cleared every tick the user had earned the moment they answered.
      Widget boardOf() => wrapForTest(
        MatchBoardSectionWidget(
          board: const MatchModeHandler().buildBoard(<StudyCardModel>[
            card('a'),
            card('b'),
            card('c'),
          ], Random(1))!,
          onPairAttempt: (_, {required isCorrect}) async => commitOf('c'),
        ),
      );

      await tester.pumpWidget(boardOf());
      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsNWidgets(2));

      // Same seed, same cards: a different object holding the identical deal.
      await tester.pumpWidget(boardOf());
      await tester.pump();

      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('a new round clears the ticks', (tester) async {
      // Round 2 holds the cards that failed round 1. Carrying the marks over
      // would show them as already correct.
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (_, {required isCorrect}) async => commitOf('c'),
          ),
        ),
      );

      await tester.tap(find.text('front-a'));
      await tester.pump();
      await tester.tap(find.text('back-a'));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsNWidgets(2));

      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: const MatchModeHandler().buildBoard(<StudyCardModel>[
              card('a'),
              card('b'),
              card('c'),
            ], Random(2))!,
            onPairAttempt: (_, {required isCorrect}) async => commitOf('c'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('a tick the queue knows about survives losing the widget', (
      tester,
    ) async {
      // **The bug this replaces was invisible from inside the widget.** The
      // screen swaps to its loading state between turns, which unmounts the
      // board and takes its private `_matched` set with it — so every paired
      // tile came back tappable on the very next card, and the same pair could
      // be answered again. The end-to-end run found it as nine `match` turns
      // recorded for five cards.
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            pairedCardIds: const <String>{'a'},
            onPairAttempt: (_, {required isCorrect}) async => commitOf('c'),
          ),
        ),
      );

      // A pair the queue already knows about comes back **cleared**, not
      // flashing: the green beat belongs to the tap that earned it, and
      // replaying it on every remount would light the board up for answers
      // minutes old. It still announces itself, or a screen reader would lose
      // the pair off the board entirely.
      expect(find.byIcon(Icons.check), findsNothing);
      for (final label in <String>['front-a', 'back-a']) {
        expect(
          tester.getSemantics(find.text(label)).value,
          'Paired',
          reason: '$label is a cleared slot and must still say so',
        );
      }

      final attempts = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            pairedCardIds: const <String>{'a'},
            onPairAttempt: (term, {required isCorrect}) async {
              attempts.add(term.cardId);

              return commitOf(term.cardId);
            },
          ),
        ),
      );

      await tester.tap(find.text('front-a'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('back-a'), warnIfMissed: false);
      await tester.pump();

      expect(attempts, isEmpty);
    });

    testWidgets('the attempt names the term, not whatever is on the queue', (
      tester,
    ) async {
      // BR-118. The board lays out the whole round, so the pair a person
      // reaches for is rarely the card at the head of the queue — and the view
      // used to discard the term and record against that one instead.
      final attempts = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            onPairAttempt: (term, {required isCorrect}) async {
              attempts.add(term.cardId);

              return commitOf(term.cardId);
            },
          ),
        ),
      );

      await tester.tap(find.text('front-c'));
      await tester.pump();
      await tester.tap(find.text('back-c'));
      await tester.pump();

      expect(attempts, <String>['c']);
    });

    testWidgets('a locked board records nothing', (tester) async {
      final attempts = <String>[];
      await tester.pumpWidget(
        wrapForTest(
          MatchBoardSectionWidget(
            board: board,
            isLocked: true,
            onPairAttempt: (term, {required isCorrect}) async {
              attempts.add(term.cardId);

              return commitOf(term.cardId);
            },
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
}
