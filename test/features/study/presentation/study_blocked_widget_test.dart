import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/states/study_session_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_blocked_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_mode_view_widget.dart';

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
        ),
        card: forCard,
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
      ),
      onAnswer: (action, {outcomeReason, comparisonVersion, hasUsedHint}) =>
          answers.add(action),
      onContinue: () {},
      random: Random(1),
    );

    expect(view, isNull);
    // BR-124: nothing is recorded, and the card is not skipped.
    expect(answers, isEmpty);
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
}
