import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

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

      expect(find.byType(MxPillButton), findsNothing);
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
      // dressed as a redesign. Sort is the toolbar's one chip — the filter
      // moved into the bar's overflow — and the heading counts the list.
      expect(find.text(english.deckSortRecentLabel), findsOneWidget);
      expect(find.byType(MxPillButton), findsOneWidget);
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
    });

    testWidgets('the sort really sorts', (tester) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(threeSummaries()),
        screen: const DeckListScreen(),
      );

      await tester.tap(find.text(english.deckSortRecentLabel));
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<DeckTileWidget>(find.byType(DeckTileWidget))
          .map((DeckTileWidget tile) => tile.summary.deck.name)
          .toList();
      expect(names, <String>['Japanese N5', 'Kanji radicals', 'Spanish verbs']);
    });

    testWidgets('a filter that matches nothing offers the way back', (
      tester,
    ) async {
      // The one empty state that must keep the toolbar: it is how the user
      // undoes the choice that emptied the list.
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

      await tester.tap(find.text(english.decksShowAllAction));
      await tester.pumpAndSettle();

      expect(find.byType(DeckTileWidget), findsOneWidget);
    });
  });
}
