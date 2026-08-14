import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/domain/models/tag_filter_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';

import 'support/fake_card_repository.dart';
import 'support/fake_tag_catalog_repository.dart';
import 'support/tag_catalog_harness.dart';

/// The card list's multi-tag filter (UC-12, BR-183, BR-184, M4.14 W6, W7).
void main() {
  const tags = <TagCatalogEntry>[
    TagCatalogEntry(id: 't1', name: 'noun', cardCount: 12),
    TagCatalogEntry(id: 't2', name: 'verb', cardCount: 4),
  ];

  Future<({FakeCardRepository cards, FakeTagCatalogRepository catalog})> pump(
    WidgetTester tester, {
    List<TagCatalogEntry> catalogEntries = tags,
  }) async {
    final cards = FakeCardRepository.loaded(
      <dynamic>[
        FakeCardRepository().listItem('c1', front: 'a', back: 'b'),
      ].cast(),
      total: 1,
    );
    final catalog = FakeTagCatalogRepository.seeded(catalogEntries);
    await pumpTagSurface(
      tester,
      home: const CardListScreen(deckId: 'deck-1'),
      catalog: catalog,
      cards: cards,
    );
    await tester.pumpAndSettle();

    return (cards: cards, catalog: catalog);
  }

  /// The sheet's primary action, whichever of its two labels it is wearing.
  ///
  /// A predicate rather than `find.text`: the label is `Show N cards` once the
  /// draft count lands and the bare `Apply` before it (M4.14 T6), and matching
  /// on the word "Show" alone would also hit the screen's own "Showing 1 of 1"
  /// and the sheet's "Shows cards with any…" subtitle.
  final applyAction = find.byWidgetPredicate(
    (Widget widget) =>
        widget is Text &&
        (widget.data == 'Apply' || (widget.data?.startsWith('Show ') ?? false)),
  );

  /// Opens the filter sheet from the pill.
  ///
  /// By its glyph, not its label: once a filter is applied the label carries
  /// the count (`Tags · 1`), so a text finder stops matching exactly when a
  /// test wants to reopen the sheet it just used.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.sell_outlined).first);
    await tester.pumpAndSettle();
  }

  testWidgets('the pill sits on the filter bar and opens the sheet', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Tags'), findsOneWidget);
    await openSheet(tester);

    expect(find.text('Filter by tags'), findsOneWidget);
    // BR-183's semantics, in words — the one place a user learns that a second
    // tag widens rather than narrows.
    expect(
      find.text('Shows cards with any of the selected tags.'),
      findsOneWidget,
    );
  });

  testWidgets('every tag is a row with its count, unchecked at rest', (
    tester,
  ) async {
    await pump(tester);
    await openSheet(tester);

    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('12 cards'), findsOneWidget);
    for (final tile in tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    )) {
      expect(tile.value, isFalse);
    }
  });

  testWidgets('nothing is applied until Apply — the list is not re-read on '
      'a tick (M4.14 T5)', (tester) async {
    final harness = await pump(tester);
    await openSheet(tester);
    final before = harness.cards.requestedTagFilters.length;

    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();

    expect(
      harness.cards.requestedTagFilters.length,
      before,
      reason: 'the list read must not follow the draft',
    );
  });

  testWidgets('Apply narrows both the list and the count with the same '
      'selection (BR-183)', (tester) async {
    final harness = await pump(tester);
    await openSheet(tester);

    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();
    await tester.tap(applyAction);
    await tester.pumpAndSettle();

    final applied = harness.cards.requestedTagFilters.last;
    expect(applied.tagIds, <String>{'t1'});
    expect(
      harness.cards.requestedCountTagFilters.last,
      applied,
      reason: 'the count must use the list predicate, or the header lies',
    );
  });

  testWidgets('two ticks apply as one selection of two (BR-183)', (
    tester,
  ) async {
    final harness = await pump(tester);
    await openSheet(tester);

    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('verb'));
    await tester.pumpAndSettle();
    await tester.tap(applyAction);
    await tester.pumpAndSettle();

    expect(harness.cards.requestedTagFilters.last.tagIds, <String>{'t1', 't2'});
  });

  testWidgets('Clear empties the draft and is disabled when it already is', (
    tester,
  ) async {
    await pump(tester);
    await openSheet(tester);

    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    for (final tile in tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    )) {
      expect(tile.value, isFalse);
    }
  });

  testWidgets('the pill reports how many tags are applied (M4.14 T4)', (
    tester,
  ) async {
    await pump(tester);
    await openSheet(tester);

    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();
    await tester.tap(applyAction);
    await tester.pumpAndSettle();

    expect(find.text('Tags · 1'), findsOneWidget);
  });

  testWidgets('closing without Apply keeps the applied selection (UC-12 A5)', (
    tester,
  ) async {
    final harness = await pump(tester);
    await openSheet(tester);
    final before = harness.cards.requestedTagFilters.last;

    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();
    // Tap the barrier: the sheet's own dismiss, no Apply.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(harness.cards.requestedTagFilters.last, before);
    expect(find.text('Tags'), findsOneWidget, reason: 'still unselected');
  });

  testWidgets('an empty catalog offers the empty state and no actions', (
    tester,
  ) async {
    await pump(tester, catalogEntries: const <TagCatalogEntry>[]);
    await openSheet(tester);

    expect(find.text('No tags yet'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
    expect(applyAction, findsNothing);
  });

  testWidgets('applying drops a tag that no longer exists (BR-186, BR-187)', (
    tester,
  ) async {
    final harness = await pump(tester);
    await openSheet(tester);
    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();
    await tester.tap(applyAction);
    await tester.pumpAndSettle();
    expect(harness.cards.requestedTagFilters.last.tagIds, <String>{'t1'});

    // `noun` is merged away elsewhere. Re-applying must not carry the id that
    // now matches nothing — the list would stay empty with no row to untick.
    harness.catalog.emitCatalog(const <TagCatalogEntry>[
      TagCatalogEntry(id: 't2', name: 'verb', cardCount: 4),
    ]);
    await tester.pumpAndSettle();
    await openSheet(tester);
    await tester.tap(applyAction);
    await tester.pumpAndSettle();

    expect(harness.cards.requestedTagFilters.last, TagFilter.none);
  });

  testWidgets('the state filter and the tag filter compose (BR-183)', (
    tester,
  ) async {
    final harness = await pump(tester);
    await tester.tap(find.text('Flagged'));
    await tester.pumpAndSettle();
    await openSheet(tester);
    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();
    await tester.tap(applyAction);
    await tester.pumpAndSettle();

    expect(harness.cards.requestedFilters.last, CardListFilter.flagged);
    expect(harness.cards.requestedTagFilters.last.tagIds, <String>{'t1'});
  });

  testWidgets('a tag filter that matches nothing shows the no-match face with '
      'a way out, never "add your first card" (M4.14 W7, UC-12 A7)', (
    tester,
  ) async {
    final cards = FakeCardRepository();
    addTearDown(cards.dispose);
    final catalog = FakeTagCatalogRepository.seeded(tags);
    final harness = (cards: cards, catalog: catalog);
    await pumpTagSurface(
      tester,
      home: const CardListScreen(deckId: 'deck-1'),
      catalog: catalog,
      cards: cards,
    );
    // A deck that *has* cards, so the filter bar is drawn at all.
    cards
      ..emitItems(<CardListItemModel>[
        FakeCardRepository().listItem('c1', front: 'a', back: 'b'),
      ])
      ..emitCount(214);
    await tester.pumpAndSettle();

    await openSheet(tester);
    await tester.tap(find.text('noun'));
    await tester.pumpAndSettle();
    await tester.tap(applyAction);
    // `pump`, not `pumpAndSettle`: applying re-subscribes the list read, so
    // until the next emission the screen is a spinner — and a spinner never
    // settles.
    await tester.pump();
    cards
      ..emitItems(<CardListItemModel>[])
      ..emitCount(0);
    await tester.pump(const Duration(seconds: 1));

    // The deck holds 214 cards; offering to add the first one would be a lie
    // the user acts on.
    expect(find.text('No cards yet'), findsNothing);
    expect(find.text('No cards match'), findsOneWidget);

    // UC-12 A7: the way out is on the face itself. Without it the only exit is
    // to reopen the sheet and press Clear inside it — two taps to undo one.
    expect(find.text('Clear tag filter'), findsOneWidget);
    // Not the sheet's bare `Clear`: this face has no visible selection, so the
    // label has to name what it clears.
    expect(find.text('Clear'), findsNothing);
    await tester.tap(find.text('Clear tag filter'));
    await tester.pump();
    cards
      ..emitItems(<CardListItemModel>[
        FakeCardRepository().listItem('c1', front: 'a', back: 'b'),
      ])
      ..emitCount(214);
    await tester.pump(const Duration(seconds: 1));

    expect(harness.cards.requestedTagFilters.last, TagFilter.none);
    expect(find.text('No cards match'), findsNothing);
  });
}
