import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_study_button_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_workload_line_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The tile's state matrix: the workload chips, one gauge, one verb
/// (BR-150, BR-142, BR-29).
///
/// **Positive counts only, until nothing is pending** (owner mockup,
/// 2026-08-20): a metric at zero stays quiet while any sibling speaks; the
/// one exception is a filled deck with nothing pending at all, which still
/// states both zeroes — there, absence would be ambiguous.
void main() {
  final english = AppLocalizationsEn();

  String due(int count) => english.deckTileDueChipLabel(count);
  String fresh(int count) => english.deckTileNewChipLabel(count);

  /// Scoped to the tile: the summary panel above the list states the same
  /// metrics in the same words, and an unscoped finder counts both.
  Finder onTile(Finder matching) =>
      find.descendant(of: find.byType(DeckTileWidget), matching: matching);

  Future<void> pump(WidgetTester tester, DeckSummary summary) => pumpDeckScreen(
    tester,
    repository: FakeDeckRepository.withSummaries(<DeckSummary>[summary]),
    screen: const DeckListScreen(),
  );

  group('mixed (7 Due, 14 New, 37%)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Nouns',
      totalCardCount: 60,
      newCardCount: 14,
      dueCardCount: 7,
      learnedCardCount: 22,
    );

    testWidgets('both metrics, Study, and a gauge below 100%', (tester) async {
      await pump(tester, summary);

      expect(onTile(find.text(due(7))), findsOneWidget);
      expect(onTile(find.text(fresh(14))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);

      final bar = tester.widget<MxProgressBar>(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.byType(MxProgressBar),
        ),
      );
      expect(bar.value, lessThan(1));
      expect(
        onTile(find.text(english.deckTileLearnedPercentLabel(37))),
        findsOneWidget,
      );
    });

    testWidgets('the block is words; the only icon is the status square', (
      tester,
    ) async {
      await pump(tester, summary);

      // The icon-per-metric grammar is gone by measurement: five anchors on a
      // three-line block wrapped the metadata and grew the card. The facts
      // read as text, and the one glyph left is the schedule status.
      expect(onTile(find.byIcon(Icons.style_outlined)), findsNothing);
      expect(onTile(find.byIcon(Icons.account_tree_outlined)), findsNothing);
      expect(onTile(find.byIcon(Icons.auto_awesome_outlined)), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DeckWorkloadLineWidget),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
      // Seven due with zero overdue days is the due-today state.
      expect(onTile(find.byIcon(Icons.event)), findsOneWidget);

      // One typography for the pair.
      final dueStyle = tester.widget<Text>(onTile(find.text(due(7)))).style;
      final newStyle = tester.widget<Text>(onTile(find.text(fresh(14)))).style;
      expect(dueStyle?.fontSize, newStyle?.fontSize);
      expect(dueStyle?.fontWeight, newStyle?.fontWeight);
    });

    testWidgets('the gauge is inset with the card content, not flush at the '
        'edge', (tester) async {
      await pump(tester, summary);

      final card = tester.getRect(find.byType(DeckTileWidget));
      final bar = tester.getRect(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.byType(MxProgressBar),
        ),
      );

      // Flush at the edge it read as a decorated border; inside the surface it
      // reads as a measurement. The inset is the card's own content padding.
      expect(bar.left - card.left, greaterThan(0));
      expect(card.right - bar.right, greaterThan(0));
      expect(card.bottom - bar.bottom, greaterThan(0));
    });
  });

  group('new-only (0 Due, 14 New)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Fresh deck',
      totalCardCount: 20,
      newCardCount: 14,
    );

    testWidgets('leads with the new count, keeps Study, and claims no '
        'success', (tester) async {
      await pump(tester, summary);

      // The due metric at zero stays quiet while new is speaking.
      expect(onTile(find.text(due(0))), findsNothing);
      expect(onTile(find.text(fresh(14))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
      // Nothing due today is not "done": no success ink anywhere on the tile.
      expect(find.byIcon(Icons.check_circle), findsNothing);
      // Nothing due: the status square rests on the outlined calendar, and
      // the workload line carries no icons at all.
      expect(onTile(find.byIcon(Icons.event_outlined)), findsOneWidget);
      expect(onTile(find.byIcon(Icons.schedule)), findsNothing);
    });
  });

  group('due-only (5 Due, 0 New)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Seasoned deck',
      totalCardCount: 9,
      dueCardCount: 5,
      learnedCardCount: 4,
    );

    testWidgets('keeps the new side quiet at zero and keeps Study', (
      tester,
    ) async {
      await pump(tester, summary);

      expect(onTile(find.text(due(5))), findsOneWidget);
      expect(onTile(find.text(fresh(0))), findsNothing);
      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
    });
  });

  group('nothing studyable (0 Due, 0 New, 50%)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Half way',
      totalCardCount: 8,
      learnedCardCount: 4,
    );

    testWidgets('both zeroes stay on the line and Study is absent, not '
        'disabled', (tester) async {
      await pump(tester, summary);

      expect(onTile(find.text(due(0))), findsOneWidget);
      expect(onTile(find.text(fresh(0))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsNothing);
    });

    testWidgets('and does not claim completion for an idle day (BR-29)', (
      tester,
    ) async {
      await pump(tester, summary);

      // 50% learned with nothing pending is neutral: no success check, and the
      // percentage stays in the quiet variant — success is earned at 100%.
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(
        onTile(find.text(english.deckTileLearnedPercentLabel(50))),
        findsOneWidget,
      );
    });
  });

  group('completed (0 Due, 0 New, 100%)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Verbs',
      totalCardCount: 60,
      learnedCardCount: 60,
    );

    testWidgets('success lives on the gauge and its figure alone', (
      tester,
    ) async {
      await pump(tester, summary);

      // No check glyph any more: the full gauge and its success figure are
      // the completion signal, and the status square answers "when" — for a
      // deck with nothing due, an outlined calendar at rest.
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(onTile(find.byIcon(Icons.event_outlined)), findsOneWidget);
      expect(onTile(find.text(due(0))), findsOneWidget);
      expect(onTile(find.text(fresh(0))), findsOneWidget);
      expect(
        onTile(find.text(english.deckTileLearnedPercentLabel(100))),
        findsOneWidget,
      );
      expect(find.byType(DeckStudyButtonWidget), findsNothing);

      final bar = tester.widget<MxProgressBar>(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.byType(MxProgressBar),
        ),
      );
      expect(bar.value, 1);
    });

    testWidgets('is honestly shorter than a studyable neighbour — no phantom '
        '48px band', (tester) async {
      // The touch floor belongs to the Study button. A completed card has no
      // button, so forcing its action row to the 48 floor bought equal heights
      // with a band of nothing — the imbalance the spacing patch removed. The
      // completed card must now be shorter, by roughly the pill's cushion.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(
            id: 'd1',
            name: 'Nouns',
            totalCardCount: 60,
            newCardCount: 14,
            dueCardCount: 7,
            learnedCardCount: 22,
          ),
          fakeSummary(
            id: 'd2',
            name: 'Verbs',
            totalCardCount: 60,
            learnedCardCount: 60,
          ),
        ]),
        screen: const DeckListScreen(),
      );

      final heights = find
          .byType(DeckTileWidget)
          .evaluate()
          .map((element) => element.size!.height)
          .toList();
      expect(heights, hasLength(2));
      expect(
        heights.last,
        lessThan(heights.first),
        reason: 'a completed card carries no empty action floor',
      );
    });

    testWidgets('keeps the Study touch target at the 48 floor', (tester) async {
      // The visual pill paints 32; the floor is the hit area, and trimming the
      // row's resting height must never trim this.
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

      expect(
        tester.getSize(find.byType(DeckStudyButtonWidget)).height,
        greaterThanOrEqualTo(AppSpacing.minimumTouchTarget),
      );
    });
  });

  group('large counts (999 Due, 999 New)', () {
    testWidgets('nothing is clipped, and the pair may wrap', (tester) async {
      await pump(
        tester,
        fakeSummary(
          id: 'd1',
          name: 'Backlog',
          totalCardCount: 2000,
          newCardCount: 999,
          dueCardCount: 999,
          learnedCardCount: 500,
        ),
      );

      expect(onTile(find.text(due(999))), findsOneWidget);
      expect(onTile(find.text(fresh(999))), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the scheduler is off the tile entirely', () {
    testWidgets('the root list no longer names it', (tester) async {
      // The algorithm moved to the deck's own level (owner mockup,
      // 2026-08-20): a column of "8 boxes" distinguished nothing and dressed
      // every card in a term from the settings sheet.
      await pump(
        tester,
        fakeSummary(id: 'd1', name: 'Nouns', totalCardCount: 60),
      );

      expect(
        onTile(find.textContaining(english.schedulerEightBoxShortLabel)),
        findsNothing,
      );
    });
  });

  group('empty deck (0 cards)', () {
    final summary = fakeSummary(id: 'd1', name: 'Brand new');

    testWidgets('says No cards, draws no gauge, offers no Study', (
      tester,
    ) async {
      await pump(tester, summary);

      expect(find.text(english.deckNoCardsLabel), findsOneWidget);
      // The resting sentence sits on the same axis as the title — the indent
      // applies to the whole workload line, whatever it is saying.
      expect(
        tester.getRect(find.byType(DeckWorkloadLineWidget)).left,
        tester.getRect(find.text('Brand new')).left,
      );
      // A gauge needs a denominator; an empty deck has none, so there is no
      // bar to draw rather than a 0% one.
      expect(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.byType(MxProgressBar),
        ),
        findsNothing,
      );
      expect(find.byType(DeckStudyButtonWidget), findsNothing);
      // And no workload zeroes: "no cards" is a different fact from "nothing
      // pending", and printing 0/0 here would collapse the two.
      expect(onTile(find.text(due(0))), findsNothing);
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

      expect(onTile(find.text(due(7))), findsOneWidget);
      expect(onTile(find.text(fresh(14))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The separator can never be an orphan: it shares a row with the metric
      // it introduces, so if the group wraps, the dot travels with `14 New`
      // and sits on the same line.
      final dot = tester.getRect(
        find
            .descendant(
              of: find.byType(DeckWorkloadLineWidget),
              matching: find.text('·'),
            )
            .first,
      );
      final fresh14 = tester.getRect(onTile(find.text(fresh(14))));
      expect(dot.center.dy, closeTo(fresh14.center.dy, 1));
    });
  });
}
