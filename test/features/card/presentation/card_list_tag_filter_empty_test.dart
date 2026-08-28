import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

import 'support/fake_card_repository.dart';
import 'support/fake_tag_catalog_repository.dart';
import 'support/tag_catalog_harness.dart';

/// The one empty face UC-18's tag filter draws that neither
/// `card_list_screen_test.dart` nor a golden pinned: a tag selection that
/// matches nothing (M4.14 W7, W6 item 6), and the way back out of it.
///
/// **A separate file, not a group in `card_list_screen_test.dart`.** Reaching
/// this state needs `pumpTagSurface` and a second fake — the catalog — which
/// the rest of that file has no reason to carry.
void main() {
  const tags = <TagCatalogEntry>[
    TagCatalogEntry(id: 't1', name: 'noun', cardCount: 12),
    TagCatalogEntry(id: 't2', name: 'food', cardCount: 3),
  ];

  Future<void> pump(WidgetTester tester, FakeCardRepository cards) async {
    // A fixed phone surface, like every other pump helper in this directory
    // — without it the default test canvas (800×600) puts the Tags pill at
    // an offset a tap on a real device would never reach.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpTagSurface(
      tester,
      home: const CardListScreen(deckId: 'deck-1'),
      catalog: FakeTagCatalogRepository.seeded(tags),
      cards: cards,
    );
  }

  testWidgets(
    'a tag selection that matches nothing offers to clear it (UC-18 A7)',
    (tester) async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      await pump(tester, repository);

      repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
      repository.emitCount(1);
      await tester.pumpAndSettle();

      // The whole pill, not its icon glyph: `MxPillButton`'s tappable area
      // and its icon's reported geometry are not the same rect, and tapping
      // the icon directly missed the button in practice.
      await tester.tap(find.widgetWithText(MxPillButton, 'Tags'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      // Applying re-subscribes the list under the new tag filter — that
      // resubscribe needs its own pump before the stream has a live listener
      // again, or the narrower frame pushed right after is lost. Not
      // `pumpAndSettle`: the fake's stream has not re-emitted yet, so the
      // screen is mid-load and would spin forever.
      await tester.pump();
      repository.emitItems(<dynamic>[].cast());
      await tester.pump();

      expect(find.text('No cards match'), findsOneWidget);
      expect(find.text('Try another filter, or add a card.'), findsOneWidget);
      expect(find.text('Clear tag filter'), findsOneWidget);

      await tester.tap(find.text('Clear tag filter'));
      // Clearing re-subscribes once more, at the empty tag filter — same
      // two-pump ordering as Apply above.
      await tester.pump();
      repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
      await tester.pump();

      expect(
        repository.requestedTagFilters.last.isActive,
        isFalse,
        reason:
            'the clear action must send the empty tag selection, not '
            'just hide the empty face',
      );
    },
  );
}
