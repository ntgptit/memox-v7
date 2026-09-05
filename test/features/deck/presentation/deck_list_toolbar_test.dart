import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_list_toolbar_widget.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The root list's filter and sort, driven through the real screen.
///
/// `deck_list_view_test.dart` covers the transform itself, which is pure. What
/// is left to prove here is that the controls are wired to it — the sort chip
/// on the toolbar, and the due-only filter that lives in the bar's overflow
/// menu now (owner mockup, 2026-08-20) — that operating one changes what is
/// on screen rather than only what is highlighted.
///
/// Split from `root_deck_list_screen_test.dart` when that file crossed the
/// 400-line guard.
void main() {
  final english = AppLocalizationsEn();

  List<DeckSummary> threeSummaries() => <DeckSummary>[
    fakeSummary(
      id: '1',
      name: 'Japanese N5',
      totalCardCount: 120,
      dueCardCount: 7,
    ),
    fakeSummary(id: '2', name: 'Spanish verbs', totalCardCount: 40),
    fakeSummary(
      id: '3',
      name: 'Kanji radicals',
      schedulerType: SchedulerType.sm2,
    ),
  ];

  group('the toolbar', () {
    testWidgets('does not exist until there is something to act on', (
      tester,
    ) async {
      // A filter and a sort over nothing are two controls that visibly do
      // nothing, which is the dead control this redesign refused to copy from
      // the reference.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository(),
        screen: const DeckListScreen(),
      );

      expect(find.byType(DeckListToolbarWidget), findsNothing);
      expect(find.byType(MxEmptyState), findsOneWidget);
    });

    testWidgets('appears with the decks, showing what is on screen', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      // The defaults describe the repository's own answer: everything, in its
      // own order. A default that changed the view would be a content change
      // dressed as a redesign.
      expect(find.byType(DeckListToolbarWidget), findsOneWidget);
      // **The order is painted on the row, in the same words the sheet uses.**
      // The first compaction pass took the control down to a bare glyph and
      // moved the order into the sheet; a glyph says "sort" and cannot say
      // "sorted by what", which is the half a user needs (owner review,
      // 2026-08-25).
      expect(find.text(english.deckSortManualLabel), findsOneWidget);
      // The painted word is a value, so the announcement says what pressing it
      // does — and contains the painted word rather than replacing it.
      expect(
        find.bySemanticsLabel(
          english.deckSortControlSemanticLabel(english.deckSortManualLabel),
        ),
        findsWidgets,
      );
      // The root's figures live in the header now (owner review,
      // 2026-08-21), so the heading is the label alone.
      expect(
        find.text(english.decksSectionLabelRoot.toUpperCase()),
        findsOneWidget,
      );
      expect(find.textContaining(' · 3'), findsNothing);
    });

    testWidgets('the filter really filters', (tester) async {
      // One of the three fixtures has cards due.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );
      expect(find.byType(DeckTileWidget), findsNWidgets(3));

      // The filter lives in the bar's overflow now: open it, choose the
      // due-only view.
      await tester.tap(find.byTooltip(english.libraryActionsTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckFilterDueLabel));
      await tester.pumpAndSettle();

      expect(find.byType(DeckTileWidget), findsOneWidget);
      expect(find.text('Japanese N5'), findsOneWidget);
      expect(
        find.text(english.deckHeaderStatsLabel(3, 160)),
        findsOneWidget,
        reason: 'the header states the level, filtered or not',
      );
      // The guard on the rule below: a filter is only a reason to drop the
      // toolbar when it matched *nothing*. One row left is still a list, and a
      // list still has an order worth changing.
      expect(find.byType(DeckListToolbarWidget), findsOneWidget);
    });

    /// Opens the sort sheet and picks [option].
    ///
    /// **Scoped to the sheet, and it has to be.** The row and the sheet name
    /// the orders with the same string now, so a bare `find.text` matches the
    /// control the tap just opened the sheet from as well as the row inside
    /// it — and taps whichever the tree happens to hold first.
    Future<void> chooseSort(WidgetTester tester, String option) async {
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(MxActionSheet),
          matching: find.text(option),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The names on screen, top to bottom.
    List<String> tileNames(WidgetTester tester) => tester
        .widgetList<DeckTileWidget>(find.byType(DeckTileWidget))
        .map((DeckTileWidget tile) => tile.summary.deck.name)
        .toList();

    testWidgets('the sheet ticks the order the list is already in', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();

      // Five options, and exactly one carries the tick. The count is half the
      // assertion: a sheet that ticked two would be worse than one that ticked
      // none, because it would look answered.
      final rows = tester
          .widgetList<MxActionSheet>(find.byType(MxActionSheet))
          .single
          .actions;
      expect(rows.length, 5);
      // The sheet and the row name the orders the same way — one vocabulary,
      // since the label that needed shortening was the one that lied.
      expect(
        rows.map((MxActionSheetAction row) => row.label),
        containsAll(<String>[
          english.deckSortManualLabel,
          english.deckSortRecentLabel,
          english.deckSortCardsDueLabel,
        ]),
      );
      expect(
        rows
            .where((MxActionSheetAction row) => row.isSelected)
            .map((MxActionSheetAction row) => row.label),
        <String>[english.deckSortManualLabel],
      );
    });

    testWidgets('sorting by name really sorts', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      await chooseSort(tester, english.deckSortNameLabel);

      expect(tileNames(tester), <String>[
        'Japanese N5',
        'Kanji radicals',
        'Spanish verbs',
      ]);
    });

    testWidgets('cards due puts the backlog first', (tester) async {
      // Only Japanese N5 has anything due, so it leads whatever order the
      // repository emitted.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      await chooseSort(tester, english.deckSortCardsDueLabel);

      expect(tileNames(tester).first, 'Japanese N5');
    });

    testWidgets('progress orders by fraction, not by cards left', (
      tester,
    ) async {
      // The trap this locks: `Nearly done` has 90 unlearned cards and
      // `Barely started` only 18, so a sort on the learned *count* would put
      // the almost-finished deck first. The fraction is what a learner means
      // by "how far am I" — 90% against 10%.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(
            id: 'a',
            name: 'Nearly done',
            totalCardCount: 900,
            learnedCardCount: 810,
          ),
          fakeSummary(
            id: 'b',
            name: 'Barely started',
            totalCardCount: 20,
            learnedCardCount: 2,
          ),
        ]),
        screen: const DeckListScreen(),
      );

      await chooseSort(tester, english.deckSortProgressLabel);

      expect(tileNames(tester), <String>['Barely started', 'Nearly done']);
    });

    testWidgets('choosing the order already in force changes nothing', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      final before = tileNames(tester);
      await chooseSort(tester, english.deckSortRecentLabel);

      expect(tileNames(tester), before);
    });

    testWidgets('a filter that matches nothing offers the way back', (
      tester,
    ) async {
      // **And loses the toolbar with the list.** The screen already refused to
      // build a filter and a sort over an empty *level* — "two controls that
      // visibly do nothing" — and this state was exempt only because that is
      // where the early return happened to stop, never because anyone decided
      // it. Dropping it costs nothing: the way back out of the filter is on
      // the empty face itself, which is what the rest of this test walks.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(id: '1', name: 'Spanish verbs', totalCardCount: 40),
        ]),
        screen: const DeckListScreen(),
      );

      await tester.tap(find.byTooltip(english.libraryActionsTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckFilterDueLabel));
      await tester.pumpAndSettle();

      expect(find.byType(DeckTileWidget), findsNothing);
      expect(find.text(english.decksNoDueTitle), findsOneWidget);
      expect(find.byType(DeckListToolbarWidget), findsNothing);

      await tester.tap(find.text(english.decksShowAllAction));
      await tester.pumpAndSettle();

      expect(find.byType(DeckTileWidget), findsOneWidget);
    });

    testWidgets('and inside a deck the count-to-zero heading goes with it', (
      tester,
    ) async {
      // The level where the dead control was loudest. The root's figure lives
      // in the header, so its heading is the label alone; inside a deck the
      // heading keeps the figure as its detail — which made a filter that
      // matched nothing print "SUB-DECKS · 0" over a sort acting on no rows.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withLevel(
          parent: fakeRootDeck(id: 'deck-1', name: 'Japanese'),
          children: <DeckSummary>[
            fakeChildSummary(id: 'c1', name: 'Hiragana', parentId: 'deck-1'),
          ],
        ),
        screen: const DeckListScreen(parentDeckId: 'deck-1'),
      );

      expect(find.byType(DeckListToolbarWidget), findsOneWidget);
      expect(find.textContaining('· 1'), findsOneWidget);

      // The level's own overflow, not the library's — scoped to the bar,
      // because every deck row draws the same glyph.
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckFilterDueLabel));
      await tester.pumpAndSettle();

      expect(find.text(english.decksNoDueTitle), findsOneWidget);
      expect(find.byType(DeckListToolbarWidget), findsNothing);
      expect(find.textContaining('· 0'), findsNothing);
    });
  });
}
