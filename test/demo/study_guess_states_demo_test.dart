@Tags(<String>['golden', 'review'])
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/guess_question_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../support/study_render.dart';

/// The three states a `guess` question is actually *in*, on the content it is
/// for.
///
/// **A one-word fixture proves nothing here.** Every layout decision this screen
/// has — left-aligned text, `bodyMedium` rather than a heading, no ellipsis, a
/// prompt card that gives way so five rows fit — exists because a real meaning
/// runs to three or four lines in two languages. Rendered against "apple", all
/// five rows are one line and the screen looks like a quiz on a poster.
///
/// The answered states can settle here only because no `onFeedbackShown` is
/// passed: with one, settling would wait out the reading budget and photograph
/// the screen after the session had moved on.
void main() {
  StudyCardModel card(
    String id, {
    required String front,
    required String back,
  }) => StudyCardModel(
    id: id,
    front: front,
    back: back,
    example: null,
    hint: null,
    pronunciation: null,
    frontFolded: front,
    backFolded: back,
  );

  /// Five meanings in the shape BR-08 allows: two languages, a part of speech,
  /// and the note that says which of the two a learner should reach for.
  final pool = <StudyCardModel>[
    card(
      'c1',
      front: '외롭다',
      back:
          'Lonely / Cô đơn (Tính từ, cảm giác buồn khi không có ai bên cạnh '
          'hoặc không có ai hiểu mình)',
    ),
    card(
      'c2',
      front: '쌀쌀하다',
      back:
          'To be chilly / Se se lạnh (Tính từ, chỉ thời tiết lạnh nhẹ, thường '
          'gặp vào mùa thu, không quá rét)',
    ),
    card(
      'c3',
      front: '영하',
      back:
          'Below zero / Dưới không độ (Danh từ, chỉ nhiệt độ dưới không độ, '
          'nhiệt độ âm, thường vào mùa đông)',
    ),
    card(
      'c4',
      front: '세수하다',
      back:
          "To wash one's face / Rửa mặt (Động từ, hành động rửa sạch mặt bằng "
          'nước và xà phòng)',
    ),
    card(
      'c5',
      front: '해수욕장',
      back:
          'Beach / Bãi tắm biển (Danh từ, nơi công cộng ở bãi biển dành cho '
          'tắm nắng và bơi lội)',
    ),
  ];

  final question = const GuessModeHandler().buildQuestion(
    term: pool.first,
    pool: pool,
    random: Random(1),
  )!;

  StudyTurnModel turnOf() => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: StudyMode.guess,
      round: 1,
      cardId: pool.first.id,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
      direction: null,
    ),
    progress: StudyStageProgressModel(
      round: 1,
      done: 2,
      total: pool.length,
      completedCardIds: const <String>[],
      roundCardIds: <String>[for (final subject in pool) subject.id],
    ),
    card: pool.first,
  );

  Widget screen({required Brightness brightness}) => ReviewApp(
    brightness: brightness,
    home: MxContentShell(
      padding: EdgeInsets.zero,
      body: StudySessionFrameSectionWidget(
        mode: StudyMode.guess,
        kind: StudySessionKind.reviewing,
        cardCount: pool.length,
        progress: turnOf().progress,
        onClose: () {},
        child: GuessQuestionSectionWidget(
          question: question,
          turn: turnOf(),
          onChosen: (option) async => StudyAnswerCommitModel(
            cardId: option.cardId,
            round: 1,
            currentItemStatus: StudyQueueItemStatus.completed,
          ),
        ),
      ),
    ),
  );

  for (final (label, brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('guess open — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      expect(find.byType(GuessQuestionSectionWidget), findsOneWidget);
      expect(find.text(pool.first.front), findsOneWidget);

      await matchesReviewGolden('goldens/guess_open_$label.png');
    });

    testWidgets('guess correct — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      await tester.tap(find.text(pool.first.back));
      await _settle(tester);

      await matchesReviewGolden('goldens/guess_correct_$label.png');
    });

    testWidgets('guess wrong — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      // A meaning that is not the term's: the row picked is marked as the
      // learner's, and the right answer is marked as right anyway.
      await tester.tap(find.text(pool[2].back));
      await _settle(tester);

      await matchesReviewGolden('goldens/guess_wrong_$label.png');
    });
  }
}

/// Runs the row's crossfade **and the tap's ink** all the way out.
///
/// Two pumps were not enough, and the picture said so: the splash the tap left
/// on the chosen row was still fading, which put a tint on exactly the row whose
/// contract is that it carries none. A reviewer reading that frame would have
/// seen the fill this change removed.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}
