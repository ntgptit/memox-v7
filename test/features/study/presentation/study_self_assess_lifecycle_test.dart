import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_card_face_section_widget.dart';

import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// `self_assess`'s half of the shared lifecycle, which it had quietly lost.
///
/// **The regression compiled.** Dart lets a function returning a value stand in
/// for a `void` one, so when the answer sink started returning a receipt, this
/// widget's `ValueChanged<StudyAction>` accepted it and threw it away — and with
/// nothing left to hand to `onFeedbackShown`, the mode wrote its answer and then
/// sat on the same card forever. No analyzer complains about a discarded return
/// value; only a test that watches for the *next* step does.
void main() {
  StudyTurnModel turnOf(String id) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: StudyMode.selfAssess,
      round: 1,
      cardId: id,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
      direction: null,
    ),
    progress: const StudyStageProgressModel(
      round: 1,
      done: 0,
      total: 1,
      completedCardIds: <String>[],
    ),
    card: StudyCardModel(
      id: id,
      front: 'front-$id',
      back: 'back-$id',
      example: null,
      hint: null,
      pronunciation: null,
      frontFolded: 'front-$id',
      backFolded: 'back-$id',
    ),
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required Future<StudyAnswerCommitModel?> Function(StudyAction) onAction,
    List<bool>? advanced,
  }) => tester.pumpWidget(
    wrapForTest(
      StudyCardFaceSectionWidget(
        turn: turnOf('c1'),
        actions: const <StudyAction>[
          StudyAction.forgotten,
          StudyAction.remembered,
        ],
        onAction: onAction,
        onFeedbackShown: ({required isCorrect}) async =>
            advanced?.add(isCorrect),
        onContinue: () {},
      ),
      isScrollable: false,
    ),
  );

  /// The actions only appear once the card has been turned over (BR-112).
  Future<void> reveal(WidgetTester tester) async {
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
  }

  testWidgets('a committed answer moves the session on exactly once', (
    tester,
  ) async {
    final advanced = <bool>[];
    await pumpCard(
      tester,
      onAction: (_) async => commitOf('c1'),
      advanced: advanced,
    );
    await reveal(tester);

    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(advanced, <bool>[true]);
  });

  testWidgets('a refused answer moves nothing and can be given again', (
    tester,
  ) async {
    var writes = 0;
    final advanced = <bool>[];
    await pumpCard(
      tester,
      onAction: (_) async {
        writes += 1;

        return null;
      },
      advanced: advanced,
    );
    await reveal(tester);

    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(advanced, isEmpty, reason: 'nothing committed, so nothing advances');

    // The buttons come back: refusing an answer *and* going dead leaves a screen
    // the user cannot get out of.
    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(writes, 2);
  });

  testWidgets('a second tap during the write is not a second answer', (
    tester,
  ) async {
    // BR-126: one question yields at most one turn. The controller's own
    // `isSubmitting` reaches this widget on the next rebuild, and a second tap
    // fits inside that gap — so the guard has to be local.
    var writes = 0;
    final write = PendingCommit();
    await pumpCard(
      tester,
      onAction: (_) {
        writes += 1;

        return write.future;
      },
    );
    await reveal(tester);

    await tester.tap(find.text('Remembered'));
    await tester.pump();
    await tester.tap(find.text('Forgot'));
    await tester.pump();

    expect(writes, 1);

    write.commit('c1');
    await tester.pumpAndSettle();
  });

  testWidgets('nothing advances while the write is still open', (tester) async {
    final advanced = <bool>[];
    final write = PendingCommit();
    await pumpCard(tester, onAction: (_) => write.future, advanced: advanced);
    await reveal(tester);

    await tester.tap(find.text('Remembered'));
    await tester.pumpAndSettle();

    expect(advanced, isEmpty);

    write.commit('c1');
    await tester.pumpAndSettle();

    expect(advanced, <bool>[true]);
  });
}
