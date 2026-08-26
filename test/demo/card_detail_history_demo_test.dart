@Tags(<String>['golden', 'review'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_not_found_failure.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/card/domain/models/card_history_event_model.dart';

import '../features/card/presentation/support/fake_card_detail_repository.dart';
import 'card_detail_demo_fixtures.dart';
import '../support/study_render.dart';

/// DEMO renders (not assertions) of what a card's **timeline** does — every face
/// of the history band, plus the two whole-screen failures (UC-19, M4.15 W3).
///
/// **Split from `card_detail_demo_test.dart`**, which is about the card itself.
/// The faces here are the ones a reviewer cannot judge from prose: a page that
/// failed *under rows already read*, the two spinners, the empty band, and the
/// deleted-card face whose glyph used to say "no search results".
void main() {
  /// **The fixture states a card the app could actually have produced.**
  /// The first version did not, and three of the headline renders showed it:
  /// the panel read `New · Never answered · Reviews 0 · Box 1` above a timeline
  /// carrying three reviews — a combination no answer can write, since an answer
  /// updates the schedule and the history in one go. Worse for review, the
  /// `forgotten` row said `Box 1 → 2`: a danger word beside a *promotion*, on
  /// the very frame someone would use to judge whether the danger/success
  /// mapping reads. And all three rows carried the same minute, so the timeline
  /// had no legible order.
  ///
  /// A reference picture that contradicts the rule it illustrates is worse than
  /// no picture, so the counts, the dates and the box moves agree here.
  testWidgets('detail — a history page that failed to load, light', (
    tester,
  ) async {
    // The band D24/D25's grammar was just applied to. Rendered because the
    // whole point of that grammar is that it is checked by eye across screens,
    // and a structural diff against the sibling widgets is not that check.
    //
    // **The second page fails, not the first, and that is the whole face.**
    // W3 face 6 is "the events already read **stay**, the tail becomes an error
    // band with `Retry`". Failing the first request instead leaves the timeline
    // empty, so the picture showed a card with nothing in it but an error — the
    // half of the face that matters absent, under a filename claiming to be it.
    // `card_history_controller.dart` says as much in its own words: a failure on
    // the very first page "leaves nothing on screen".
    final repository = loaded()
      ..pages.add(fakeHistoryPage(count: 2, prefix: 'f'));
    repository.pages[0] = CardHistoryPageModel(
      events: repository.pages[0].events,
      hasMore: true,
      nextCursor: repository.pages[0].events.last.cursor,
    );
    await pumpReview(tester, scope(repository, Brightness.light));

    repository.nextHistoryFailure = const DatabaseFailure(message: 'demo');
    await tester.ensureVisible(find.text('Load more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    // Scrolled to the recovery, because the frame used to stop above it.
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_detail_page_error_light.png');
  });

  testWidgets('detail — a history page that failed to load, dark', (
    tester,
  ) async {
    // The one face carrying `errorContainer`, in the mode where the surface
    // ladder is inverted and the band sits on a card that is lighter than the
    // page. It had light only.
    final repository = loaded()
      ..pages.add(fakeHistoryPage(count: 2, prefix: 'f'));
    repository.pages[0] = CardHistoryPageModel(
      events: repository.pages[0].events,
      hasMore: true,
      nextCursor: repository.pages[0].events.last.cursor,
    );
    await pumpReview(tester, scope(repository, Brightness.dark));

    repository.nextHistoryFailure = const DatabaseFailure(message: 'demo');
    await tester.ensureVisible(find.text('Load more'));
    await tester.pumpAndSettle();
    // **The tap, which the first version of this render forgot.**
    // `nextHistoryFailure` only fires on a request, so without it the fixture
    // never failed: the file was byte-identical to the load-more render — a PNG
    // named `page_error_dark` with no error anywhere in it.
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();

    // Asserted before capture, because a wrong frame at the right size looks
    // exactly like a right one.
    expect(find.text('Retry'), findsOneWidget);

    await matchesReviewGolden('goldens/card_detail_page_error_dark.png');
  });

  testWidgets('detail — the Load more tail, dark', (tester) async {
    final repository = loaded()
      ..pages.add(fakeHistoryPage(count: 2, prefix: 'f'));
    repository.pages[0] = CardHistoryPageModel(
      events: repository.pages[0].events,
      hasMore: true,
      nextCursor: repository.pages[0].events.last.cursor,
    );
    await pumpReview(tester, scope(repository, Brightness.dark));
    await tester.ensureVisible(find.text('Load more'));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_detail_load_more_dark.png');
  });

  testWidgets('detail — a card with no history yet, light', (tester) async {
    await pumpReview(
      tester,
      scope(loaded(withHistory: false), Brightness.light),
    );
    // Same fault the page-error frame had: the band this render is named after
    // sat in the last few pixels, with the card's own bottom edge outside the
    // frame — so a reviewer could not tell a clipped band from a broken one,
    // which is the exact confusion V16 wrapped the empty face in a card to
    // prevent.
    await tester.ensureVisible(
      find.text(
        'Reviews appear here after this card '
        'has been studied.',
      ),
    );
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_detail_no_history_light.png');
  });

  testWidgets('detail — the timeline still loading its first page, light', (
    tester,
  ) async {
    // **The one face this screen has never shown anyone.** V16 put a card
    // around the band, which changed what this face looks like, and nothing
    // rendered it — a centred spinner floating 40dp inside a card would have
    // looked exactly as plausible as the correct one. Held open with the
    // repository's own gate, the same lever `card_detail_history_faces_test`
    // uses for `loading-more`, and captured on the first frame so the
    // indicator's phase is the same on every machine.
    final repository = loaded()..historyGate = Completer<void>();
    await pumpReview(
      tester,
      scope(repository, Brightness.light),
      settle: false,
    );
    // **Not frame 0.** At t=0 the indicator's sweep is zero length, so the
    // capture is a single blue dot — a picture that looks like a rendering
    // fault rather than like the face it is meant to show. A fixed offset into
    // the animation is just as deterministic and actually shows an arc.
    await tester.pump(const Duration(milliseconds: 400));

    await matchesReviewGolden('goldens/card_detail_history_loading_light.png');

    repository.historyGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('detail — the next page on its way, light', (tester) async {
    // The sibling of the face above, and the one G6 is really about: the tail
    // swaps a button for a spinner **in place**. There is a geometry assertion
    // for it, and until now no picture — which is the pairing this whole round
    // showed to be worth having.
    final repository = loaded()
      ..pages.add(fakeHistoryPage(count: 2, prefix: 'f'));
    repository.pages[0] = CardHistoryPageModel(
      events: repository.pages[0].events,
      hasMore: true,
      nextCursor: repository.pages[0].events.last.cursor,
    );
    await pumpReview(tester, scope(repository, Brightness.light));

    final gate = Completer<void>();
    repository.historyGate = gate;
    await tester.ensureVisible(find.text('Load more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    // **Two pumps, not one.** The first builds `_InlineSpinner` and paints it
    // at t=0, where the indicator's sweep has zero length — the previous
    // version of this render was a 2.7dp dot. The second advances a fixed
    // offset into the animation it has just started.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await matchesReviewGolden('goldens/card_detail_loading_more_light.png');

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('detail — the Load more tail and a second learning cycle, '
      'light', (tester) async {
    // Two faces in one frame, both of them new since V16 and neither of them
    // photographed: `Load more` is the only place `MxTextButton` meets the
    // card's inner edge, and a second generation heading is the only place the
    // connector breaks on purpose (G5).
    final repository = FakeCardDetailRepository()
      ..seededDetail = fakeCardDetail(
        front: '사과',
        back: 'quả táo',
        tagNames: <String>['noun'],
        currentBox: 3,
        answerCount: 7,
        lapseCount: 1,
        learnedAt: fakeNow.subtract(const Duration(days: 12)),
        dueAt: fakeNow.add(const Duration(days: 2)),
        lastAnsweredAt: fakeNow,
      )
      ..pages.add(
        CardHistoryPageModel(
          events: <CardHistoryEventModel>[
            fakeHistoryEvent(id: 'g2-1', schedulerGeneration: 2),
            fakeHistoryEvent(
              id: 'g1-1',
              action: StudyAction.forgotten,
              answeredAt: fakeNow.subtract(const Duration(days: 30)),
              // A forgotten turn sends the card back down the boxes. Leaving
              // the fixture's 1 → 2 default here put a danger word beside a
              // promotion, on the frame a reviewer uses to judge exactly that
              // mapping — the fault `loaded()` was already corrected for.
              previousBox: 2,
              nextBox: 1,
            ),
            fakeHistoryEvent(
              id: 'g1-2',
              answeredAt: fakeNow.subtract(const Duration(days: 31)),
            ),
          ],
          hasMore: true,
          nextCursor: fakeHistoryEvent(id: 'g1-2').cursor,
        ),
      );
    await pumpReview(tester, scope(repository, Brightness.light));
    await tester.ensureVisible(find.text('Load more'));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_detail_load_more_light.png');
  });

  testWidgets('detail — the card was deleted from another screen, light', (
    tester,
  ) async {
    // The face whose glyph changed this round. `search_off` said "nothing
    // matched your search" on four other screens; a render is what makes the
    // difference visible.
    final repository = loaded();
    await pumpReview(tester, scope(repository, Brightness.light));
    repository.emitDetailError(
      const NotFoundFailure(
        message: 'gone',
        reason: CardNotFoundReason.cardGone,
      ),
    );
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_detail_not_found_light.png');
  });

  testWidgets('detail — the whole read failed, light', (tester) async {
    // W3 face 7, and the app bar's half of it: with nothing to edit the action
    // is gone. Listed in the review doc's state matrix and never photographed —
    // the face is `MxErrorState`, shared, but "shared" is an argument about
    // code and this is a claim about a screen.
    final repository = FakeCardDetailRepository();
    // `settle: false` for the first pump: until the error lands the screen is
    // the whole-page spinner, and `pumpAndSettle` would time out on it rather
    // than reach the face this render is about.
    await pumpReview(
      tester,
      scope(repository, Brightness.light),
      settle: false,
    );
    repository.emitDetailError(const DatabaseFailure(message: 'demo'));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_detail_read_error_light.png');
  });

  testWidgets('detail — the card itself still loading, light', (tester) async {
    // W3 face 1. The read never lands, so this is the frame a user meets before
    // anything else on the screen exists — and, like the timeline's spinner, it
    // had no picture because it never settles.
    await pumpReview(
      tester,
      scope(FakeCardDetailRepository(), Brightness.light),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 400));

    await matchesReviewGolden('goldens/card_detail_loading_light.png');
  });
}
