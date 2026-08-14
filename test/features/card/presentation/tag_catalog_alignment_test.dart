import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/tag_catalog_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_filter_bar_widget.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/fake_card_repository.dart';
import 'support/fake_tag_catalog_repository.dart';
import 'support/tag_catalog_harness.dart';

/// **The tag surfaces' geometry contract (wireframe M4.14 G1…G9), measured.**
///
/// Written because none of the other gates can see a laid-out rectangle:
/// `flutter analyze` and the guard read source text, the visual audit reads
/// colour, and a golden only compares a screen with yesterday's copy of itself
/// — so an edge that is wrong but *stable* passes forever. G1 is the one that
/// motivated the file: a management screen whose gutter differs from the screen
/// it manages reads as two apps, and nothing else would have caught it.
void main() {
  const tags = <TagCatalogEntry>[
    TagCatalogEntry(id: 't1', name: 'động từ', cardCount: 12),
    TagCatalogEntry(id: 't2', name: 'food', cardCount: 1),
    TagCatalogEntry(
      id: 't3',
      name:
          'a very long tag name that has to wrap or '
          'be truncated somewhere',
      cardCount: 0,
    ),
  ];

  /// A hairline, not a design allowance: antialiasing may land a fraction
  /// either way.
  const double epsilon = 0.5;

  /// The narrowest supported phone at the largest supported scale, and two
  /// ordinary ones (M4.14 R).
  const narrow = Size(320, 640);
  const phone = Size(390, 844);
  const wide = Size(412, 915);

  void sizeTo(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpCatalog(
    WidgetTester tester, {
    Size size = phone,
    double textScale = 1,
  }) async {
    sizeTo(tester, size);
    await pumpTagSurface(
      tester,
      // `copyWith` through a Builder, never a fresh `MediaQueryData`: a new one
      // carries a zero size, which puts the screen below the compact
      // breakpoint and silently changes the gutter this file is measuring.
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: const TagCatalogScreen(),
        ),
      ),
      catalog: FakeTagCatalogRepository.seeded(tags),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpCardList(
    WidgetTester tester, {
    Size size = phone,
    double textScale = 1,
  }) async {
    sizeTo(tester, size);
    await pumpTagSurface(
      tester,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: const CardListScreen(deckId: 'deck-1'),
        ),
      ),
      catalog: FakeTagCatalogRepository.seeded(tags),
      cards: FakeCardRepository.loaded(
        <dynamic>[
          FakeCardRepository().listItem('c1', front: 'a', back: 'b'),
        ].cast(),
        total: 1,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('G1/G2 — the catalog shares the card list edge', () {
    for (final size in <Size>[narrow, phone, wide]) {
      testWidgets('at ${size.width.toInt()}dp', (tester) async {
        await pumpCardList(tester, size: size);
        final listField = tester.getRect(find.byType(MxSearchField));

        await pumpCatalog(tester, size: size);
        final catalogField = tester.getRect(find.byType(MxSearchField));

        expect(
          catalogField.left,
          moreOrLessEquals(listField.left, epsilon: epsilon),
          reason: 'G2 — the two search fields share a left edge',
        );
        expect(
          catalogField.right,
          moreOrLessEquals(listField.right, epsilon: epsilon),
          reason: 'G2 — and a right edge',
        );
      });
    }
  });

  testWidgets('G3 — a row s name and its count share a left edge', (
    tester,
  ) async {
    await pumpCatalog(tester);

    final name = tester.getRect(find.text('động từ'));
    final count = tester.getRect(find.text('12 cards'));

    expect(
      count.left,
      moreOrLessEquals(name.left, epsilon: epsilon),
      reason:
          'The count is a subtitle under the name; a right-aligned number '
          'across from a name of any length reads as an empty column.',
    );
  });

  testWidgets('G4 — the row menu is a 48dp target inside the gutter', (
    tester,
  ) async {
    await pumpCatalog(tester);

    final row = tester.getRect(find.byType(TagCatalogRowWidget).first);
    final menu = tester.getRect(
      find.descendant(
        of: find.byType(TagCatalogRowWidget).first,
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    final button = tester.getRect(
      find
          .ancestor(
            of: find.byIcon(Icons.more_vert).first,
            matching: find.byType(InkWell),
          )
          .first,
    );

    expect(button.width, greaterThanOrEqualTo(48 - epsilon));
    expect(button.height, greaterThanOrEqualTo(48 - epsilon));
    expect(menu.right, lessThanOrEqualTo(row.right + epsilon));
  });

  testWidgets('G5 — every row shares the same left and right edge', (
    tester,
  ) async {
    await pumpCatalog(tester);

    final rects = tester
        .widgetList<TagCatalogRowWidget>(find.byType(TagCatalogRowWidget))
        .toList();
    expect(rects, hasLength(3));
    final first = tester.getRect(find.byType(TagCatalogRowWidget).first);
    for (var i = 1; i < rects.length; i++) {
      final rect = tester.getRect(find.byType(TagCatalogRowWidget).at(i));
      expect(rect.left, moreOrLessEquals(first.left, epsilon: epsilon));
      expect(rect.right, moreOrLessEquals(first.right, epsilon: epsilon));
    }
  });

  group('G6/G7 — the filter overlay is one column with full-row targets', () {
    testWidgets('rows and the action row share both edges', (tester) async {
      await pumpCardList(tester);
      await tester.tap(find.byIcon(Icons.sell_outlined).first);
      await tester.pumpAndSettle();

      final row = tester.getRect(find.byType(CheckboxListTile).first);
      final actions = tester.getRect(find.text('Clear'));

      expect(actions.left, greaterThanOrEqualTo(row.left - epsilon));
      expect(actions.right, lessThanOrEqualTo(row.right + epsilon));
    });

    testWidgets('the whole row toggles, not just the box', (tester) async {
      await pumpCardList(tester);
      await tester.tap(find.byIcon(Icons.sell_outlined).first);
      await tester.pumpAndSettle();

      final row = tester.getRect(find.byType(CheckboxListTile).first);
      expect(row.height, greaterThanOrEqualTo(48 - epsilon));

      // Tap the far end of the row, well away from the checkbox.
      await tester.tapAt(Offset(row.right - 8, row.center.dy));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        isTrue,
      );
    });
  });

  testWidgets('G9 — nothing overflows at 320dp with textScale 2.0', (
    tester,
  ) async {
    await pumpCatalog(tester, size: narrow, textScale: 2);

    // A RenderFlex overflow throws into the test binding, so reaching here
    // with no exception is the assertion; the edges are checked as well so a
    // silently clipped row cannot pass.
    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byType(TagCatalogRowWidget).first);
    expect(row.left, greaterThanOrEqualTo(-epsilon));
    expect(row.right, lessThanOrEqualTo(narrow.width + epsilon));
  });

  group('G10 — the Tags pill is fully inside the filter bar', () {
    for (final size in <Size>[narrow, phone, wide]) {
      testWidgets('at ${size.width.toInt()}dp', (tester) async {
        await pumpCardList(tester, size: size);

        final bar = tester.getRect(find.byType(CardFilterBarWidget));
        final pill = tester.getRect(
          find.ancestor(
            of: find.byIcon(Icons.sell_outlined),
            matching: find.byType(MxPillButton),
          ),
        );

        // It was inside the horizontal scroller and 66% of it — including
        // every pixel of the word — sat past this edge at every width.
        expect(
          pill.right,
          lessThanOrEqualTo(bar.right + epsilon),
          reason: 'the only entry to multi-tag filtering must be visible',
        );
        expect(pill.left, greaterThanOrEqualTo(bar.left - epsilon));
        expect(pill.width, greaterThan(48), reason: 'not a sliver of a pill');

        // **And a real gap before it.** The first attempt put the gap in the
        // scroller's `padding`, which pads the *content*: it is part of the
        // scrollable extent, so on a bar that overflows at every width it was
        // never drawn. Measured 0.33dp — the clipped pill and the pinned one
        // read as a single broken control (W1).
        final scroller = tester.getRect(
          find.byType(SingleChildScrollView).first,
        );
        expect(
          pill.left - scroller.right,
          moreOrLessEquals(AppSpacing.sm, epsilon: epsilon),
          reason: 'W1 asks for AppSpacing.sm between the two',
        );
      });
    }
  });

  group('G9 — the overlay action rows wrap instead of overflowing', () {
    testWidgets('the filter sheet at 320dp × 2.0', (tester) async {
      await pumpCardList(tester, size: narrow, textScale: 2);
      await tester.tap(find.byIcon(Icons.sell_outlined).first);
      await tester.pumpAndSettle();

      // A RenderFlex overflow throws into the binding, so an exception here is
      // the failure; the edges are checked too, so a clipped row cannot pass.
      expect(tester.takeException(), isNull);
      final clear = tester.getRect(find.text('Clear'));
      expect(clear.left, greaterThanOrEqualTo(-epsilon));
      expect(clear.right, lessThanOrEqualTo(narrow.width + epsilon));
    });

    testWidgets('the rename sheet at 320dp × 2.0', (tester) async {
      await pumpCatalog(tester, size: narrow, textScale: 2);
      await tester.tap(find.byTooltip('Actions for tag food'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final cancel = tester.getRect(find.text('Cancel'));
      expect(cancel.left, greaterThanOrEqualTo(-epsilon));
      expect(cancel.right, lessThanOrEqualTo(narrow.width + epsilon));
    });
  });

  group('R — focus returns to the row an overlay was opened from', () {
    testWidgets('after the rename sheet closes', (tester) async {
      await pumpCatalog(tester);
      final before = FocusManager.instance.primaryFocus;

      await tester.tap(find.byTooltip('Actions for tag food'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // The sheet autofocuses its field; closing it must not strand focus on a
      // disposed node or leave it inside the popped route.
      final after = FocusManager.instance.primaryFocus;
      expect(after, isNotNull);
      expect(after?.context?.mounted ?? false, isTrue);
      expect(before?.context?.mounted ?? true, isTrue);
    });
  });
}
