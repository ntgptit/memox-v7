@Tags(<String>['golden', 'review'])
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_durations.dart';
import 'package:memox/features/study/domain/models/match_mode.dart';
import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/items/match_tile_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/match_board_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../support/study_render.dart';

/// The three states a match board is actually *in* while somebody plays it.
///
/// **`study_modes_demo_test.dart` renders the board it opens on and nothing
/// else.** That is one of five states: `idle` with nothing answered. The two
/// that carry the mode's whole feedback contract — a wrong pair holding red, a
/// correct pair holding green — last for a fixed beat and then undo themselves,
/// so no render that settles can ever contain them, and the board mid-round with
/// blanks in it is a fourth. Those three had no picture anywhere in the repo,
/// which is exactly the set a reviewer is asked about.
///
/// **These pump rather than settle, and that is the point.** `pumpAndSettle`
/// waits for `wrongHold` and `successFlash` to expire — the state under test is
/// the thing it is waiting to see the end of. Each test pumps one frame, captures,
/// and only then runs the hold out, because `flutter_test` asserts no timer is
/// still pending when a test finishes.
///
/// The board is driven directly rather than through the session screen: the
/// screen swaps to its loading state while an answer is written, which unmounts
/// the board and takes the state being photographed with it. `onPairAttempt` is
/// a no-op here for the same reason.
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
    backFolded: back,
  );

  /// The same five cards `study_modes_demo_test.dart` deals, so the two suites
  /// photograph one deck rather than two.
  final cards = <StudyCardModel>[
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

  /// Two cards already answered, so the render has the blanks a mid-round board
  /// has. They are not in the same row: the two columns are independent shuffles
  /// (BR-127), which is what makes an emptied slot look like the board working
  /// rather than like a hole punched through a row.
  const paired = <String>{'m1', 'm4'};

  /// The card the tests act on, and the one they get wrong with. Both chosen
  /// from what is still in play, and both found by **text** — a row index would
  /// name whatever the shuffle put there.
  final subject = cards[2];
  final other = cards[1];

  final board = const MatchModeHandler().buildBoard(cards, Random(1))!;

  Widget screen({required Brightness brightness}) => ReviewApp(
    brightness: brightness,
    home: MxContentShell(
      // Production passes `EdgeInsets.zero` and lets the frame gutter its own
      // parts; anything else here would photograph a board inset twice.
      padding: EdgeInsets.zero,
      body: StudySessionFrameSectionWidget(
        mode: StudyMode.match,
        kind: StudySessionKind.reviewing,
        cardCount: cards.length,
        progress: StudyStageProgressModel(
          round: 1,
          done: paired.length,
          total: cards.length,
          completedCardIds: paired.toList(),
          roundCardIds: <String>[for (final subject in cards) subject.id],
        ),
        onClose: () {},
        child: MatchBoardSectionWidget(
          board: board,
          pairedCardIds: paired,
          // **A committed receipt, because the board now waits for one**
          // (BR-157). A no-op returning null would photograph a board that
          // refused every pair, which is a real state but not this one.
          onPairAttempt: (term, {required isCorrect}) async =>
              StudyAnswerCommitModel(
                cardId: term.cardId,
                round: 1,
                currentItemStatus: isCorrect
                    ? StudyQueueItemStatus.completed
                    : StudyQueueItemStatus.pending,
              ),
        ),
      ),
    ),
  );

  for (final (label, brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('match mid-round, nothing selected — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      // Two cards answered leave four empty slots and six tiles still in play.
      // Asserted, because an empty slot and a tile that failed to render are
      // the same picture — and an emptied slot keeps its `Text` in the tree at
      // opacity 0, so absence is the wrong question to ask about it.
      expect(_contentOpacity(tester, subject.front), 1);
      expect(_contentOpacity(tester, other.back), 1);
      expect(_contentOpacity(tester, cards.first.front), 0);
      expect(_contentOpacity(tester, cards.first.back), 0);
      // An emptied slot is still a pair the user got right, and still says so.
      expect(_semanticValues(tester, 'Paired'), paired.length * 2);

      await matchesReviewGolden('goldens/study_match_progress_idle_$label.png');
    });

    // **The state the other three are judged against, and the only one that was
    // missing.** `idle`, `wrong` and `paired` all had a picture; the tile a
    // person has just tapped did not — and it is the one the mode cannot work
    // without. Every tap in `match` is two: this is what the board looks like
    // between them, for as long as it takes to find the other half.
    //
    // It is also the state with the least to say. Since #269 a selection is an
    // edge and an ink on the same fill an idle tile carries, so the whole signal
    // is a hairline and a colour shift in the text — against a board of nine
    // other tiles that are still white. Whether that is enough is a question a
    // render answers and a token table does not.
    testWidgets('match holding a selected tile — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      await tester.tap(find.text(subject.front));
      await _settleColour(tester);

      // Exactly one tile is selected, and it is not marked by an icon: `paired`
      // and `wrong` carry ✓ and ✕, selection carries neither. So the assertion
      // is the absence of both inside the board — a selection that grew a mark
      // would be reading as a result.
      expect(_boardIcons(Icons.check), findsNothing);
      expect(_boardIcons(Icons.close), findsNothing);

      await matchesReviewGolden(
        'goldens/study_match_progress_selected_$label.png',
      );

      // No hold to run out — selection waits for the second tap, not a timer —
      // so the board is left exactly as photographed.
    });

    testWidgets('match holding a wrong pair — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      await tester.tap(find.text(subject.front));
      await tester.pump();
      await tester.tap(find.text(other.back));
      await _settleColour(tester);

      // Both tiles say it, and neither says it with colour alone (WCAG 1.4.1).
      // Scoped to the board: the frame's own ✕ closes the session and its hint
      // line carries a ✓, so an unscoped finder counts the chrome as feedback.
      expect(_boardIcons(Icons.close), findsNWidgets(2));
      expect(_semanticValues(tester, 'Not a pair'), 2);

      await matchesReviewGolden(
        'goldens/study_match_progress_wrong_$label.png',
      );

      // The hold is a real timer, and the framework fails the test if one is
      // still pending. Running it out here rather than settling above is what
      // let the red be photographed at all.
      await tester.pump(AppMatchTile.wrongHold);
      await tester.pumpAndSettle();
    });

    testWidgets('match holding a correct pair — $label', (tester) async {
      await pumpReview(tester, screen(brightness: brightness));

      await tester.tap(find.text(subject.front));
      await tester.pump();
      await tester.tap(find.text(subject.back));
      await _settleColour(tester);

      expect(_boardIcons(Icons.check), findsNWidgets(2));
      // Two more than the four slots already cleared: a cleared tile keeps
      // saying `Paired`, or a screen reader loses the pair off the board
      // altogether once its tick has faded.
      expect(_semanticValues(tester, 'Paired'), paired.length * 2 + 2);

      await matchesReviewGolden(
        'goldens/study_match_progress_paired_$label.png',
      );

      await tester.pump(AppMatchTile.successFlash);
      await tester.pumpAndSettle();
    });
  }
}

