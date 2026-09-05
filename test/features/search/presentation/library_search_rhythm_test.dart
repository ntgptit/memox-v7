import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/widgets/items/card_result_tile_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/deck_result_tile_widget.dart';
import 'package:memox/features/search/presentation/widgets/sections/search_group_header_widget.dart';

import 'support/fake_library_search_repository.dart';
import 'support/search_screen_harness.dart';

/// The vertical grammar of the result list (SC-C2-01).
///
/// **Measured, not read off the source.** The defect this closes was two gaps
/// one step below the app's scale at once — rows at `sm` (8) where every other
/// `MxCard` list is at `lg` (16), and the Decks→Cards break at `lg` where the
/// scale's section step is `xl` (24). The two are coupled: correcting only the
/// row gap would have made the section break equal the item gap, which is the
/// failure `study_home_body_section_widget.dart` names in its own comment.
///
/// `test/app/screen_composition_rhythm_test.dart` catches the row gap
/// structurally, from the AST. It cannot see the *section* break, because that
/// one is an `EdgeInsets` on a `SliverPadding` rather than a separator — so the
/// half of the finding a scan cannot reach is pinned here, by geometry.
///
/// Both widths, for `library_search_review_test.dart`'s recorded reason: at
/// 320dp `mxScreenGutter` steps to `md` and the horizontal edges move, but the
/// vertical scale must not — a rhythm that changes with the gutter is the drift
/// this screen has already had once.
void main() {
  Finder groupHeader(SearchResultGroup group) => find.byWidgetPredicate(
    (Widget widget) =>
        widget is SearchGroupHeaderWidget && widget.group == group,
  );

  for (final (String label, Size surface) in const <(String, Size)>[
    ('320', Size(320, 568)),
    ('393', Size(393, 852)),
  ]) {
    group('the result list keeps the app\'s rhythm — $label', () {
      testWidgets('two rows of one group are a list-item gap apart', (
        tester,
      ) async {
        await pumpSearchScreen(
          tester,
          repository: FakeLibrarySearchRepository.serving(
            fakeSearchPage(
              decks: <DeckSearchHit>[fakeDeckHit()],
              cards: <CardSearchHit>[
                fakeCardHit(),
                fakeCardHit(id: 'card-2', front: 'nouns', back: 'các danh từ'),
              ],
            ),
          ),
          surface: surface,
        );
        await typeSearch(tester, 'noun');

        final List<Rect> rows = tester
            .widgetList<CardResultTileWidget>(find.byType(CardResultTileWidget))
            .map(
              (CardResultTileWidget tile) =>
                  tester.getRect(find.byKey(tile.key!)),
            )
            .toList();

        expect(rows, hasLength(2));
        expect(
          rows[1].top - rows[0].bottom,
          AppSpacing.lg,
          reason:
              'the row carries a 12dp vertical inset of its own, so at sm the '
              'space between two rows was tighter than the space inside one',
        );
      });

      testWidgets('the break between the two groups is a section gap', (
        tester,
      ) async {
        await pumpSearchScreen(
          tester,
          repository: FakeLibrarySearchRepository.serving(
            fakeSearchPage(
              decks: <DeckSearchHit>[fakeDeckHit()],
              cards: <CardSearchHit>[fakeCardHit()],
            ),
          ),
          surface: surface,
        );
        await typeSearch(tester, 'noun');

        final double deckRowBottom = tester
            .getRect(find.byType(DeckResultTileWidget))
            .bottom;
        final double cardsHeaderTop = tester
            .getRect(groupHeader(SearchResultGroup.cards))
            .top;

        expect(
          cardsHeaderTop - deckRowBottom,
          AppSpacing.xl,
          reason:
              'a break that used the gap between two rows would make the '
              'Cards heading read as one more row of the deck list',
        );
        expect(
          cardsHeaderTop - deckRowBottom,
          greaterThan(AppSpacing.lg),
          reason: 'the section break must outrank the item gap it follows',
        );
      });

      testWidgets('whichever group is first opens at the same distance', (
        tester,
      ) async {
        // The lead-in says what the group follows, and the first group follows
        // the pinned field. A cards-only answer must therefore open exactly
        // where a decks-only one does — the `xl` belongs to the *break*, not to
        // the Cards group.
        double leadIn(Finder header) =>
            tester.getRect(header).top -
            tester.getRect(find.byType(CustomScrollView)).top;

        await pumpSearchScreen(
          tester,
          repository: FakeLibrarySearchRepository.serving(
            fakeSearchPage(decks: <DeckSearchHit>[fakeDeckHit()]),
          ),
          surface: surface,
        );
        await typeSearch(tester, 'noun');
        expect(leadIn(groupHeader(SearchResultGroup.decks)), AppSpacing.lg);

        await pumpSearchScreen(
          tester,
          repository: FakeLibrarySearchRepository.serving(
            fakeSearchPage(cards: <CardSearchHit>[fakeCardHit()]),
          ),
          surface: surface,
        );
        await typeSearch(tester, 'noun');
        expect(leadIn(groupHeader(SearchResultGroup.cards)), AppSpacing.lg);
      });
    });
  }
}
