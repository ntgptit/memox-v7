@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/support/study_mode_feedback_widget.dart';

import '../features/study/domain/support/fake_study_repository.dart';
import '../support/golden_density.dart';
import '../support/study_render.dart';
import '../visual_audit/study_audit_harness.dart';

/// Every state a `fill` turn is actually *in*, split out of
/// `study_modes_demo_test.dart` the same way `guess` and `match` were.
///
/// **The idle render stays with the five-stage sweep**; what lives here is what
/// only `fill` has: something typed into the card, a hint asked for, the two
/// verdicts, a meaning of the length BR-08 allows, and the layout under a
/// keyboard.
///
/// The graded states pass no `onFeedbackShown`, so they can settle: with one,
/// settling would wait out the reading budget and photograph the screen after
/// the session had already moved on.
void main() {
  StudyCardModel card(
    String id, {
    required String front,
    required String back,
    String? example,
    String? hint,
  }) => StudyCardModel(
    id: id,
    front: front,
    back: back,
    example: example,
    hint: hint,
    pronunciation: null,
    frontFolded: front,
    backFolded: back,
  );

  /// The same five cards the sweep uses, so the idle render there and the states
  /// here are pictures of one screen rather than of two fixtures.
  List<StudyCardModel> deck() => <StudyCardModel>[
    card(
      'c1',
      front: '사과',
      back: 'quả táo',
      example: '사과를 먹었어요.',
      hint: 'bắt đầu bằng 사',
    ),
    card(
      'c2',
      front: '안녕하세요',
      back:
          'Xin chào / Chào hỏi lịch sự (Câu chào dùng với người lớn tuổi hoặc '
          'người mới gặp; 안녕: bình an, 하세요: đuôi câu thể lịch sự)',
      example: '안녕하세요, 반갑습니다.',
    ),
    card('c3', front: '물', back: 'nước', example: '물 한 잔 주세요.'),
    card('c4', front: '책', back: 'quyển sách', example: '그녀는 책을 읽었어요.'),
    card('c5', front: '바다', back: 'biển', example: '바다가 잔잔했어요.'),
  ];

  /// `fill`'s worst case: a meaning that runs to five or six lines.
  ///
  /// **BR-08 gives the back 240 characters because a real gloss is two languages
  /// plus the note that says which to use.** The default deck's `quả táo` is the
  /// case that never wraps — and the case that hid a prompt set in a headline
  /// rung, cut at six lines by an ellipsis that removed exactly the half
  /// distinguishing two similar cards.
  List<StudyCardModel> longMeaningDeck() => <StudyCardModel>[
    card(
      'c1',
      front: '허전하다',
      back:
          'Empty, hollow / Trống rỗng, hụt hẫng (Tính từ, dùng khi cảm thấy '
          'mất mát hoặc thiếu vắng sau chia tay, kết thúc, hoặc khi một điều '
          'quen thuộc không còn nữa)',
      example: '집이 허전해요.',
      hint: 'bắt đầu bằng 허',
    ),
    ...deck().skip(1),
  ];

  StudyTurnModel turnFor(List<StudyCardModel> cards) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: StudyMode.fill,
      round: 1,
      cardId: cards.first.id,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
    ),
    progress: StudyStageProgressModel(
      round: 1,
      done: 2,
      total: 5,
      completedCardIds: const <String>[],
      roundCardIds: <String>[for (final c in cards) c.id],
    ),
    card: cards.first,
  );

  /// The `fill` screen, opened on the card each state below acts on.
  ///
  /// [surface] is logical. The default is the shared review frame; the keyboard
  /// render passes the Android viewport the UI contract names, so the two cards
  /// can be judged at the height a real phone leaves them.
  Future<void> pumpFill(
    WidgetTester tester,
    Brightness brightness, {
    List<StudyCardModel>? cards,
    Size surface = kReviewSurface,
  }) async {
    final deckCards = cards ?? deck();
    final repository = FakeStudyRepository(stageExhausted: false)
      ..cards = deckCards
      ..nextTurn_ = turnFor(deckCards);

    await pumpReview(
      tester,
      ReviewApp(
        brightness: brightness,
        home: studyScreenWith(
          repository,
          const StudySessionScreen(
            deckId: 'deck-1',
            kind: StudySessionKind.reviewing,
            reviewMode: StudyMode.fill,
          ),
        ),
      ),
      surface: surface,
    );
  }

  for (final (label, brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    // **`fill` while typing, because that is the state the concept draws.** The
    // answer card *is* the field, so an idle render shows a placeholder and
    // nothing else — this is the one that shows where a typed term actually
    // lands, and that it lands in the Korean the mode asks for rather than the
    // gloss.
    testWidgets('study fill typing — $label', (tester) async {
      await pumpFill(tester, brightness);

      await tester.enterText(find.byType(TextField), '사과');
      await tester.pumpAndSettle();

      await matchesReviewGolden('goldens/study_fill_typing_$label.png');
    });

    // **The hint, inside the prompt card.** It is the state that proves the hint
    // does not open a third surface between the two cards and does not move the
    // answer card or the row below it (BR-136).
    testWidgets('study fill hint — $label', (tester) async {
      await pumpFill(tester, brightness);

      await tester.tap(find.text('Show hint'));
      await tester.pumpAndSettle();

      await matchesReviewGolden('goldens/study_fill_hint_$label.png');
    });

    // **The correct verdict.** The accent is the card's own edge, an icon and a
    // line — never a flooded surface, which would put the strongest thing on
    // screen behind the one thing worth reading.
    testWidgets('study fill correct — $label', (tester) async {
      await pumpFill(tester, brightness);

      await tester.enterText(find.byType(TextField), '사과');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      await matchesReviewGolden('goldens/study_fill_correct_$label.png');

      // **The verdict outlives the frame it was drawn in.** A graded answer is
      // held on screen for its reading budget before the session fetches the
      // next card, and `pumpAndSettle` does not run a `Future.delayed` out —
      // flutter_test then fails the test for a pending timer. Running it here is
      // what proves the hold is real rather than hiding it.
      await tester.pump(AppStudyFeedback.fillCorrect);
      await tester.pumpAndSettle();
    });

    // **The wrong verdict**, and the one BR-138 makes a render worth having: the
    // learner's own attempt is not stored and is not echoed, so the card shows
    // the term that was missed and does not repeat the meaning above it.
    testWidgets('study fill incorrect — $label', (tester) async {
      await pumpFill(tester, brightness);

      await tester.enterText(find.byType(TextField), '바다');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      await matchesReviewGolden('goldens/study_fill_incorrect_$label.png');

      await tester.pump(AppStudyFeedback.fillWrong);
      await tester.pumpAndSettle();
    });

    // **A meaning of the length BR-08 actually allows.** Four to six lines is
    // the case the old headline-sized prompt could not hold and the ellipsis
    // hid; the prompt card scrolls rather than truncating, and the pair stays
    // balanced either way.
    testWidgets('study fill long meaning — $label', (tester) async {
      await pumpFill(tester, brightness, cards: longMeaningDeck());

      await matchesReviewGolden('goldens/study_fill_long_meaning_$label.png');
    });
  }

  // **412×915 with the keyboard up, which is the layout claim.** Both cards
  // shrink together, neither collapses, and Hint and Check stay above the
  // keyboard — the three things a full-height render cannot show.
  testWidgets('study fill keyboard — light', (tester) async {
    tester.view.padding = _androidSafeArea;
    tester.view.viewInsets = _androidKeyboardInset;

    await pumpFill(tester, Brightness.light, surface: _androidViewport);

    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '사과');
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/study_fill_keyboard_light.png');
  });
}

/// The viewport the UI contract names: a mid-range Android phone, in logical
/// pixels.
const Size _androidViewport = Size(412, 915);

/// A status bar and a gesture bar, in **physical** pixels — `FakeViewPadding` is
/// not scaled by the view's density for us.
const FakeViewPadding _androidSafeArea = FakeViewPadding(
  top: 24 * kGoldenDevicePixelRatio,
  bottom: 24 * kGoldenDevicePixelRatio,
);

/// A soft keyboard, physical again. 300 logical is a Korean IME with its
/// candidate bar — the tallest thing that routinely covers this screen.
const FakeViewPadding _androidKeyboardInset = FakeViewPadding(
  bottom: 300 * kGoldenDevicePixelRatio,
);
