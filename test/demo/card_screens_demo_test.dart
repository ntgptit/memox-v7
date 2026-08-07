@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart' show Brightness, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../support/study_render.dart';

/// DEMO renders (not assertions): captures the real card screens with seeded
/// content as PNGs, so the card management UI can be reviewed without the web
/// database. Device-faithful — soft shadows, via `pumpReview` (see
/// `test/support/study_render.dart` for why the shadow flag matters). Tagged
/// `golden`+`review` like the design previews, so CI runs it on the windows
/// golden job and excludes it on Linux. Run with:
///   flutter test --update-goldens --tags golden test/demo/card_screens_demo_test.dart
/// PNGs land in test/demo/goldens/.
///
/// **Latin sample content on purpose.** `flutter_test`'s golden renderer does not
/// exercise the CJK `fontFamilyFallback` the app wires (see
/// `AppTypography.cjkFallbackFamily`), so seeding Korean here would render tofu
/// boxes in the PNG even though a device shows the script. The fallback wiring is
/// proven instead by `test/core/theme/cjk_fallback_test.dart`; these renders use
/// English vocabulary so the layout is faithful.
/// **A card past `isNew` gets a due date, because a real one has.** BR-77 fills
/// `due_at` on the first `scheduled` review, so only a never-reviewed card has
/// none — and the row draws no due badge for those. Leaving every fixture row at
/// `due_at = null` would render a demo with no badge anywhere and quietly drop
/// the mark from review.
CardListItemModel demoItem(
  String id,
  String front,
  String back,
  CardState state, {
  bool flag = false,
}) => FakeCardRepository().listItem(
  id,
  front: front,
  back: back,
  state: state,
  isFlagged: flag,
  dueAt: state == CardState.isNew ? null : _demoDueAt,
);

/// Comfortably behind any clock the render could read, so the badge is `now`
/// rather than a countdown that changes with the calendar — a golden whose
/// content depends on the day it was generated is a golden that fails tomorrow.
final DateTime _demoDueAt = DateTime.utc(2020);

// The deck the card list belongs to (W1): its name titles the screen and its
// ancestors draw the breadcrumb.
const DeckContextModel _demoContext = DeckContextModel(
  deckName: 'English · IELTS',
  ancestors: <DeckBreadcrumbSegment>[
    DeckBreadcrumbSegment(id: 'lang', name: 'Languages'),
    DeckBreadcrumbSegment(id: 'en', name: 'English'),
  ],
);

// The four-state spread behind the progress panel (D5).
const CardStateDistributionModel _demoDistribution = CardStateDistributionModel(
  total: 142,
  isNew: 38,
  beginning: 31,
  reviewing: 29,
  mastered: 44,
);

FakeCardRepository _demoList(
  List<CardListItemModel> items,
) => FakeCardRepository.loaded(items, total: 142)
  ..deckContextToShow = _demoContext
  ..distributionToShow = _demoDistribution
  // Something waiting, so the panel's Start-study action and the pill counts
  // render the state a learner actually opens this screen in.
  //
  // **Due and New are disjoint, so these two add rather than overlap.**
  // `CardListFilter.due` is BR-22's queue minus the never-reviewed cards, so 23
  // is the cards that have come back around and 38 the ones never opened; the
  // Start-study button shows their sum. This pair briefly read 61/38 while the
  // pill still carried the whole queue — the same 61 the button prints now,
  // which is why the number moving here does not move the button.
  ..filterCounts[CardListFilter.due] = 23
  ..filterCounts[CardListFilter.isNew] = 38
  ..filterCounts[CardListFilter.flagged] = 2;

ProviderScope _scope(FakeCardRepository repo, Widget home, Brightness mode) =>
    ProviderScope(
      overrides: [cardRepositoryProvider.overrideWithValue(repo)],
      child: ReviewApp(home: home, brightness: mode),
    );

void main() {
  testWidgets('card list — full row (state, flag, due badge)', (tester) async {
    final repo = _demoList(<CardListItemModel>[
      demoItem('c1', 'ephemeral', 'short-lived / phù du', CardState.isNew),
      demoItem('c2', 'ubiquitous', 'everywhere / khắp nơi', CardState.mastered),
      demoItem(
        'c3',
        'meticulous',
        'very careful / tỉ mỉ',
        CardState.beginning,
        flag: true,
      ),
      demoItem(
        'c4',
        'resilient',
        'quick to recover / kiên cường',
        CardState.reviewing,
      ),
      demoItem('c5', 'candid', 'frank, honest / thẳng thắn', CardState.isNew),
      demoItem(
        'c6',
        'pragmatic',
        'practical / thực dụng',
        CardState.beginning,
        flag: true,
      ),
      demoItem(
        'c7',
        'eloquent',
        'fluent, persuasive / hùng biện',
        CardState.mastered,
      ),
    ]);
    addTearDown(repo.dispose);

    await pumpReview(
      tester,
      _scope(repo, const CardListScreen(deckId: 'demo'), Brightness.light),
    );

    await matchesReviewGolden('goldens/card_list_light.png');
  });

  testWidgets('card list — dark', (tester) async {
    final repo = _demoList(<CardListItemModel>[
      demoItem('c1', 'ephemeral', 'short-lived / phù du', CardState.isNew),
      demoItem(
        'c3',
        'meticulous',
        'very careful / tỉ mỉ',
        CardState.beginning,
        flag: true,
      ),
      demoItem('c2', 'ubiquitous', 'everywhere / khắp nơi', CardState.mastered),
    ]);
    addTearDown(repo.dispose);

    await pumpReview(
      tester,
      _scope(repo, const CardListScreen(deckId: 'demo'), Brightness.dark),
    );

    await matchesReviewGolden('goldens/card_list_dark.png');
  });

  testWidgets('card editor — edit mode (tags, flag, danger zone)', (
    tester,
  ) async {
    final repo = FakeCardRepository();
    addTearDown(repo.dispose);
    repo.cardToGet = repo.card(
      'c3',
      front: 'meticulous',
      back: 'showing great attention to detail / rất tỉ mỉ, cẩn thận',
      // Flagged, so the review render shows the app-bar flag in its active amber.
      isFlagged: true,
    );

    await pumpReview(
      tester,
      _scope(
        repo,
        const CardEditorScreen(deckId: 'demo', cardId: 'c3'),
        Brightness.light,
      ),
    );
    repo.emitTags(
      <dynamic>[
        repo.tag('t1', name: 'noun'),
        repo.tag('t2', name: 'places'),
      ].cast(),
    );
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_editor_edit.png');
  });
}
