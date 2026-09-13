import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_workload_line_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_mastery_ring.dart';
import 'package:memox/shared/widgets/mx_row_group.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The row's geometry contracts, measured — split from
/// `deck_tile_counts_test.dart` at the 400-line guard, and the seam is real:
/// that file asks *what* each state shows, this one asks *where* it stands.
///
/// Every distance here is asserted against the constants that produce it, so a
/// re-split of a padding or a copied dimension fails as arithmetic rather than
/// surviving as a quietly different screen.
void main() {
  final english = AppLocalizationsEn();

  Finder onTile(Finder matching) =>
      find.descendant(of: find.byType(DeckTileWidget), matching: matching);

  DeckSummary nouns() => fakeSummary(
    id: 'd1',
    name: 'Nouns',
    totalCardCount: 60,
    newCardCount: 14,
    dueCardCount: 7,
    learnedCardCount: 22,
  );

  Future<void> pump(WidgetTester tester, DeckSummary summary) => pumpDeckScreen(
    tester,
    repository: FakeDeckRepository.withSummaries(<DeckSummary>[summary]),
    screen: const DeckListScreen(),
  );

  group('the row grid', () {
    testWidgets('the text column keeps one rhythm: name, cards, counts', (
      tester,
    ) async {
      // All three lines live in one column, and each line break is the same
      // step. Measured on the real text boxes, so a stray floor, padding or
      // alignment cannot quietly stretch one seam past the other. The pair is
      // asserted against each other first and against the token second.
      await pump(tester, nouns());

      final title = tester.getRect(find.text('Nouns'));
      final meta = tester.getRect(
        onTile(find.text(english.deckCardCountLabel(60))),
      );
      final workload = tester.getRect(find.byType(DeckWorkloadLineWidget));

      expect(
        meta.top - title.bottom,
        workload.top - meta.bottom,
        reason: 'one rhythm, whatever the step is',
      );
      expect(meta.top - title.bottom, AppSpacing.xs);
    });

    testWidgets('tile, text, ring and overflow stand on the handoff grid', (
      tester,
    ) async {
      await pump(tester, nouns());

      final row = tester.getRect(find.byType(DeckTileWidget));
      final tile = tester.getRect(onTile(find.byType(MxIconTile)));
      final title = tester.getRect(find.text('Nouns'));
      final ring = tester.getRect(onTile(find.byType(MxMasteryRing)));
      final overflow = tester.getRect(onTile(find.byType(MxIconButton)));

      expect(tile.left - row.left, AppSpacing.lg);
      expect(tile.size, const Size.square(AppSizing.iconTileMd));
      // The text column starts one `md` past the tile, and every line of it
      // on that one axis.
      expect(title.left - tile.right, AppSpacing.md);
      expect(
        tester.getRect(find.byType(DeckWorkloadLineWidget)).left,
        title.left,
      );
      expect(ring.size, const Size.square(AppSizing.masteryRing));
      // `xs` at the end: 4 + the overflow's own 12 inset puts its glyph on
      // the 16 gutter.
      expect(row.right - overflow.right, AppSpacing.xs);
      // Centred on the row, not hung from its top.
      expect(tile.center.dy, moreOrLessEquals(row.center.dy, epsilon: 0.5));
      expect(ring.center.dy, moreOrLessEquals(row.center.dy, epsilon: 0.5));
    });

    testWidgets('the row stands at least 48, and its overflow is a 48 target', (
      tester,
    ) async {
      // The shortest row there is: no cards, so no ring.
      await pump(tester, fakeSummary(id: 'd1', name: 'Brand new'));

      expect(
        tester.getSize(find.byType(DeckTileWidget)).height,
        greaterThanOrEqualTo(AppSizing.rowMinHeight),
      );
      final overflow = tester.getSize(onTile(find.byType(MxIconButton)));
      expect(overflow.width, greaterThanOrEqualTo(AppSizing.touchTarget));
      expect(overflow.height, greaterThanOrEqualTo(AppSizing.touchTarget));
    });

    testWidgets('a level is one card, its rows split by hairlines at the '
        'leading inset', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          nouns(),
          fakeSummary(id: 'd2', name: 'Verbs', totalCardCount: 8),
          fakeSummary(id: 'd3', name: 'Kanji', totalCardCount: 3),
        ]),
        screen: const DeckListScreen(),
      );

      final group = find.byType(MxRowGroup);
      expect(group, findsOneWidget);
      expect(
        find.ancestor(of: group, matching: find.byType(MxCard)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: group, matching: find.byType(DeckTileWidget)),
        findsNWidgets(3),
      );

      final hairlines = find.descendant(
        of: group,
        matching: find.byType(Divider),
      );
      expect(hairlines, findsNWidgets(2), reason: 'none after the last row');
      expect(
        tester.widget<Divider>(hairlines.first).indent,
        AppSizing.listDividerIndent,
      );
      // Nothing between two rows but the hairline.
      final hairline = tester.getRect(hairlines.first);
      expect(
        hairline.top,
        tester.getRect(find.byType(DeckTileWidget).at(0)).bottom,
      );
      expect(
        tester.getRect(find.byType(DeckTileWidget).at(1)).top,
        hairline.bottom,
      );
    });
  });

  group('the 4px grid (owner review, 2026-08-20)', () {
    /// Every control height and inset on this screen is a multiple of four.
    /// The rule is the owner's and it is worth a test rather than a comment:
    /// the values that broke it — a 6px track, an 11/14 inset — each arrived
    /// as a local optical fix, and a local fix is invisible to the next one.
    testWidgets('the chip and the path line land on it', (tester) async {
      await pump(tester, nouns());

      final chip = tester
          .getRect(
            find
                .ancestor(
                  of: find.text(english.deckTileDueChipLabel(7)),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .height;
      expect(chip, 24, reason: 'due chip: 8 across, 24 tall');

      // The root header has no path — it states the level's figures — so the
      // line itself is measured one level in, by `deck_path_test.dart`.
      expect(MxBreadcrumb.compactLineHeight, 32);
    });
  });

  group('at text scale 2.0 on a compact width', () {
    testWidgets('the whole anatomy survives 320px at double text', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(
            id: 'd1',
            name: 'A deck with a deliberately long name that wraps',
            totalCardCount: 60,
            newCardCount: 14,
            dueCardCount: 7,
            learnedCardCount: 22,
          ),
        ]),
        screen: const DeckListScreen(),
        surface: const Size(320, 852),
        textScale: 2,
      );

      expect(
        onTile(find.text(english.deckTileDueChipLabel(7))),
        findsOneWidget,
      );
      expect(
        onTile(find.text(english.deckTileNewChipLabel(14))),
        findsOneWidget,
      );
      expect(onTile(find.byType(MxMasteryRing)), findsOneWidget);
      expect(onTile(find.byType(MxIconButton)), findsOneWidget);
      expect(tester.takeException(), isNull);

      // One inset on every width: the row no longer steps its gutter down
      // below the compact breakpoint the way the card did (M100.91).
      expect(
        tester.getRect(onTile(find.byType(MxIconTile))).left -
            tester.getRect(find.byType(DeckTileWidget)).left,
        AppSpacing.lg,
      );

      // No separators left to strand: each count has its own ground.
      expect(
        find.descendant(
          of: find.byType(DeckWorkloadLineWidget),
          matching: find.text('·'),
        ),
        findsNothing,
      );
    });
  });
}
