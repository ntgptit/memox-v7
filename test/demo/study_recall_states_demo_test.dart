@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../support/study_render.dart';

/// The three states a `recall` turn is actually *in*, on content it is for.
///
/// **Two of them did not exist before this change and the third meant something
/// else.** The turn used to be over the moment the back appeared, so there was
/// one picture: a covered card with a *Show answer* under it. The reveal now
/// opens a question the learner answers, and the clock's own ending waits for
/// them — which is two screens nobody has seen, and they are the ones a
/// reviewer is being asked about.
///
/// The answered states pump rather than settle where a hold is involved; here
/// nothing holds, so `pumpAndSettle` is safe and lets the tap's ink finish.
void main() {
  const card = StudyCardModel(
    id: 'c1',
    front: '허전하다',
    back:
        'Empty, hollow / Trống rỗng, hụt hẫng (Tính từ, dùng khi cảm thấy mất '
        'mát hoặc thiếu vắng sau chia tay, kết thúc, hoặc khi một điều quen '
        'thuộc không còn nữa)',
    example: null,
    hint: null,
    pronunciation: null,
    frontFolded: '허전하다',
    backFolded: 'Empty, hollow',
  );

  StudyTurnModel turnOf() => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: StudyMode.recall,
      round: 1,
      cardId: card.id,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
    ),
    progress: const StudyStageProgressModel(
      round: 1,
      done: 2,
      total: 5,
      completedCardIds: <String>[],
    ),
    card: card,
  );

  /// The screen as the session mounts it, including the one piece of plumbing
  /// a body-only render would leave out: the frame's hint line is swapped by
  /// the screen when the body reports it has stopped asking (§8.11), so a
  /// picture taken without it shows "Recall it, then show the answer" under a
  /// card whose answer is already up.
  Widget screen({required Brightness brightness}) {
    var isResolved = false;

    return ReviewApp(
      brightness: brightness,
      home: StatefulBuilder(
        builder: (context, setState) => MxContentShell(
          padding: EdgeInsets.zero,
          body: StudySessionFrameSectionWidget(
            mode: StudyMode.recall,
            kind: StudySessionKind.reviewing,
            cardCount: 5,
            progress: turnOf().progress,
            onClose: () {},
            hintOverride: isResolved
                ? context.studyModeHintResolved(StudyMode.recall)
                : null,
            child: RecallTimerSectionWidget(
              turn: turnOf(),
              onResolved: () => setState(() => isResolved = true),
              onOutcome: (_) async => const StudyAnswerCommitModel(
                cardId: 'c1',
                round: 1,
                currentItemStatus: StudyQueueItemStatus.completed,
              ),
            ),
          ),
        ),
      ),
    );
  }

  for (final (label, brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('recall counting down — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      expect(find.text('Show answer'), findsOneWidget);
      // The back is covered, and the bar standing in for it is the only thing
      // that says there is an answer at all.
      expect(find.bySemanticsLabel('Answer hidden'), findsOneWidget);

      await matchesReviewGolden('goldens/recall_counting_down_$label.png');

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();
    });

    testWidgets('recall asking which it was — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot'), findsOneWidget);
      expect(find.text('Remembered'), findsOneWidget);

      await matchesReviewGolden('goldens/recall_self_assess_$label.png');
    });

    testWidgets('recall after the clock ran out — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      await tester.pump(kRecallTurnLimit);
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);

      await matchesReviewGolden('goldens/recall_timed_out_$label.png');
    });
  }
}
