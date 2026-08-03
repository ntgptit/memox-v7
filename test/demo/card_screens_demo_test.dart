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
  deckName: 'Korean · TOPIK I',
  ancestors: <DeckBreadcrumbSegment>[
    DeckBreadcrumbSegment(id: 'lang', name: 'Languages'),
    DeckBreadcrumbSegment(id: 'kr', name: 'Korean'),
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
      demoItem('c1', '연구자', 'researcher / nhà nghiên cứu', CardState.isNew),
      demoItem('c2', '공부하다', 'to study / học', CardState.mastered),
      demoItem(
        'c3',
        '도서관',
        'library / thư viện',
        CardState.beginning,
        flag: true,
      ),
      demoItem('c4', '어렵다', 'to be difficult / khó', CardState.reviewing),
      demoItem('c5', '경험', 'experience / kinh nghiệm', CardState.isNew),
      demoItem(
        'c6',
        '준비하다',
        'to prepare / chuẩn bị',
        CardState.beginning,
        flag: true,
      ),
      demoItem('c7', '환경', 'environment / môi trường', CardState.mastered),
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
      demoItem('c1', '연구자', 'researcher / nhà nghiên cứu', CardState.isNew),
      demoItem(
        'c3',
        '도서관',
        'library / thư viện',
        CardState.beginning,
        flag: true,
      ),
      demoItem('c2', '공부하다', 'to study / học', CardState.mastered),
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
      front: '도서관',
      back: 'library, reading room / thư viện',
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
