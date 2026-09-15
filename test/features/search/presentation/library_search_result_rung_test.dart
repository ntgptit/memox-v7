import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/widgets/items/card_result_tile_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/deck_result_tile_widget.dart';

import 'support/fake_library_search_repository.dart';
import 'support/search_screen_harness.dart';

/// The type rung of a result row's primary line (SC-C6-01).
///
/// **Asserted as the whole `TextStyle`, not as a font size.** The defect was a
/// *weight* inversion — the primary line at bodyLarge's w400 sitting lighter
/// than the w500 path caption printed directly above it — and both rungs are
/// 16sp, so a size assertion would have passed against the bug. Comparing the
/// rendered style to the theme's own `titleMedium` catches a bare
/// `copyWith(fontWeight:)` too, which is the shape the regression would most
/// likely come back in.
void main() {
  Finder primaryLine<T extends Widget>(String text) =>
      find.descendant(of: find.byType(T), matching: find.text(text));

  Future<void> pumpBothRows(
    WidgetTester tester, {
    Size surface = const Size(393, 852),
    double textScale = 1,
  }) async {
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          decks: <DeckSearchHit>[fakeDeckHit()],
          cards: <CardSearchHit>[fakeCardHit()],
        ),
      ),
      surface: surface,
      textScale: textScale,
    );
    await typeSearch(tester, 'noun');
  }

  testWidgets('both result rows title at the app\'s row rung', (tester) async {
    await pumpBothRows(tester);

    final TextTheme texts = Theme.of(
      tester.element(find.byType(DeckResultTileWidget)),
    ).textTheme;

    expect(
      tester.widget<Text>(primaryLine<DeckResultTileWidget>('Nouns')).style,
      texts.titleMedium,
      reason:
          'the deck name is the thing the row is about; bodyLarge left it a '
          'weight below the path caption above it',
    );
    expect(
      tester.widget<Text>(primaryLine<CardResultTileWidget>('noun')).style,
      texts.titleMedium,
      reason:
          'the front is the word the row is about — the same rule '
          '`card_tile_widget.dart` already states for the browsed card row',
    );
  });

  testWidgets('the rung swap moves no metric', (tester) async {
    // Why nothing reflowed: the two rungs differ in weight and tracking only.
    // Pinning that here means a future edit to the *scale* is what fails, at
    // the place that explains the consequence, rather than four goldens.
    await pumpBothRows(tester);

    final TextTheme texts = Theme.of(
      tester.element(find.byType(DeckResultTileWidget)),
    ).textTheme;

    expect(texts.titleMedium!.fontSize, texts.bodyLarge!.fontSize);
    expect(texts.titleMedium!.height, texts.bodyLarge!.height);
    expect(
      texts.titleMedium!.letterSpacing,
      lessThan(texts.bodyLarge!.letterSpacing!),
      reason:
          'tracking falls 0.5 -> 0.15, so the line gets narrower — the '
          'direction that cannot introduce a wrap',
    );
  });

  testWidgets('the heavier rung still fits at 320 and textScale 1.3', (
    tester,
  ) async {
    await pumpBothRows(tester, surface: const Size(320, 568), textScale: 1.3);

    expect(tester.takeException(), isNull);

    final Rect deckLine = tester.getRect(
      primaryLine<DeckResultTileWidget>('Nouns'),
    );
    final Rect cardLine = tester.getRect(
      primaryLine<CardResultTileWidget>('noun'),
    );

    // The card front is `maxLines: 1` and so cannot wrap; the deck name is
    // `maxLines: 2` and can. Equal heights at the same rung and the same scale
    // is therefore the assertion that the deck name is still on one line.
    expect(
      deckLine.height,
      cardLine.height,
      reason: 'a heavier primary line must not push the deck name to two lines',
    );

    for (final Finder row in <Finder>[
      find.byType(DeckResultTileWidget),
      find.byType(CardResultTileWidget),
    ]) {
      expect(
        tester.getRect(row).height,
        greaterThanOrEqualTo(AppSizing.touchTarget),
        reason: 'the shell\'s floor still holds under the larger text',
      );
    }
  });
}
