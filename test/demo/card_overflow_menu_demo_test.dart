@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart' show Brightness, Icons, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../support/study_render.dart';

/// DEMO render: the card list's overflow menu, open, in both modes.
///
/// **It had no picture, and that is why a bug lived in it.** Four
/// `PopupMenuButton` call sites exist — this one, the sort control, the
/// selection bar and the tag catalog row — and not one golden opened any of
/// them. The menu was drawn on `surface` at `elevation: 0`, the same paper as
/// the card it opens over, which measures a lift of **0.00 L\***. Every
/// assertion about it passed: the paper was a real rung, the label cleared its
/// contrast floor, the corner matched the scale. Nothing compared the menu to
/// what was *behind* it, and nothing rendered it for a person to look at.
///
/// So this file exists to make that visible rather than only measured. Both
/// modes, because the depth is built differently in each — light gets almost
/// nothing from the paper and carries it with a shadow, dark gets 13.73 L\* from
/// the paper and paints no shadow at all (AD-14).
///
/// Device-faithful via `pumpReview`, so the light shadow is actually rasterised;
/// rendering this one flat would remove exactly the thing it is here to show.
// **A local fixture rather than the one next door, and deliberately small.**
// `card_screens_demo_test.dart` owns a richer set — a full distribution, the
// filter counts, a seven-row list — and reaching for it would mean either
// growing a file already at the guard's 400-line cap or extracting a shared
// fixtures library for two renders. What this file photographs is a menu on
// top of a list; the list only has to be a real one underneath it.
const DeckContextModel _demoContext = DeckContextModel(
  deckName: 'Korean · TOPIK I',
  ancestors: <DeckBreadcrumbSegment>[
    DeckBreadcrumbSegment(id: 'lang', name: 'Languages'),
    DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
  ],
);

FakeCardRepository _demoList(List<CardListItemModel> items) =>
    FakeCardRepository.loaded(items, total: items.length)
      ..deckContextToShow = _demoContext
      ..filterCounts[CardListFilter.due] = 23
      ..filterCounts[CardListFilter.isNew] = 38;

ProviderScope _scope(FakeCardRepository repo, Widget home, Brightness mode) =>
    ProviderScope(
      overrides: [cardRepositoryProvider.overrideWithValue(repo)],
      child: ReviewApp(home: home, brightness: mode),
    );

/// Comfortably behind any clock the render could read, for the reason
/// `card_screens_demo_test.dart` gives: a golden whose content depends on the
/// day it was generated is a golden that fails tomorrow.
final DateTime _demoDueAt = DateTime.utc(2020);

CardListItemModel _item(
  String id,
  String front,
  String back,
  CardState state,
) => FakeCardRepository().listItem(
  id,
  front: front,
  back: back,
  state: state,
  dueAt: state == CardState.isNew ? null : _demoDueAt,
);

Future<void> _openMenu(WidgetTester tester, Brightness mode) async {
  final repo = _demoList(<CardListItemModel>[
    _item('c1', '사과', 'apple / quả táo', CardState.isNew),
    _item('c2', '바다', 'sea / biển', CardState.mastered),
    _item('c3', '감사합니다', 'thank you / cảm ơn', CardState.beginning),
  ]);
  addTearDown(repo.dispose);

  await pumpReview(
    tester,
    _scope(repo, const CardListScreen(deckId: 'demo'), mode),
  );

  // The app bar's, which is the last `more_vert` in the tree — the rows carry
  // their own. `deck_overlays_demo_test.dart` records what picking the wrong
  // one costs: a plausible PNG filed under a name for a different menu.
  await tester.tap(find.byIcon(Icons.more_vert).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('overflow menu — open over the list, light', (tester) async {
    await _openMenu(tester, Brightness.light);

    await matchesReviewGolden('goldens/card_overflow_menu_light.png');
  });

  testWidgets('overflow menu — open over the list, dark', (tester) async {
    await _openMenu(tester, Brightness.dark);

    await matchesReviewGolden('goldens/card_overflow_menu_dark.png');
  });
}
