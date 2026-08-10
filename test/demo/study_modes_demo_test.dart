@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
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
    frontFolded: front,
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

  /// `browse`'s deck: a Korean term on the front, its meaning on the back.
  ///
  /// **The shape BR-08 already fixed, and the one two earlier passes got
  /// backwards.** The front is capped at 60 characters because it is the prompt
  /// a phone draws on one line; the back at 240 because "một nghĩa chứa nhiều
  /// hơn một từ — hai ngôn ngữ, ngăn bằng dấu phẩy". The fixture before this one
  /// put a 67-character gloss on the *front* — data the app refuses to save —
  /// and every typography decision taken from that render was reasoning about a
  /// card the product cannot hold.
  List<StudyCardModel> browseDeck() => <StudyCardModel>[
    card(
      'b1',
      front: '부끄러워하다',
      back:
          'Be shy / Ngượng ngùng (Động từ, thể hiện sự e ngại trong giao '
          'tiếp)',
    ),
    ...deck().skip(1),
  ];

  /// `match`'s deck: Korean terms on the front, meanings on the back.
  ///
  /// **Four long meanings and one short one, because density is the thing being
  /// judged.** BR-08 gives the front 60 characters and the back 240 because the
  /// front is the prompt and the back is a gloss in two languages plus the note
  /// that says which to use. A board of two-word meanings is the case that never
  /// wraps — and the case that hid the meaning column being drawn in the same
  /// bold voice as the term, then cut at two lines. These are the shape of the
  /// decks this app is actually for: five and six lines each, and one deliberate
  /// short one so a sparse tile can be checked for centring in the same render.
  List<StudyCardModel> matchDeck() => <StudyCardModel>[
    card(
      'm1',
      front: '애석하다',
      back:
          'Regrettable, lamentable / Rất đáng tiếc, đáng thương tiếc (Tính từ, '
          'sắc thái trang trọng; hay dùng trong tin tức, tai nạn hoặc mất mát '
          'lớn)',
    ),
    card(
      'm2',
      front: '허전하다',
      back:
          'Empty, hollow / Trống rỗng, hụt hẫng (Tính từ, dùng khi cảm thấy '
          'mất mát hoặc thiếu vắng sau chia tay, kết thúc, hoặc khi một điều '
          'quen thuộc không còn nữa)',
    ),
    card(
      'm3',
      front: '민망하다',
      back:
          'Embarrassed, awkward / Ngại, khó xử, bối rối vì tình huống (Tính '
          'từ, dùng khi tình huống trở nên awkward hoặc khiến mình thấy ngại)',
    ),
    card(
      'm4',
      front: '초조하다',
      back:
          'Nervous, impatient / Sốt ruột, nóng ruột, bồn chồn (Tính từ, dùng '
          'khi đang chờ đợi hoặc lo vì điều gì chưa xảy ra)',
    ),
    card('m5', front: '부끄러워하다', back: 'Be shy / Ngượng ngùng'),
  ];

  /// The turn a render opens on.
  ///
  /// **`roundCardIds` comes from the deck, never from a literal.** It was
  /// hardcoded to the default deck's ids, so a mode with its own fixture dealt
  /// a board of cards the session did not contain — `match` rendered an empty
  /// grid and the assertion that caught it was the only thing that noticed.
  StudyTurnModel turnFor(
    StudyMode mode, {
    required List<StudyCardModel> cards,
  }) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: mode,
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

  /// A string the mode is guaranteed to put on screen.
  ///
  /// `fill` is the one mode that shows the **back**: it asks for the Korean term
  /// rather than showing it (BR-134). It used to be listed here as the mode that
  /// shows its `example`, which is the prompt this task replaced — an example
  /// sentence contains the answer, so the screen was asking and answering the
  /// same question.
  String contentOf(StudyMode mode, StudyCardModel card) =>
      mode == StudyMode.fill ? card.back : card.front;

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
        final cards = switch (mode) {
          StudyMode.browse => browseDeck(),
          StudyMode.match => matchDeck(),
          _ => deck(),
        };
        final repository = FakeStudyRepository(stageExhausted: false)
          ..cards = cards
          ..nextTurn_ = turnFor(mode, cards: cards);

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

        // **BR-08, asserted on the fixture itself.** Two passes of typography
        // were reasoned out of a render whose front was 67 characters — longer
        // than the product allows, so the card on screen was one no user could
        // ever create. A picture of impossible data is worse than no picture.
        for (final subject in cards) {
          expect(
            subject.front.length,
            lessThanOrEqualTo(CardSide.front.maxLength),
            reason: 'BR-08 caps the front at ${CardSide.front.maxLength}',
          );
          expect(
            subject.back.length,
            lessThanOrEqualTo(CardSide.back.maxLength),
            reason: 'BR-08 caps the back at ${CardSide.back.maxLength}',
          );
        }

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
}
