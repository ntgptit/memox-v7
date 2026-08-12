import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_icon_area_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_workload_line_widget.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The tile's geometry contracts, measured — split from
/// `deck_tile_counts_test.dart` at the 400-line guard, and the seam is real:
/// that file asks *what* each state shows, this one asks *where* it stands.
///
/// Every distance here is asserted against the constants that produce it, so a
/// re-split of a padding or a copied dimension fails as arithmetic rather than
/// surviving as a quietly different screen.
void main() {
  Finder onTile(Finder matching) =>
      find.descendant(of: find.byType(DeckTileWidget), matching: matching);

  Future<void> pump(WidgetTester tester, DeckSummary summary) => pumpDeckScreen(
    tester,
    repository: FakeDeckRepository.withSummaries(<DeckSummary>[summary]),
    screen: const DeckListScreen(),
  );

  group('the tile grid', () {
    testWidgets('the block keeps one rhythm: title, metadata and workload', (
      tester,
    ) async {
      // All three lines live in one column now, and each line break is the
      // same `xs`. Measured on the real text boxes, so a stray floor, padding
      // or alignment cannot quietly stretch one seam past the other.
      await pump(
        tester,
        fakeSummary(
          id: 'd1',
          name: 'Nouns',
          totalCardCount: 60,
          newCardCount: 14,
          dueCardCount: 7,
          learnedCardCount: 22,
        ),
      );

      final english = AppLocalizationsEn();
      final title = tester.getRect(find.text('Nouns'));
      final meta = tester.getRect(
        onTile(find.text(english.deckCardCountLabel(60))),
      );
      final workload = tester.getRect(find.byType(DeckWorkloadLineWidget));

      expect(meta.top - title.bottom, AppSpacing.xs);
      expect(workload.top - meta.bottom, AppSpacing.xs);
    });

    testWidgets('the workload line shares the title axis; the gauge keeps '
        'the full content width', (tester) async {
      // Option 1A: identity, metadata and workload all start on one vertical
      // axis — the eye reads down a single column instead of jumping back to
      // the card edge — while the progress row below stays at the content
      // gutter, because a shortened gauge changes what it appears to measure.
      await pump(
        tester,
        fakeSummary(
          id: 'd1',
          name: 'Nouns',
          totalCardCount: 60,
          newCardCount: 14,
          dueCardCount: 7,
          learnedCardCount: 22,
        ),
      );

      final titleLeft = tester.getRect(find.text('Nouns')).left;
      final workloadLeft = tester
          .getRect(find.byType(DeckWorkloadLineWidget))
          .left;
      final well = tester.getRect(find.byType(DeckIconArea));
      final gauge = tester.getRect(onTile(find.byType(MxProgressBar)));

      expect(workloadLeft, titleLeft, reason: 'one axis for the text column');
      // The indent is derived, not copied: the well's edge plus the header's
      // gap beside it.
      expect(workloadLeft - well.left, DeckIconArea.dimension + AppSpacing.md);
      expect(
        gauge.left,
        well.left,
        reason: 'the gauge starts at the content gutter, not the text axis',
      );
      expect(workloadLeft - gauge.left, DeckIconArea.dimension + AppSpacing.md);
    });
  });
}
