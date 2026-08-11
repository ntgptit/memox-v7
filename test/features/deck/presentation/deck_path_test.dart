import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The breadcrumb on a deck level — when it appears, what it lists, and where a
/// step goes (M4.10d).
///
/// Split from `deck_list_level_test.dart` at the size guard, on a real seam: the
/// path is about the levels *above* this one, while everything left there is
/// about the level itself.
///
/// `MxBreadcrumb`'s own contract — overflow, semantics, the non-tappable step —
/// is in `test/shared/widgets/mx_breadcrumb_test.dart`. What is below is the
/// adapter's decisions: which levels get a path at all, and that the deck the
/// user is standing in is deliberately not in it.
void main() {
  /// A repository serving one deck and the children it should show.
  FakeDeckRepository serving(
    DeckEntity deck, {
    List<DeckSummary> children = const <DeckSummary>[],
    List<DeckPathSegment> ancestors = const <DeckPathSegment>[],
    List<DeckEntity>? allDecks,
    Failure? writeFailure,
  }) => FakeDeckRepository(
    deckList: (_) => Stream<DeckListSnapshot>.value(
      DeckListSnapshot(
        ancestors: ancestors,
        parent: deck,
        decks: children,
        nextDueAt: null,
      ),
    ),
    allDecks: () =>
        Stream<List<DeckEntity>>.value(allDecks ?? <DeckEntity>[deck]),
    writeFailure: writeFailure,
  );

  Future<void> pumpLevel(
    WidgetTester tester,
    FakeDeckRepository repository, {
    String deckId = 'deck-1',
    Size surface = const Size(393, 852),
    double textScale = 1,
    bool isDark = false,
  }) => pumpDeckScreen(
    tester,
    repository: repository,
    screen: DeckListScreen(parentDeckId: deckId),
    surface: surface,
    textScale: textScale,
    isDark: isDark,
  );

  group('the path back up', () {
    testWidgets('it runs from the deck list down to the deck you are in', (
      tester,
    ) async {
      final english = AppLocalizationsEn();

      await pumpLevel(
        tester,
        serving(
          fakeSubDeck(id: 'deck-1', name: 'Hiragana', parentId: 'branch'),
          ancestors: fakePath(<String>['Japanese N5', 'Kana']),
        ),
      );

      expect(find.byType(MxBreadcrumb), findsOneWidget);
      final MxBreadcrumb crumb = tester.widget(find.byType(MxBreadcrumb));
      // The whole path, literally. Both ends used to be dropped as duplicate
      // chrome — the list is what Back reaches, the deck is what the title says
      // — and the result was a strip that answered "where am I" only in the
      // middle of the tree.
      expect(crumb.items.map((MxBreadcrumbItem i) => i.label), <String>[
        english.deckPathRootLabel,
        'Japanese N5',
        'Kana',
        'Hiragana',
      ]);
      // Every step but the last goes somewhere; the last is where you already
      // are, so it renders as text rather than as a control that does nothing.
      expect(
        crumb.items.take(3).every((MxBreadcrumbItem i) => i.onTap != null),
        isTrue,
      );
      expect(crumb.items.last.onTap, isNull);
    });

    testWidgets('a root deck gets one too — Root, then itself', (tester) async {
      // The case that used to render nothing, and the reason this changed: one
      // level in is where a user first looks for a breadcrumb, and finding none
      // there reads as the component being broken rather than as a decision.
      final english = AppLocalizationsEn();

      await pumpLevel(
        tester,
        serving(fakeRootDeck(id: 'deck-1', name: 'Japanese N5')),
      );

      final MxBreadcrumb crumb = tester.widget(find.byType(MxBreadcrumb));
      expect(crumb.items.map((MxBreadcrumbItem i) => i.label), <String>[
        english.deckPathRootLabel,
        'Japanese N5',
      ]);
    });

    testWidgets('the deck list itself shows Root, and it does not act', (
      tester,
    ) async {
      // The top of the tree is a place like any other, so it says so. It is not
      // a link there: tapping it would navigate to the screen already on screen,
      // which is the same reason the last step of a deeper path is text.
      final english = AppLocalizationsEn();

      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(id: '1', name: 'Japanese N5'),
        ]),
        screen: const DeckListScreen(),
      );

      final MxBreadcrumb crumb = tester.widget(find.byType(MxBreadcrumb));
      expect(crumb.items.map((MxBreadcrumbItem i) => i.label), <String>[
        english.deckPathRootLabel,
      ]);
      expect(crumb.items.single.onTap, isNull);
    });

    testWidgets('it starts at the gutter, not centred in the strip', (
      tester,
    ) async {
      // Geometry, because "it looks left-aligned" is not a property any widget
      // exposes. The subheader's Column defaulted to centring its children; the
      // search field is full width so it hid that, and only the breadcrumb —
      // which is as wide as its own steps — showed a path floating in the middle
      // of a screen whose every other element starts at the gutter.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(id: '1', name: 'Japanese N5'),
        ]),
        screen: const DeckListScreen(),
      );

      // **The first painted thing, not the strip's box.** Asserting the widget
      // origin passed while every step still carried `sm` of leading padding,
      // so the box sat on the gutter and the word sat 8px inside it — which is
      // what a reader sees and what was reported.
      expect(
        tester.getTopLeft(find.byIcon(Icons.home_outlined)).dx,
        tester.getTopLeft(find.byType(MxSearchField)).dx,
        reason: 'the path and the search field share one left edge',
      );
    });

    testWidgets('the root step keeps its home glyph', (tester) async {
      // It lost it for a release: the glyph was drawn on the tappable branch
      // only, and the deck list's `Root` step is the one step in the app that is
      // first and non-tappable at once — so the mark that makes the top of the
      // tree recognisable without reading was missing exactly there.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(id: '1', name: 'Japanese N5'),
        ]),
        screen: const DeckListScreen(),
      );

      expect(
        find.descendant(
          of: find.byType(MxBreadcrumb),
          matching: find.byIcon(Icons.home_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the Root step goes back to the deck list', (tester) async {
      // Through the real router, like the ancestor case below: what the step
      // does is the whole of its behaviour.
      final english = AppLocalizationsEn();
      final repository = FakeDeckRepository(
        deckList: (String? id) => Stream<DeckListSnapshot>.value(
          DeckListSnapshot(
            parent: fakeRootDeck(id: id ?? 'deck-1', name: 'Japanese N5'),
            ancestors: const <DeckPathSegment>[],
            decks: const <DeckSummary>[],
            nextDueAt: null,
          ),
        ),
      );
      final router = await pumpDeckApp(
        tester,
        repository: repository,
        initialLocation: '/decks/deck-1',
      );

      // Scoped to the strip: labels elsewhere on the screen — the bottom
      // navigation's tab, the app bar — are allowed to collide with the
      // breadcrumb's, so a bare text finder would be ambiguous about which
      // control this test is exercising.
      await tester.tap(
        find.descendant(
          of: find.byType(MxBreadcrumb),
          matching: find.text(english.deckPathRootLabel),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });

    testWidgets('tapping an ancestor navigates to that deck', (tester) async {
      // Through the real router: the crumb calls `goNamed`, which needs a
      // GoRouter above it, and the assertion that matters is the location it
      // lands on rather than that a callback fired.
      final repository = FakeDeckRepository(
        deckList: (String? id) => Stream<DeckListSnapshot>.value(
          DeckListSnapshot(
            parent: fakeSubDeck(
              id: id ?? 'deck-1',
              name: 'Hiragana',
              parentId: 'branch',
            ),
            ancestors: fakePath(<String>['Japanese N5']),
            decks: const <DeckSummary>[],
            nextDueAt: null,
          ),
        ),
      );
      final router = await pumpDeckApp(
        tester,
        repository: repository,
        initialLocation: '/decks/deck-1',
      );

      await tester.tap(find.text('Japanese N5'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/decks/path-0',
      );
    });

    testWidgets('it is shown above an empty level too', (tester) async {
      // Where the level has nothing in it is exactly where "where am I" is
      // hardest to answer from what is on screen.
      await pumpLevel(
        tester,
        serving(
          fakeSubDeck(id: 'deck-1', name: 'Empty', parentId: 'branch'),
          ancestors: fakePath(<String>['Japanese N5', 'Kana']),
        ),
      );

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.byType(MxBreadcrumb), findsOneWidget);
    });

    testWidgets('a full-depth path fits 320x568 at textScaler 2.0', (
      tester,
    ) async {
      // BR-55 caps the tree at ten, so nine ancestors is the worst real case.
      await pumpLevel(
        tester,
        serving(
          fakeSubDeck(id: 'deck-1', name: 'Level ten', parentId: 'branch'),
          ancestors: fakePath(<String>[
            for (var i = 1; i <= 9; i++) 'Level number $i',
          ]),
        ),
        surface: const Size(360, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
