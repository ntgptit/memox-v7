@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_not_found_failure.dart';
import 'package:memox/features/card/di/card_detail_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/card/domain/models/card_history_event_model.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_detail_state_widget.dart';

import '../features/card/presentation/support/fake_card_detail_repository.dart';
import '../support/study_render.dart';

/// DEMO renders (not assertions) of Card Detail (UC-19, wireframe M4.15):
/// device-faithful PNGs for design review, driven through the real screen with
/// its one repository faked. Run with:
///   flutter test --update-goldens --tags golden test/demo/card_detail_demo_test.dart
///
/// **This screen shipped without any**, which is why three visual changes could
/// land in one afternoon — a rebuilt error band, a halved bottom inset, a new
/// not-found glyph — and the whole suite stayed green. The other screens in the
/// card feature have demo renders; this one was the exception, which is what
/// made D27's decision uncheckable.
///
/// The faces chosen are the ones a reviewer cannot judge from prose: the
/// reading surface D27 deliberately leaves un-carded, the timeline's failed
/// page now that it wears the app's shared band, and the deleted-card face
/// whose glyph used to say "no search results". The first version of this file
/// named all three and rendered only the first — the two this round changed
/// were exactly the two it left out.
void main() {
  FakeCardDetailRepository loaded({bool withHistory = true}) {
    final repository = FakeCardDetailRepository()
      ..seededDetail = fakeCardDetail(
        front: '사과',
        back: 'quả táo',
        example: '사과를 먹어요',
        hint: 'a fruit',
        pronunciation: 'sa-gwa',
        tagNames: <String>['noun', 'food'],
        isFlagged: true,
      );
    repository.pages.add(
      withHistory
          ? CardHistoryPageModel(
              events: <CardHistoryEventModel>[
                fakeHistoryEvent(id: 'e1'),
                fakeHistoryEvent(id: 'e2', action: StudyAction.forgotten),
                fakeHistoryEvent(id: 'e3', kind: StudyAnswerKind.learning),
              ],
              hasMore: false,
              nextCursor: null,
            )
          : CardHistoryPageModel.empty,
    );

    return repository;
  }

  Widget scope(
    FakeCardDetailRepository repository,
    Brightness brightness, {
    Locale? locale,
    double textScale = 1,
  }) => ProviderScope(
    overrides: [cardDetailRepositoryProvider.overrideWithValue(repository)],
    child: ReviewApp(
      home: const CardDetailScreen(deckId: 'deck-1', cardId: 'card-1'),
      brightness: brightness,
      locale: locale,
      textScale: textScale,
    ),
  );

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

  testWidgets('detail — a history page that failed to load, light', (
    tester,
  ) async {
    // The band D24/D25's grammar was just applied to. Rendered because the
    // whole point of that grammar is that it is checked by eye across screens,
    // and a structural diff against the sibling widgets is not that check.
    final repository = loaded()
      ..nextHistoryFailure = const DatabaseFailure(message: 'demo');
    await pumpReview(tester, scope(repository, Brightness.light));

    await matchesReviewGolden('goldens/card_detail_page_error_light.png');
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

  testWidgets('detail — a card with no history yet, light', (tester) async {
    await pumpReview(
      tester,
      scope(loaded(withHistory: false), Brightness.light),
    );

    await matchesReviewGolden('goldens/card_detail_no_history_light.png');
  });
}
