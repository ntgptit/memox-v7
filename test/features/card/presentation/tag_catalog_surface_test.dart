import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/presentation/widgets/items/tag_catalog_row_widget.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/fake_tag_catalog_repository.dart';
import 'support/tag_catalog_harness.dart';

/// **The tag catalog as one grouped surface**, split out of
/// `tag_catalog_alignment_test.dart` when that file crossed the guard's
/// 400-line ceiling.
///
/// The G-numbered wireframe assertions stayed there; this file holds the
/// surface revision — the search field and the catalog sharing edges, every
/// state face standing on those edges, and the row separators ending on the
/// row content rather than on a number (SC-C1-10, SC-C1-11).
void main() {
  group('visual revision 2026-08-28 - one grouped surface', () {
    // Where a row's text begins inside the card: leading inset, 32dp well,
    // gap. Restated here from the screen so the two cannot drift silently -
    // if the screen changes its inset, this file says where and by how much.
    const rowTextInset =
        AppSpacing.md + TagCatalogRowWidget.wellSize + AppSpacing.md;

    testWidgets('the search field and the catalog surface share edges', (
      tester,
    ) async {
      // Narrow included since the surface took its gutter from
      // `mxScreenGutter`: below `AppBreakpoints.compact` the shell's subheader
      // steps to `md`, and the catalog now steps with it. This is the group
      // that guards the coupling - the G1/G2 group above compares two search
      // fields, both of which come from the shell and agree either way.
      for (final size in <Size>[kTagNarrow, kTagPhone, kTagWide]) {
        await pumpTagCatalog(tester, size: size);
        final search = tester.getRect(find.byType(MxSearchField));
        final surface = tester.getRect(find.byType(MxCard));

        expect(
          search.left,
          moreOrLessEquals(surface.left, epsilon: kTagEpsilon),
          reason: 'the field must start where the list it filters starts',
        );
        expect(
          search.right,
          moreOrLessEquals(surface.right, epsilon: kTagEpsilon),
          reason: 'and end where it ends',
        );
      }
    });

    testWidgets('every state face stands on the catalog surface edges', (
      tester,
    ) async {
      await pumpTagCatalog(tester);
      final surface = tester.getRect(find.byType(MxCard));

      // Search-empty: type a term that matches nothing. The face replaces the
      // card at the card's own edges.
      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      await tester.pumpAndSettle();
      final searchEmpty = tester.getRect(find.byType(MxEmptyState));
      expect(
        searchEmpty.left,
        moreOrLessEquals(surface.left, epsilon: kTagEpsilon),
      );
      expect(
        searchEmpty.right,
        moreOrLessEquals(surface.right, epsilon: kTagEpsilon),
      );
    });

    testWidgets('the error face stands on the same edges', (tester) async {
      final repo = FakeTagCatalogRepository.seeded(kTagFixtures);
      await pumpTagCatalog(tester, repository: repo);
      final surface = tester.getRect(find.byType(MxCard));

      repo.emitError(StateError('read failed'));
      await tester.pumpAndSettle();
      final face = tester.getRect(find.byType(MxErrorState));
      expect(face.left, moreOrLessEquals(surface.left, epsilon: kTagEpsilon));
      expect(face.right, moreOrLessEquals(surface.right, epsilon: kTagEpsilon));
    });

    testWidgets('separators live inside the text column, one per boundary', (
      tester,
    ) async {
      await pumpTagCatalog(tester);
      final surface = tester.getRect(find.byType(MxCard));
      final dividers = find.byType(Divider);

      // The row's own content edge: the menu button's 48dp box, which the row
      // pads by `xs` from the card. The trailing end of every separator is
      // measured against this rather than against a literal, which is how it
      // came to end 8dp short of the content and 4dp past the glyph.
      final menuButton = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(Icons.more_vert).first,
              matching: find.byType(InkWell),
            )
            .first,
      );

      expect(
        dividers,
        findsNWidgets(kTagFixtures.length - 1),
        reason: 'a separator marks a boundary, so rows minus one',
      );
      for (var i = 0; i < kTagFixtures.length - 1; i++) {
        // The widget spans the card; the *painted* line is inset by the
        // divider's own indent properties, which `getRect` cannot see - so
        // the box is measured and the inset is read off the widget, the same
        // split the D21 claim makes for a scroller's padding.
        final rect = tester.getRect(dividers.at(i));
        expect(rect.left, moreOrLessEquals(surface.left, epsilon: kTagEpsilon));
        expect(
          rect.right,
          moreOrLessEquals(surface.right, epsilon: kTagEpsilon),
        );

        final divider = tester.widget<Divider>(dividers.at(i));
        expect(
          divider.indent,
          rowTextInset,
          reason:
              'the line starts where the text column starts, not at the '
              'card edge - a full-bleed line slices the card',
        );
        expect(
          surface.right - divider.endIndent!,
          moreOrLessEquals(menuButton.right, epsilon: kTagEpsilon),
          reason:
              'the line must stop on the row content it separates, not on a '
              'number that matches neither the glyph nor the card edge',
        );
      }

      // And the inset is not just a number two files agree on: the name's
      // laid-out left edge sits exactly there, so a well that grew would
      // drag this assertion red instead of letting the line drift off the
      // text column.
      final name = tester.getRect(find.text('food'));
      expect(
        name.left,
        moreOrLessEquals(surface.left + rowTextInset, epsilon: kTagEpsilon),
        reason: 'the separator indent and the text column are one fact',
      );
    });

    testWidgets('an error arriving after data takes the search with it '
        '(W3 face 5)', (tester) async {
      final repo = FakeTagCatalogRepository.seeded(kTagFixtures);
      await pumpTagCatalog(tester, repository: repo);
      expect(find.byType(MxSearchField), findsOneWidget);

      repo.emitError(StateError('read failed'));
      await tester.pumpAndSettle();

      expect(
        find.byType(MxSearchField),
        findsNothing,
        reason:
            'the error face has nothing to kTagNarrow - Riverpod keeping the '
            'previous value must not keep the chrome',
      );
    });

    testWidgets('every row wears the same neutral well', (tester) async {
      await pumpTagCatalog(tester);

      expect(
        find.byIcon(Icons.sell_outlined),
        findsNWidgets(kTagFixtures.length),
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
      await pumpTagCatalog(tester);

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
      await pumpTagCatalog(tester, size: kTagNarrow, textScale: 2);

      final surface = tester.getRect(find.byType(MxCard));
      for (var i = 0; i < kTagFixtures.length; i++) {
        final row = tester.getRect(find.byType(TagCatalogRowWidget).at(i));
        expect(row.left, greaterThanOrEqualTo(surface.left - kTagEpsilon));
        expect(row.right, lessThanOrEqualTo(surface.right + kTagEpsilon));
      }
      // An overflow throws through the test binding; reaching here with no
      // exception is the G9 claim at this size.
      expect(tester.takeException(), isNull);
    });
  });
}
