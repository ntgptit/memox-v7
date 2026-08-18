import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_stroke.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';
import 'package:memox/features/search/presentation/widgets/items/card_result_tile_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/deck_result_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/fake_library_search_repository.dart';
import 'support/search_screen_harness.dart';

/// The regressions the M99.32 UI/UX review closed.
///
/// Each of these failed before its fix, and each is here rather than in the
/// state matrix because they are all about a property the matrix cannot see: an
/// edge, a focus ring, a number that should not be printed, a label a screen
/// reader hears.
void main() {
  final english = AppLocalizationsEn();

  group('the gutter is the shell', () {
    for (final (String label, Size surface) in const <(String, Size)>[
      // Below the compact breakpoint, where the shell's gutter is `md` (12) and
      // three hardcoded `AppSpacing.lg` in the body put the rows 4dp inside the
      // field. Above it, where the same code happened to be correct — which is
      // why the defect survived a test suite that only ran at 393.
      ('320', Size(320, 568)),
      ('390', Size(390, 844)),
    ]) {
      testWidgets('the field and the rows share one left edge — $label', (
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

        final double fieldLeft = tester
            .getRect(find.byType(MxSearchField))
            .left;

        expect(
          tester.getRect(find.byType(DeckResultTileWidget)).left,
          fieldLeft,
          reason: 'two owners of one edge is exactly how they drift (W5 G1)',
        );
        expect(
          tester.getRect(find.byType(CardResultTileWidget)).left,
          fieldLeft,
        );
        expect(
          tester.getRect(find.text(english.librarySearchDecksGroupLabel)).left,
          fieldLeft,
        );
      });
    }
  });

  testWidgets('the load-more action clears an open keyboard at 320x568', (
    tester,
  ) async {
    // W4. The harness used to install a fresh `MediaQueryData`, which zeroed
    // `viewInsets` — so no test could reach this state at all.
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(cards: <CardSearchHit>[fakeCardHit()], hasMore: true),
      ),
      surface: const Size(320, 568),
      keyboardInset: 270,
    );
    await typeSearch(tester, 'noun');

    final Finder action = find.text(english.librarySearchLoadMoreAction);
    // Named rather than `find.byType(Scrollable)`: the text field brings one of
    // its own, so the default finder resolves to two.
    await tester.scrollUntilVisible(
      action,
      100,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(action).bottom,
      lessThanOrEqualTo(568 - 270),
      reason: 'the keyboard must not cover the only way to see more',
    );
  });

  testWidgets('a focused row draws the focus ring, not only a wash', (
    tester,
  ) async {
    // WCAG 1.4.11 asks 3:1 of a focus indicator. `AppStateOpacity.focus`'s own
    // documentation measures the 10% wash at ~1.15:1, so the ring is the part
    // that carries the requirement — and a hand-drawn `Material` + `InkWell`
    // has none. This row is an `MxCard` now, which does.
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(decks: <DeckSearchHit>[fakeDeckHit()]),
      ),
    );
    await typeSearch(tester, 'noun');

    // Focus the row itself. Tabbing from the field would have to step over the
    // clear button first, and how many stops that takes is a detail of the
    // shared field rather than of this screen.
    Focus.of(
      tester.element(
        find
            .descendant(
              of: find.byType(DeckResultTileWidget),
              matching: find.byType(ExcludeSemantics),
            )
            .first,
      ),
    ).requestFocus();
    await tester.pumpAndSettle();

    final DecoratedBox box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final BoxDecoration decoration = box.decoration as BoxDecoration;

    expect(decoration.border?.top.width, AppStroke.focus);
    expect(
      decoration.border?.top.color,
      const AppSemanticColors.light().focusRing,
    );
  });

  group('the field never states a count it cannot stand behind', () {
    testWidgets('not while the first page is in flight', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository(
          (_, _, _) => const Stream<Never>.empty(),
        ),
      );
      await tester.enterText(searchInput, 'noun');
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(MxSearchField),
          matching: find.text('0'),
        ),
        findsNothing,
        reason: 'a confident 0 beside a spinner is a wrong answer (S5)',
      );
    });

    testWidgets('not on the failure state', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.failing(),
      );
      await typeSearch(tester, 'noun');

      expect(
        find.descendant(
          of: find.byType(MxSearchField),
          matching: find.text('0'),
        ),
        findsNothing,
        reason: 'a 0 under "Could not search" reads as "there are none"',
      );
    });

    testWidgets('not while more pages remain', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: FakeLibrarySearchRepository.serving(
          fakeSearchPage(cards: <CardSearchHit>[fakeCardHit()], hasMore: true),
        ),
      );
      await typeSearch(tester, 'noun');

      expect(
        find.descendant(
          of: find.byType(MxSearchField),
          matching: find.text('1'),
        ),
        findsNothing,
      );
    });

    testWidgets('but does once every page is in', (tester) async {
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
        find.descendant(
          of: find.byType(MxSearchField),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('a tag-only match says so to a screen reader', (tester) async {
    // The chip lives inside the row's ExcludeSemantics, and match highlighting
    // is deliberately absent (S6) — so without this the label gives a reader a
    // front and a back containing nothing they typed, and no reason at all.
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.serving(
        fakeSearchPage(
          cards: <CardSearchHit>[
            fakeCardHit(front: 'unrelated', matchedTagName: 'noun'),
          ],
        ),
      ),
    );
    await typeSearch(tester, 'noun');

    expect(
      find.bySemanticsLabel(
        english.librarySearchCardResultTaggedSemantic(
          'unrelated',
          'danh từ',
          'Korean › Grammar › Nouns',
          'noun',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the loading-more spinner is announced', (tester) async {
    // W6 names the spinner and the failure band in one sentence: a list that
    // stops partway has to say so, or a reader cannot tell "that is everything"
    // from "the next page is still coming".
    final handle = tester.ensureSemantics();
    await pumpSearchScreen(
      tester,
      repository: FakeLibrarySearchRepository.paged(
        first: fakeSearchPage(
          cards: <CardSearchHit>[fakeCardHit()],
          hasMore: true,
        ),
        // Never answers, so the footer stays in its loading state.
        next: fakeSearchPage(),
      ),
    );
    await typeSearch(tester, 'noun');

    expect(
      find.bySemanticsLabel(english.librarySearchLoadingMoreLabel),
      findsNothing,
      reason: 'nothing is loading until the action is used',
    );

    await tester.tap(find.text(english.librarySearchLoadMoreAction));
    // `pump`, not `pumpAndSettle`: the spinner animates forever by design.
    await tester.pump();

    expect(
      find.bySemanticsLabel(english.librarySearchLoadingMoreLabel),
      findsOneWidget,
      reason:
          'the held page is announced — the liveRegion merges with the '
          "spinner's own semanticsLabel into one node, like card history's "
          'tail',
    );
    handle.dispose();
  });
}
