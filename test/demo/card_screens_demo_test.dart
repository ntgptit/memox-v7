@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart' show Brightness, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../support/review_render.dart';

/// DEMO renders (not assertions): captures the real card screens with seeded
/// content as PNGs, so the card management UI can be reviewed without the web
/// database. Device-faithful — soft shadows, via `pumpReview` (see
/// `test/support/review_render.dart` for why the shadow flag matters). Tagged
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
);

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

FakeCardRepository _demoList(List<CardListItemModel> items) =>
    FakeCardRepository.loaded(items, total: 142)
      ..deckContextToShow = _demoContext
      ..distributionToShow = _demoDistribution;

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

    await matchesReviewGolden(
      find.byType(CardListScreen),
      'goldens/card_list_light.png',
    );
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

    await matchesReviewGolden(
      find.byType(CardListScreen),
      'goldens/card_list_dark.png',
    );
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

    await matchesReviewGolden(
      find.byType(CardEditorScreen),
      'goldens/card_editor_edit.png',
    );
  });
}
