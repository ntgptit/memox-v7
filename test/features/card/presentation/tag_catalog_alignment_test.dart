import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/tag_catalog_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_filter_bar_widget.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
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
    FakeTagCatalogRepository? repository,
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
      catalog: repository ?? FakeTagCatalogRepository.seeded(tags),
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
  testWidgets('the last row ends a full gutter above the foot (D21)', (
    tester,
  ) async {
    // **Nothing pinned this, and it was 8dp.** Progress, Study Home and the
    // deck level all leave `AppSpacing.lg` under the last row — M99.26 settled
    // that so a list reads as ended rather than cut off — and the catalog was
    // the one screen a user could cross into and see the difference.
    await pumpCatalog(tester);

    // The scroller's own resolved padding, not the gap to the last row: the
    // fixture is short enough that the list does not overflow, so a measured
    // gap here would be the empty viewport rather than the inset. Progress can
    // measure the gap because it seeds fifty decks; this asserts the same
    // number one level closer to the source.
    // A `SingleChildScrollView` since the visual revision put the catalog on
    // one grouped surface - the claim is the same inset on the same scroller,
    // one widget over.
    final padding = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .padding;

    expect(
      (padding! as EdgeInsets).bottom,
      AppSpacing.lg,
      reason: 'D21: every scrolling list ends a full gutter above the foot',
    );
  });

  group('visual revision 2026-08-28 - one grouped surface', () {
    // Where a row's text begins inside the card: leading inset, 32dp well,
    // gap. Restated here from the screen so the two cannot drift silently -
    // if the screen changes its inset, this file says where and by how much.
    const rowTextInset =
        AppSpacing.md + TagCatalogRowWidget.wellSize + AppSpacing.md;

    testWidgets('the search field and the catalog surface share edges', (
      tester,
    ) async {
      // Phone and wide only: below `AppBreakpoints.compact` the shell's own
      // subheader gutter steps to `md` while the catalog holds the card
      // list's fixed `lg` (G1) - a pre-existing shell trade the card list
      // makes identically, not a fact this revision changed.
      for (final size in <Size>[phone, wide]) {
        await pumpCatalog(tester, size: size);
        final search = tester.getRect(find.byType(MxSearchField));
        final surface = tester.getRect(find.byType(MxCard));

        expect(
          search.left,
          moreOrLessEquals(surface.left, epsilon: epsilon),
          reason: 'the field must start where the list it filters starts',
        );
        expect(
          search.right,
          moreOrLessEquals(surface.right, epsilon: epsilon),
          reason: 'and end where it ends',
        );
      }
    });

    testWidgets('every state face stands on the catalog surface edges', (
      tester,
    ) async {
      await pumpCatalog(tester);
      final surface = tester.getRect(find.byType(MxCard));

      // Search-empty: type a term that matches nothing. The face replaces the
      // card at the card's own edges.
      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      await tester.pumpAndSettle();
      final searchEmpty = tester.getRect(find.byType(MxEmptyState));
      expect(
        searchEmpty.left,
        moreOrLessEquals(surface.left, epsilon: epsilon),
      );
      expect(
        searchEmpty.right,
        moreOrLessEquals(surface.right, epsilon: epsilon),
      );
    });

    testWidgets('the error face stands on the same edges', (tester) async {
      final repo = FakeTagCatalogRepository.seeded(tags);
      await pumpCatalog(tester, repository: repo);
      final surface = tester.getRect(find.byType(MxCard));

      repo.emitError(StateError('read failed'));
      await tester.pumpAndSettle();
      final face = tester.getRect(find.byType(MxErrorState));
      expect(face.left, moreOrLessEquals(surface.left, epsilon: epsilon));
      expect(face.right, moreOrLessEquals(surface.right, epsilon: epsilon));
    });

    testWidgets('separators live inside the text column, one per boundary', (
      tester,
    ) async {
      await pumpCatalog(tester);
      final surface = tester.getRect(find.byType(MxCard));
      final dividers = find.byType(Divider);

      expect(
        dividers,
        findsNWidgets(tags.length - 1),
        reason: 'a separator marks a boundary, so rows minus one',
      );
      for (var i = 0; i < tags.length - 1; i++) {
        // The widget spans the card; the *painted* line is inset by the
        // divider's own indent properties, which `getRect` cannot see - so
        // the box is measured and the inset is read off the widget, the same
        // split the D21 claim makes for a scroller's padding.
        final rect = tester.getRect(dividers.at(i));
        expect(rect.left, moreOrLessEquals(surface.left, epsilon: epsilon));
        expect(rect.right, moreOrLessEquals(surface.right, epsilon: epsilon));

        final divider = tester.widget<Divider>(dividers.at(i));
        expect(
          divider.indent,
          rowTextInset,
          reason:
              'the line starts where the text column starts, not at the '
              'card edge - a full-bleed line slices the card',
        );
        expect(divider.endIndent, AppSpacing.md);
      }

      // And the inset is not just a number two files agree on: the name's
      // laid-out left edge sits exactly there, so a well that grew would
      // drag this assertion red instead of letting the line drift off the
      // text column.
      final name = tester.getRect(find.text('food'));
      expect(
        name.left,
        moreOrLessEquals(surface.left + rowTextInset, epsilon: epsilon),
        reason: 'the separator indent and the text column are one fact',
      );
    });

    testWidgets('an error arriving after data takes the search with it '
        '(W3 face 5)', (tester) async {
      final repo = FakeTagCatalogRepository.seeded(tags);
      await pumpCatalog(tester, repository: repo);
      expect(find.byType(MxSearchField), findsOneWidget);

      repo.emitError(StateError('read failed'));
      await tester.pumpAndSettle();

      expect(
        find.byType(MxSearchField),
        findsNothing,
        reason:
            'the error face has nothing to narrow - Riverpod keeping the '
            'previous value must not keep the chrome',
      );
    });

    testWidgets('every row wears the same neutral well', (tester) async {
      await pumpCatalog(tester);

      expect(
        find.byIcon(Icons.sell_outlined),
        findsNWidgets(tags.length),
        reason:
            'one glyph per row, all identical - a well that varied would '
            'invent a hierarchy BR-230 does not have',
      );
    });

    testWidgets('a row reads as name then count, each spoken once', (
      tester,
    ) async {
      // The row left `MxListTile` (whose ListTile grouped title+subtitle into
      // one semantics node) for two sibling `Text`s. The claim that survives
      // the move: traversal order is name first, count second, and neither
      // string appears on more than one node - "count khong bi doc lap".
      final handle = tester.ensureSemantics();
      await pumpCatalog(tester);

      final name = tester.getSemantics(find.text('food'));
      final count = tester.getSemantics(find.text('1 card'));
      expect(name.label, 'food');
      expect(count.label, '1 card');
      // Once each: one node per string across the whole tree.
      expect(find.bySemanticsLabel('food'), findsOneWidget);
      expect(find.bySemanticsLabel('1 card'), findsOneWidget);
      // Order: the name's node comes before its count in traversal, which is
      // vertical order here - the count sits under the name (G3).
      expect(
        tester.getRect(find.text('food')).top,
        lessThan(tester.getRect(find.text('1 card')).top),
      );
      handle.dispose();
    });

    testWidgets('320dp at 2.0x: rows wrap inside the surface, nothing '
        'overflows', (tester) async {
      await pumpCatalog(tester, size: narrow, textScale: 2);

      final surface = tester.getRect(find.byType(MxCard));
      for (var i = 0; i < tags.length; i++) {
        final row = tester.getRect(find.byType(TagCatalogRowWidget).at(i));
        expect(row.left, greaterThanOrEqualTo(surface.left - epsilon));
        expect(row.right, lessThanOrEqualTo(surface.right + epsilon));
      }
      // An overflow throws through the test binding; reaching here with no
      // exception is the G9 claim at this size.
      expect(tester.takeException(), isNull);
    });
  });
}
