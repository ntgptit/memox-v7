@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_state_widget.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';

import '../features/card/presentation/support/fake_card_detail_repository.dart';
import 'card_detail_demo_fixtures.dart';
import '../support/study_render.dart';

/// DEMO renders (not assertions) of what a card **says** — the summary hero, the
/// scheduler badge, the progress panel and its grid — driven through the real
/// screen with its one repository faked (UC-19, M4.15). Run with:
///   flutter test --update-goldens --tags golden test/demo/card_detail_demo_test.dart
///
/// **Split from `card_detail_history_demo_test.dart` at the seam the guard's
/// size ceiling exposed, and a real one:** this file is about the card, that one
/// is about its timeline's faces. Same fixtures, same harness, so nothing about
/// the setup diverges.
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
  testWidgets('detail — loaded with history, light', (tester) async {
    await pumpReview(tester, scope(loaded(), Brightness.light));

    await matchesReviewGolden('goldens/card_detail_light.png');
  });

  testWidgets('detail — loaded with history, dark', (tester) async {
    await pumpReview(tester, scope(loaded(), Brightness.dark));

    await matchesReviewGolden('goldens/card_detail_dark.png');
  });

  testWidgets('detail — Vietnamese at 320dp and textScaler 2.0', (
    tester,
  ) async {
    // The narrowest surface with the longest labels: the one combination where
    // an un-carded reading column has to hold together on its spacing alone.
    await pumpReview(
      tester,
      scope(
        loaded(),
        Brightness.light,
        locale: const Locale('vi'),
        textScale: 2,
      ),
      surface: const Size(320, 568),
    );

    await matchesReviewGolden('goldens/card_detail_320_x2_vi.png');
  });

  testWidgets('detail — the schedule grid at 320dp and textScaler 2.0, VI', (
    tester,
  ) async {
    // **The frame above stops before the thing its own comment is about.** At
    // 320dp and scale 2.0 the reading column fills the viewport with the card's
    // two faces, so the state band — the part G8's stacking rule governs — is
    // below the fold and no render showed it. Scrolled to it here, because a
    // geometry assertion pins the numbers and a picture is what a reviewer
    // judges.
    await pumpReview(
      tester,
      scope(
        loaded(),
        Brightness.light,
        locale: const Locale('vi'),
        textScale: 2,
      ),
      surface: const Size(320, 568),
    );

    // **`ensureVisible`, not `maxScrollExtent`.** The screen's order is content
    // → state band → history, so scrolling to the end lands past the band and
    // in the timeline's tail — which is what the first version of this render
    // captured while its comment said otherwise.
    await tester.ensureVisible(find.byType(CardDetailStateWidget));
    await tester.pumpAndSettle();

    // **Asserted, because the last version of this render was wrong and its
    // dimensions were right.** A PNG of the correct size showing the wrong part
    // of the screen looks exactly like a PNG of the correct size showing the
    // right part; only the frame's own contents distinguish them.
    //
    // It proves **overlap, not containment**, and that is the strongest claim
    // available: at 320dp and scale 2.0 the band is taller than the viewport,
    // so no frame can hold all of it. What this rules out is the failure that
    // happened — a frame scrolled past the band entirely.
    final band = tester.getRect(find.byType(CardDetailStateWidget));
    final viewport = tester.getRect(find.byType(ReviewApp));
    expect(
      band.top < viewport.bottom && band.bottom > viewport.top,
      isTrue,
      reason: 'the state band is not inside the frame this render captures',
    );

    await matchesReviewGolden('goldens/card_detail_320_x2_vi_scrolled.png');
  });

  testWidgets('detail — the whole schedule grid, VI at textScaler 2.0', (
    tester,
  ) async {
    // **A taller surface, because the grid does not fit a phone at this
    // scale.** The 320×568 frame reaches `Reviews` and stops; `Lapses` and the
    // scheduler-specific `Box` row have never appeared in any render. Widening
    // would change the stacking G8 governs, so the height is what gives — the
    // column is still 320dp wide and the text still doubled.
    await pumpReview(
      tester,
      scope(
        loaded(),
        Brightness.light,
        locale: const Locale('vi'),
        textScale: 2,
      ),
      surface: const Size(320, 1400),
    );

    await tester.ensureVisible(find.byType(CardDetailStateWidget));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_detail_state_grid_vi_x2.png');
  });

  testWidgets('detail — the schedule grid at 320dp and 2.0, VI, dark', (
    tester,
  ) async {
    // **G8 stacked has only ever been seen in light.** Dark is where the
    // surface ladder inverts (W6, divergence four), and the stacked grid is the
    // densest thing on the muted panel — so the one frame where that inversion
    // matters most was the one frame nobody had.
    await pumpReview(
      tester,
      scope(
        loaded(),
        Brightness.dark,
        locale: const Locale('vi'),
        textScale: 2,
      ),
      surface: const Size(320, 1400),
    );

    await tester.ensureVisible(find.byType(CardDetailStateWidget));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_detail_state_grid_vi_x2_dark.png');
  });

  testWidgets('detail — ten tags and a flag at 320dp and 2.0, VI', (
    tester,
  ) async {
    // **The hero now holds the flag and every tag in one `Wrap`.** That is a
    // different reflow shape from the tag row it replaced, and ten tags with
    // doubled Vietnamese is the case that actually bends it.
    final repository = FakeCardDetailRepository()
      ..seededDetail = fakeCardDetail(
        front: '사과',
        back: 'quả táo',
        isFlagged: true,
        tagNames: <String>[for (var i = 1; i <= 10; i++) 'nhãn $i'],
        currentBox: 3,
        // The schedule has to agree with the counts: `Reviews 7` above `Not
        // scheduled yet` is a card no answer could have written, and a
        // reference picture that contradicts the rule it illustrates is worse
        // than no picture.
        learnedAt: fakeNow.subtract(const Duration(days: 12)),
        dueAt: fakeNow.add(const Duration(days: 2)),
        lastAnsweredAt: fakeNow,
        answerCount: 7,
        lapseCount: 1,
      )
      ..pages.add(CardHistoryPageModel.empty);
    await pumpReview(
      tester,
      scope(
        repository,
        Brightness.light,
        locale: const Locale('vi'),
        textScale: 2,
      ),
      surface: const Size(320, 1400),
    );

    await matchesReviewGolden('goldens/card_detail_many_tags_vi_x2.png');
  });

  testWidgets('detail — loaded with history at 412dp', (tester) async {
    // The widest phone the geometry tests run at, and the one width that had
    // assertions but no picture.
    await pumpReview(
      tester,
      scope(loaded(), Brightness.light),
      surface: const Size(412, 915),
    );

    await matchesReviewGolden('goldens/card_detail_412_light.png');
  });

  for (final brightness in Brightness.values) {
    testWidgets('detail — an sm2 card, unflagged and with no extras, '
        '${brightness.name}', (tester) async {
      // **Both modes, because one mode is how a mode goes unexamined.** The
      // gallery pairs a screen by `<base>_light` / `<base>_dark`; a face
      // rendered in dark alone is a face the owner reviews in dark alone — and
      // this is the frame where the surface ladder is easiest to read, in
      // either direction.
      await pumpReview(tester, scope(sm2(), brightness));

      await matchesReviewGolden(
        'goldens/card_detail_sm2_${brightness.name}.png',
      );
    });
  }

  testWidgets('detail — a long meaning and a long example, light', (
    tester,
  ) async {
    // The hero has to hold a paragraph without the divider or the optional
    // group losing their place, and the card must still end on the gutter.
    final repository = FakeCardDetailRepository()
      ..seededDetail = fakeCardDetail(
        front: '만나서 반갑습니다',
        back:
            'nice to meet you — a polite greeting used the first time you meet '
            'someone, and long enough here to wrap several times inside the '
            'card that holds it',
        example:
            '안녕하세요, 만나서 반갑습니다. 저는 한국어를 배우고 있어요, '
            'and this line keeps going so the example wraps too',
        isFlagged: true,
      )
      ..pages.add(CardHistoryPageModel.empty);
    await pumpReview(tester, scope(repository, Brightness.light));

    await matchesReviewGolden('goldens/card_detail_long_content_light.png');
  });
}
