import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_workload_line_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_mastery_ring.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The Library deck row's state matrix: the tile, the counts, the ring
/// (BR-150, BR-142, BR-88, BR-29).
///
/// **Positive counts only** (owner mockup, 2026-08-20): a metric at zero
/// stays quiet while any sibling speaks, and a deck with nothing pending at
/// all says so in one chip rather than in two zeroes (owner review,
/// 2026-08-21).
///
/// **No verb on the row** (owner decision 7, 2026-09-13, reversing M4.12): a
/// session starts from the Study tab or inside the deck, so every state below
/// asserts the row offers none, whatever its counts say.
void main() {
  final english = AppLocalizationsEn();

  String due(int count) => english.deckTileDueChipLabel(count);
  String fresh(int count) => english.deckTileNewChipLabel(count);

  /// Scoped to the row: the summary panel states the same words above.
  Finder onTile(Finder matching) =>
      find.descendant(of: find.byType(DeckTileWidget), matching: matching);

  Future<void> pump(WidgetTester tester, DeckSummary summary) => pumpDeckScreen(
    tester,
    repository: FakeDeckRepository.withSummaries(<DeckSummary>[summary]),
    screen: const DeckListScreen(),
  );

  MxMasteryRing ringOf(WidgetTester tester) =>
      tester.widget<MxMasteryRing>(onTile(find.byType(MxMasteryRing)));

  /// The row offers no session: no labelled button of any variant on it.
  void expectNoVerb() =>
      expect(onTile(find.byType(ButtonStyleButton)), findsNothing);

  group('the row: tile · name, cards, counts · ring · overflow', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Nouns',
      totalCardCount: 60,
      newCardCount: 14,
      dueCardCount: 7,
      learnedCardCount: 22,
    );

    testWidgets('carries every part, and no Study', (tester) async {
      await pump(tester, summary);

      expect(onTile(find.byType(MxIconTile)), findsOneWidget);
      expect(onTile(find.text('Nouns')), findsOneWidget);
      // UC-06 step 2: the total card count in the tree stays on the row.
      expect(onTile(find.text(english.deckCardCountLabel(60))), findsOneWidget);
      expect(onTile(find.byType(DeckWorkloadLineWidget)), findsOneWidget);
      expect(onTile(find.byType(MxMasteryRing)), findsOneWidget);
      expect(onTile(find.byIcon(Icons.more_vert)), findsOneWidget);
      expectNoVerb();
      expect(
        tester.getSize(find.byType(DeckTileWidget)).height,
        greaterThanOrEqualTo(AppSizing.rowMinHeight),
      );
    });

    testWidgets('the ring measures what is learned, and names it', (
      tester,
    ) async {
      await pump(tester, summary);

      final ring = ringOf(tester);
      expect(ring.value, summary.learnedFraction);
      expect(ring.isComplete, isFalse);
      expect(ring.semanticsLabel, english.deckLearnedProgressLabel(22, 60));
      expect(ring.semanticsValue, english.deckLearnedPercentLabel(37));
    });

    testWidgets('the counts are words; the only glyphs are the tile and the '
        'overflow', (tester) async {
      await pump(tester, summary);

      expect(onTile(find.byIcon(Icons.account_tree_outlined)), findsNothing);
      expect(onTile(find.byIcon(Icons.auto_awesome_outlined)), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DeckWorkloadLineWidget),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
      // The tile says what the deck holds in every schedule state: urgency
      // is the chips' job.
      expect(onTile(find.byIcon(Icons.folder_outlined)), findsOneWidget);
      expect(onTile(find.byIcon(Icons.event)), findsNothing);

      // One typography for the pair.
      final dueStyle = tester.widget<Text>(onTile(find.text(due(7)))).style;
      final newStyle = tester.widget<Text>(onTile(find.text(fresh(14)))).style;
      expect(dueStyle?.fontSize, newStyle?.fontSize);
      expect(dueStyle?.fontWeight, newStyle?.fontWeight);
    });
  });

  group('new-only (0 Due, 14 New)', () {
    testWidgets('leads with the new count and claims no success', (
      tester,
    ) async {
      await pump(
        tester,
        fakeSummary(
          id: 'd1',
          name: 'Fresh deck',
          totalCardCount: 20,
          newCardCount: 14,
        ),
      );

      expect(onTile(find.text(due(0))), findsNothing);
      expect(onTile(find.text(fresh(14))), findsOneWidget);
      expectNoVerb();
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(ringOf(tester).isComplete, isFalse);
      expect(onTile(find.byIcon(Icons.folder_outlined)), findsOneWidget);
      expect(onTile(find.byIcon(Icons.schedule)), findsNothing);
    });
  });

  group('due-only (5 Due, 0 New)', () {
    testWidgets('keeps the new side quiet at zero', (tester) async {
      await pump(
        tester,
        fakeSummary(
          id: 'd1',
          name: 'Seasoned deck',
          totalCardCount: 9,
          dueCardCount: 5,
          learnedCardCount: 4,
        ),
      );

      expect(onTile(find.text(due(5))), findsOneWidget);
      expect(onTile(find.text(fresh(0))), findsNothing);
      expectNoVerb();
    });
  });

  group('nothing pending (0 Due, 0 New, 50%)', () {
    testWidgets('one chip says the whole state, and an idle day is not '
        'completion (BR-29)', (tester) async {
      await pump(
        tester,
        fakeSummary(
          id: 'd1',
          name: 'Half way',
          totalCardCount: 8,
          learnedCardCount: 4,
        ),
      );

      // **Not two zeroes**: `0 due · 0 new` is two facts about what is not
      // there, and a reader scanning for work read both to learn nothing.
      expect(onTile(find.text(due(0))), findsNothing);
      expect(onTile(find.text(fresh(0))), findsNothing);
      expect(
        onTile(find.text(english.deckTileAllCaughtUpLabel)),
        findsOneWidget,
      );
      expectNoVerb();
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(ringOf(tester).isComplete, isFalse);
    });
  });

  group('completed (0 Due, 0 New, 100%)', () {
    testWidgets('completion lives on the ring alone', (tester) async {
      await pump(
        tester,
        fakeSummary(
          id: 'd1',
          name: 'Verbs',
          totalCardCount: 60,
          learnedCardCount: 60,
        ),
      );

      // No check glyph: the ring is the completion signal, and the tile
      // answers "what", not "when".
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(onTile(find.byIcon(Icons.folder_outlined)), findsOneWidget);
      expect(
        onTile(find.text(english.deckTileAllCaughtUpLabel)),
        findsOneWidget,
      );
      expectNoVerb();
      expect(ringOf(tester).isComplete, isTrue);
    });

    testWidgets('one card short is not complete, whatever the ring rounds to '
        '(BR-88)', (tester) async {
      await pump(
        tester,
        fakeSummary(
          id: 'd1',
          name: 'Verbs',
          totalCardCount: 200,
          learnedCardCount: 199,
        ),
      );

      expect(ringOf(tester).isComplete, isFalse);
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

  group('the scheduler is off the row entirely', () {
    testWidgets('the root list no longer names it', (tester) async {
      // The algorithm moved to the deck's own level (owner mockup,
      // 2026-08-20): a column of "8 boxes" distinguished nothing and dressed
      // every row in a term from the settings sheet.
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
    testWidgets('says No cards, draws no ring, offers no Study', (
      tester,
    ) async {
      await pump(tester, fakeSummary(id: 'd1', name: 'Brand new'));

      expect(find.text(english.deckNoCardsLabel), findsOneWidget);
      // The resting sentence sits on the title's axis.
      expect(
        tester.getRect(find.byType(DeckWorkloadLineWidget)).left,
        tester.getRect(find.text('Brand new')).left,
      );
      // A ring needs a denominator; an empty deck has none.
      expect(onTile(find.byType(MxMasteryRing)), findsNothing);
      expectNoVerb();
      // "No cards" is a different fact from "nothing pending".
      expect(onTile(find.text(due(0))), findsNothing);
    });
  });
}
