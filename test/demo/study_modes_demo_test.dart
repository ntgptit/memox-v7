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
import 'package:memox/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart';

import '../features/study/domain/support/fake_study_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/study_audit_harness.dart';

/// Device-faithful renders of **all five study stages**, for a human to look at.
///
/// **The gap this closes is the same one `deck_screens_demo_test.dart` closed
/// for decks, and it is wider here.** `study_session_screen_visual_audit_test`
/// audits exactly one state — `self_assess` on a turned-over card — and says so
/// on the grounds that every other mode "shows strictly less chrome, or the same
/// chrome under a different body". That is true of the *chrome* and false of the
/// *body*: `match` deals a board, `guess` stacks five option rows, `recall` runs
/// a clock over two equal cards, and `fill` puts a text field under the prompt.
/// Four of the five screens a learner actually sees had no picture of themselves
/// anywhere in the repo.
///
/// Each stage is rendered light and dark. The pair is the point: the modes carry
/// state in colour — selected, paired, wrong, dimmed, cleared — and a fill that
/// reads as a step down in light can read as a step *up* in dark, which is how
/// the cleared match slot came out lighter than the page it was meant to be a
/// hole in.
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
    backFolded: back,
  );

  /// Five cards, because that is the smallest set every stage accepts: `guess`
  /// needs five distinct meanings (BR-121) and `match` needs two pairs (BR-153).
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
      // **One deliberately long meaning, in the shape a real deck uses.** Every
      // option being two words is the case that never wraps, and the case that
      // hid how a row behaves for the content this app is actually for.
      back:
          'Xin chào / Chào hỏi lịch sự (Câu chào dùng với người lớn tuổi hoặc '
          'người mới gặp; 안녕: bình an, 하세요: đuôi câu thể lịch sự)',
      example: '안녕하세요, 반갑습니다.',
    ),
    card('c3', front: '물', back: 'nước', example: '물 한 잔 주세요.'),
    card('c4', front: '책', back: 'quyển sách', example: '그녀는 책을 읽었어요.'),
    card('c5', front: '바다', back: 'biển', example: '바다가 잔잔했어요.'),
  ];

  /// `browse`'s deck, whose first card carries a front that wraps.
  ///
  /// **The realistic case, and the one a one-word fixture hid.** A front is not
  /// a term: decks in this app hold "Be shy / Ngượng ngùng (Động từ, thể hiện
  /// sự e ngại trong giao tiếp)" on it. Rendered at the prompt size that used
  /// to be hardcoded here, three headline lines swallowed the card and left the
  /// back in the corner of its own half — so the render that guards the
  /// balance has to contain one.
  List<StudyCardModel> browseDeck() => <StudyCardModel>[
    card(
      'b1',
      front:
          'Be shy / Ngượng ngùng (Động từ, thể hiện sự e ngại trong giao '
          'tiếp)',
      back: 'ngượng ngùng',
    ),
    ...deck().skip(1),
  ];

  StudyTurnModel turnFor(StudyMode mode, {required StudyCardModel first}) =>
      StudyTurnModel(
        item: StudyQueueItemEntity(
          sessionId: 'session-1',
          mode: mode,
          round: 1,
          cardId: first.id,
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
          roundCardIds: <String>['c1', 'c2', 'c3', 'c4', 'c5'],
        ),
        card: first,
      );

  /// A string the mode is guaranteed to put on screen. `fill` asks about the
  /// card's example rather than its front, so one field cannot cover all five.
  String contentOf(StudyMode mode, StudyCardModel card) =>
      mode == StudyMode.fill ? card.example! : card.front;

  /// The mode chip as the top bar draws it — uppercased at the join (#239).
  String chipOf(StudyMode mode) => switch (mode) {
    StudyMode.browse => 'BROWSE',
    StudyMode.match => 'MATCH',
    StudyMode.guess => 'GUESS',
    StudyMode.recall => 'RECALL',
    StudyMode.fill => 'FILL IN',
    StudyMode.selfAssess => 'SELF ASSESS',
    StudyMode.unknown => 'UNKNOWN',
  };

  const stages = <StudyMode>[
    StudyMode.browse,
    StudyMode.match,
    StudyMode.guess,
    StudyMode.recall,
    StudyMode.fill,
  ];

  for (final mode in stages) {
    for (final (label, brightness) in <(String, Brightness)>[
      ('light', Brightness.light),
      ('dark', Brightness.dark),
    ]) {
      testWidgets('study ${mode.name} — $label', (tester) async {
        final cards = mode == StudyMode.browse ? browseDeck() : deck();
        final repository = FakeStudyRepository(stageExhausted: false)
          ..cards = cards
          ..nextTurn_ = turnFor(mode, first: cards.first);

        await pumpReview(
          tester,
          ReviewApp(
            brightness: brightness,
            home: studyScreenWith(
              repository,
              StudySessionScreen(
                deckId: 'deck-1',
                // **A reviewing session runs exactly one mode — except for
                // `browse`, which a reviewing session refuses outright.**
                // BR-146 offers only the graded modes for review, so opening
                // `browse` this way produced "Nothing to review yet" and the
                // golden recorded an empty state under the name of a screen it
                // never rendered. A learning session walks the algorithm's
                // sequence and opens *on* `browse`, which is where the mode
                // actually lives.
                kind: mode == StudyMode.browse
                    ? StudySessionKind.learning
                    : StudySessionKind.reviewing,
                reviewMode: mode == StudyMode.browse ? null : mode,
              ),
            ),
          ),
        );

        // **The golden cannot be the only witness.** It recorded "Nothing to
        // review yet" under the name `study_browse` for as long as the fixture
        // opened the wrong session kind, and a picture of the wrong screen
        // looks exactly as green as a picture of the right one. These three
        // assertions are what a wrong screen cannot satisfy: the mode's own
        // chip, the frame that carries it, and a piece of the card's content.
        expect(find.byType(StudySessionFrameSectionWidget), findsOneWidget);
        expect(find.text(chipOf(mode)), findsOneWidget);
        expect(find.text(contentOf(mode, cards.first)), findsWidgets);

        await matchesReviewGolden('goldens/study_${mode.name}_$label.png');
      });
    }
  }

  for (final (label, brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    // **`fill` while typing, because that is the state the handout draws.**
    // `fill_mode.png` is titled "đang nhập" and §6 asks for the typed value
    // centred and large — a floating label sits left and small until something
    // is in the field, so an empty render cannot show the thing being specified.
    testWidgets('study fill typing — $label', (tester) async {
      final cards = deck();
      final repository = FakeStudyRepository(stageExhausted: false)
        ..cards = cards
        ..nextTurn_ = turnFor(StudyMode.fill, first: cards.first);

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
      );

      await tester.enterText(find.byType(TextField), 'quả táo');
      await tester.pumpAndSettle();

      await matchesReviewGolden('goldens/study_fill_typing_$label.png');
    });

    // **The graded state, which no render covered.** It is the one place the
    // verdict tokens are drawn, and BR-138 makes it the one place that has to
    // be checked for what it does *not* show: the learner's own attempt is not
    // stored and is not echoed, so a wrong turn shows the card's back and
    // nothing else.
    testWidgets('study fill graded — $label', (tester) async {
      final cards = deck();
      final repository = FakeStudyRepository(stageExhausted: false)
        ..cards = cards
        ..nextTurn_ = turnFor(StudyMode.fill, first: cards.first);

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
      );

      await tester.enterText(find.byType(TextField), 'sai rồi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      await matchesReviewGolden('goldens/study_fill_graded_$label.png');
    });
  }
}
