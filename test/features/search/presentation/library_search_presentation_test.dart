import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/widgets/items/card_result_tile_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/deck_result_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';

import 'support/fake_library_search_repository.dart';
import 'support/search_screen_harness.dart';

/// Locale, theme, viewport, semantics and the geometry contract of wireframe
/// M99.32 W5.
///
/// Separate from the state matrix because they answer a different question: not
/// "what is on screen" but "where is it, and can it be read".
void main() {
  final english = AppLocalizationsEn();

  testWidgets('Vietnamese renders its own strings', (tester) async {
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(fakeSearchPage()),
      locale: const Locale('vi'),
    );

    expect(
      find.text(AppLocalizationsVi().librarySearchInitialTitle),
      findsOneWidget,
    );
  });

  for (final (String label, Size surface, double scale)
      in const <(String, Size, double)>[
        ('320 at 2.0', Size(320, 568), 2),
        ('390', Size(390, 844), 1),
        ('412', Size(412, 915), 1),
      ]) {
    testWidgets('it lays out without overflow — $label', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.serving(
          fakeSearchPage(
            decks: <DeckSearchHit>[
              fakeDeckHit(
                name: '명사와 형용사를 모두 담은 아주 긴 이름의 덱',
                path: const <String>[
                  'Tiếng Hàn cơ bản',
                  '문법 정리 노트',
                  'Danh từ và tính từ',
                ],
              ),
            ],
            cards: <CardSearchHit>[
              fakeCardHit(
                front: '아주 긴 앞면 텍스트가 여기에 들어갑니다',
                back: 'Một mặt sau rất dài để kiểm tra việc cắt chữ một dòng',
                matchedTagName: 'ngữ pháp',
              ),
            ],
          ),
        ),
        surface: surface,
        textScale: scale,
      );
      await typeSearch(tester, 'noun');

      expect(tester.takeException(), isNull);
      expect(find.byType(DeckResultTileWidget), findsOneWidget);
      expect(find.byType(CardResultTileWidget), findsOneWidget);
    });
  }

  testWidgets('dark mode renders the same states', (tester) async {
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(cards: <CardSearchHit>[fakeCardHit()]),
      ),
      isDark: true,
    );
    await typeSearch(tester, 'noun');

    expect(find.byType(CardResultTileWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every row announces its kind, its text and its path', (
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
    );
    await typeSearch(tester, 'noun');

    expect(
      find.bySemanticsLabel(
        english.librarySearchDeckResultInPathSemantic(
          'Nouns',
          'Korean › Grammar',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        english.librarySearchCardResultSemantic(
          'noun',
          'danh từ',
          'Korean › Grammar › Nouns',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('every row clears the 48dp touch floor', (tester) async {
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          decks: <DeckSearchHit>[fakeDeckHit()],
          cards: <CardSearchHit>[fakeCardHit()],
        ),
      ),
    );
    await typeSearch(tester, 'noun');

    for (final Finder row in <Finder>[
      find.byType(DeckResultTileWidget),
      find.byType(CardResultTileWidget),
    ]) {
      expect(tester.getRect(row).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('the field, the group header and the rows share one gutter', (
    tester,
  ) async {
    // Geometry, because "aligned" is not a property any widget exposes. The
    // field lives in the shell's subheader and the rows live in a sliver with
    // its own padding — two owners of one edge is exactly how they drift.
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          decks: <DeckSearchHit>[fakeDeckHit()],
          cards: <CardSearchHit>[fakeCardHit()],
        ),
      ),
    );
    await typeSearch(tester, 'noun');

    final double deckLeft = tester
        .getRect(find.byType(DeckResultTileWidget))
        .left;
    final double cardLeft = tester
        .getRect(find.byType(CardResultTileWidget))
        .left;
    final double headerLeft = tester
        .getRect(find.text(english.librarySearchDecksGroupLabel))
        .left;

    expect(cardLeft, deckLeft);
    expect(headerLeft, deckLeft);
    expect(
      tester.getRect(find.byType(DeckResultTileWidget)).width,
      tester.getRect(find.byType(CardResultTileWidget)).width,
      reason: 'two rows of one list are one column',
    );
  });

  testWidgets('the input stays pinned above the results', (tester) async {
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(decks: <DeckSearchHit>[fakeDeckHit()]),
      ),
    );
    await typeSearch(tester, 'noun');

    expect(
      tester.getRect(searchInput).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(DeckResultTileWidget)).top),
    );
  });
}
