import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/entities/study_session_entity.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/states/study_session_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_blocked_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_mode_view_widget.dart';

import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// BR-124's blocking case, seen from the widget layer.
void main() {
  StudyCardModel card(String id, {String back = 'meaning'}) => StudyCardModel(
    id: id,
    front: 'front-$id',
    back: back,
    example: 'ex-$id',
    hint: null,
    pronunciation: null,
    frontFolded: 'front-$id',
    backFolded: back,
  );

  StudyTurnModel turnOf(StudyMode mode, StudyCardModel forCard) =>
      StudyTurnModel(
        item: StudyQueueItemEntity(
          sessionId: 's1',
          mode: mode,
          round: 1,
          cardId: forCard.id,
          position: 0,
          status: StudyQueueItemStatus.pending,
          availableAt: 0,
          answersInSession: 0,
          remainingMs: null,
          isRevealed: false,
          direction: null,
        ),
        card: forCard,
        progress: const StudyStageProgressModel(
          round: 1,
          done: 0,
          total: 3,
          completedCardIds: <String>[],
        ),
      );

  test('a question that cannot be built yields no view and no answer', () {
    // Null, not an empty box. `SizedBox.shrink()` is a blank screen: nothing to
    // read, nothing to tap, and force-quitting the only way out — which is how
    // a rule that protects the user ends up looking like a crash.
    final answers = <StudyAction>[];
    final pool = <StudyCardModel>[card('c0'), card('c1'), card('c2')];

    final view = studyModeView(
      mode: StudyMode.guess,
      state: StudySessionState(
        turn: turnOf(StudyMode.guess, pool.first),
        sessionCards: pool,
        // Named, not defaulted. The default is `unknown`, and a graded stage on
        // an unknown algorithm is refused for a *different* reason — so leaving
        // it out would let this test pass without BR-124 being implemented at
        // all.
        schedulerType: SchedulerType.eightBox,
      ),
      onAnswer:
          (
            action, {
            cardId,
            outcomeReason,
            comparisonVersion,
            hasUsedHint,
          }) async {
            answers.add(action);

            return commitOf('c');
          },
      onContinue: () {},
      onLookBack: () {},
    );

    expect(view, isNull);
    // BR-124: nothing is recorded, and the card is not skipped.
    expect(answers, isEmpty);
  });

  test('a graded stage on an unrecognised algorithm yields no view', () {
    // `schedulerFor` returns null for an algorithm this build has never heard
    // of, so `binaryAction` has no answer and every grade taken here would be
    // dropped on the way out. Building the board anyway is a screen that eats
    // taps: the user matches a pair, nothing moves, nothing is written, and
    // force-quitting is the only way out.
    final answers = <StudyAction>[];
    final pool = <StudyCardModel>[card('c0', back: 'a'), card('c1', back: 'b')];

    final view = studyModeView(
      mode: StudyMode.match,
      state: StudySessionState(
        turn: turnOf(StudyMode.match, pool.first),
        sessionCards: pool,
        // Spelled out even though it is the default: this test is *about* the
        // unknown algorithm, and a reader who cannot see that from the call has
        // to go looking for what the default happens to be today.
        // ignore: avoid_redundant_argument_values
        schedulerType: SchedulerType.unknown,
      ),
      onAnswer:
          (
            action, {
            cardId,
            outcomeReason,
            comparisonVersion,
            hasUsedHint,
          }) async {
            answers.add(action);

            return commitOf('c');
          },
      onContinue: () {},
      onLookBack: () {},
    );

    expect(view, isNull);
    expect(answers, isEmpty);
  });

  test('the same stage builds once the algorithm is known', () {
    // The counterpart, and it is what stops the guard above from being "match
    // never renders": two pairs on `eight_box` is a board.
    final pool = <StudyCardModel>[card('c0', back: 'a'), card('c1', back: 'b')];

    final view = studyModeView(
      mode: StudyMode.match,
      state: StudySessionState(
        turn: turnOf(StudyMode.match, pool.first),
        sessionCards: pool,
        schedulerType: SchedulerType.eightBox,
      ),
      onAnswer:
          (
            action, {
            cardId,
            outcomeReason,
            comparisonVersion,
            hasUsedHint,
          }) async => commitOf('c'),
      onContinue: () {},
      onLookBack: () {},
    );

    expect(view, isNotNull);
  });

  testWidgets('the blocked state says what did not happen', (tester) async {
    // Without this sentence a blocked stage reads as work lost, which is the
    // opposite of what the rule protects (BR-86).
    await tester.pumpWidget(
      wrapForTest(StudyBlockedSectionWidget(onLeave: () {})),
    );

    expect(find.text('This card cannot be shown here'), findsOneWidget);
    expect(find.textContaining('Nothing was recorded'), findsOneWidget);
  });

  testWidgets('leaving is the only action, and it reports', (tester) async {
    // BR-124 forbids skipping the card, so there is nowhere forward to offer. A
    // button that pretended otherwise would have to break the rule to work.
    var left = false;
    await tester.pumpWidget(
      wrapForTest(StudyBlockedSectionWidget(onLeave: () => left = true)),
    );

    await tester.tap(find.text('Leave session'));
    await tester.pump();

    expect(left, isTrue);
  });

  group('the deal is seeded, not drawn from a live generator (BR-127)', () {
    // The bug this replaces: `studyModeView` took a `Random` held by the screen
    // and consumed it on every build, so any rebuild — locking the buttons
    // during a write was enough — re-dealt the board and reordered the five
    // options. BR-127 also wants both stable across a Resume, which a live
    // generator can never be.
    StudySessionState stateFor(StudyMode mode, List<StudyCardModel> pool) =>
        StudySessionState(
          session: StudySessionEntity(
            id: 's1',
            deckId: 'd1',
            rootDeckId: 'd1',
            schedulerGeneration: 1,
            kind: StudySessionKind.reviewing,
            currentMode: mode,
            status: StudySessionStatus.inProgress,
            endReason: null,
            cursor: 0,
            cardLimit: 20,
            startedAt: DateTime.utc(2026, 8, 7),
            endedAt: null,
            direction: null,
          ),
          turn: turnOf(mode, pool.first),
          sessionCards: pool,
          schedulerType: SchedulerType.eightBox,
        );

    List<String> boardOrder(Widget view) => (view as MatchBoardSectionWidget)
        .board
        .meanings
        .map((tile) => tile.cardId)
        .toList();

    test('the match board is identical on a second build', () {
      final pool = <StudyCardModel>[
        for (var i = 0; i < 8; i++) card('c$i', back: 'b$i'),
      ];
      final state = stateFor(StudyMode.match, pool);

      Widget build() => studyModeView(
        mode: StudyMode.match,
        state: state,
        onAnswer:
            (
              action, {
              cardId,
              outcomeReason,
              comparisonVersion,
              hasUsedHint,
            }) async => commitOf('c'),
        onContinue: () {},
        onLookBack: () {},
      )!;

      expect(boardOrder(build()), boardOrder(build()));
    });

    test('and a different round deals a different board', () {
      // The counterpart: without it, "stable across builds" also passes on a
      // board that is never shuffled at all.
      final pool = <StudyCardModel>[
        for (var i = 0; i < 8; i++) card('c$i', back: 'b$i'),
      ];
      final roundOne = stateFor(StudyMode.match, pool);
      final roundTwo = roundOne.copyWith(
        turn: roundOne.turn!.copyWith(
          item: roundOne.turn!.item.copyWith(round: 2),
        ),
      );

      Widget build(StudySessionState state) => studyModeView(
        mode: StudyMode.match,
        state: state,
        onAnswer:
            (
              action, {
              cardId,
              outcomeReason,
              comparisonVersion,
              hasUsedHint,
            }) async => commitOf('c'),
        onContinue: () {},
        onLookBack: () {},
      )!;

      expect(boardOrder(build(roundOne)), isNot(boardOrder(build(roundTwo))));
    });
  });
}