/// How many tiles carry [value] as their `Semantics` value.
///
/// The tick and the cross mark a result for people who can see them; this is
/// what marks it for everyone else, and a golden cannot check it.
/// Lets the tile's crossfade finish, while its hold is still running.
///
/// **One pump photographs the first frame of the transition, not the state.**
/// A tile's edge and ink change over [AppDurations.normal], so a single frame
/// after the tap still has the border at its idle weight and hue — a picture of
/// a board that has not reacted yet, which is indistinguishable from one that
/// never did. [AppMatchTile.wrongHold] and [AppMatchTile.successFlash] are both
/// `slow` (320ms) against `normal` (200ms), so there is a window where the
/// colour has landed and the hold has not expired. That window is the state
/// worth photographing, and it is the one a user sees.
///
/// Two pumps, not one: the first is the frame the tap's `setState` produces —
/// where the `AnimatedContainer` *starts* — and the second is the one that
/// lands on the target.
Future<void> _settleColour(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(AppDurations.normal);
}

/// [icon] as drawn **inside the board**, never in the frame around it.
Finder _boardIcons(IconData icon) => find.descendant(
  of: find.byType(MatchBoardSectionWidget),
  matching: find.byIcon(icon),
);

/// What the tile holding [text] is fading its content to.
///
/// A cleared slot keeps its widgets and drops them to zero — the slot is what
/// says the pair is gone, and removing it would move every tile under it.
double _contentOpacity(WidgetTester tester, String text) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

int _semanticValues(WidgetTester tester, String value) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .where((widget) => widget.properties.value == value)
    .length;
